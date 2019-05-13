# frozen_string_literal: true

require 'modulation'
Polyphony = import('../../lib/polyphony')

puts "parent pid: #{Process.pid}"

pid = Polyphony.fork do
  puts "child pid: #{Process.pid}"

  spawn do
    puts "child going to sleep 1..."
    sleep 1
    puts "child woke up 1"
  end
end

puts "got child pid #{pid}"

puts "waiting for child"
EV::Child.new(pid).await
puts "child is done"