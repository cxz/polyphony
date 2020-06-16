# frozen_string_literal: true

require_relative '../core/exceptions'

# Thread extensions
class ::Thread
  attr_reader :main_fiber, :result

  alias_method :orig_initialize, :initialize
  def initialize(*args, &block)
    @join_wait_queue = Gyro::Queue.new
    @args = args
    @block = block
    @finalization_mutex = Mutex.new
    orig_initialize { execute }
  end

  def execute
    setup
    @ready = true
    result = @block.(*@args)
  rescue Polyphony::MoveOn, Polyphony::Terminate => e
    result = e.value
  rescue Exception => e
    result = e
  ensure
    @ready = true
    finalize(result)
  end

  attr_accessor :agent

  def setup
    @main_fiber = Fiber.current
    @main_fiber.setup_main_fiber
    setup_fiber_scheduling
    @agent = Gyro::LibevAgent.new
  end

  def finalize(result)
    unless Fiber.current.children.empty?
      Fiber.current.terminate_all_children
      Fiber.current.await_all_children
    end
    @finalization_mutex.synchronize do
      @terminated = true
      @result = result
      signal_waiters(result)
    end
    @agent.finalize
  end

  def signal_waiters(result)
    @join_wait_queue.shift_each { |w| w.signal(result) }
  end

  alias_method :orig_join, :join
  def join(timeout = nil)
    watcher = Fiber.current.auto_watcher
    @finalization_mutex.synchronize do
      if @terminated
        @result.is_a?(Exception) ? (raise @result) : (return @result)
      else
        @join_wait_queue.push(watcher)
      end
    end
    timeout ? move_on_after(timeout) { watcher.await } : watcher.await
  end
  alias_method :await, :join

  alias_method :orig_raise, :raise
  def raise(error = nil)
    Thread.pass until @main_fiber
    error = RuntimeError.new if error.nil?
    error = RuntimeError.new(error) if error.is_a?(String)
    error = error.new if error.is_a?(Class)

    sleep 0.0001 until @ready
    main_fiber&.raise(error)
  end

  alias_method :orig_kill, :kill
  def kill
    return if @terminated
  
    raise Polyphony::Terminate
  end

  alias_method :orig_inspect, :inspect
  def inspect
    return orig_inspect if self == Thread.main

    state = status || 'dead'
    "#<Thread:#{object_id} #{location} (#{state})>"
  end
  alias_method :to_s, :inspect

  def location
    @block.source_location.join(':')
  end

  def <<(value)
    main_fiber << value
  end
  alias_method :send, :<<
end
