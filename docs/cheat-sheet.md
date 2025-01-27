# @title Cheat Sheet

# Cheat Sheet

## Fibers

### Start a fiber

```ruby
fiber = spin do
  do_some_work
end
```

### Run a loop in a fiber

```ruby
fiber = spin_loop do
  iterate_on_something
end
```

### Stop a fiber

```ruby
fiber.stop
# or:
fiber.interrupt
```

### Wait for a fiber to terminate

```ruby
fiber.await
# or:
fiber.join
```

### Wait for multiple fibers to terminate

```ruby
Fiber.await(fiber1, fiber2, ...)
# or:
Fiber.join(fiber1, fiber2, ...)
```

### Raise an exception in a fiber

```ruby
fiber.raise(SomeException)
# or:
fiber.raise(SomeException, 'Exception message')
```

### Restart a fiber

```ruby
fiber.restart
# or:
fiber.reset
```

## Control Fiber Scheduling

### Yield to other fibers during a lengthy CPU-bound operation

```ruby
def calculate_some_stuff(n)
  acc = 0
  n.times do |i|
    acc += big_calc(acc, i)
    snooze if (i % 1000) == 0
  end
end 
```

### Suspend fiber

```ruby
suspend
```

### Schedule fiber

```ruby
fiber.schedule
# or:
fiber.schedule(some_value)
```

## Message Passing

### Send a message to a fiber

```ruby
fiber << message
# or:
fiber.send << message
```
### Receive a message

```ruby
message = receive
# or, using deconstructing assign
a, b, c = receive
```

## Using Timers and Sleeping

### Sleep for a specific duration

```ruby
sleep 1 # sleeps for 1 second
```

### Sleep infinitely

```ruby
sleep
# or:
suspend
```

### Perform an operation repeatedly with a given time interval

```ruby
every(10) { do_something } # perform an operation once every 10 seconds
```

### Perform an operation repeatedly with a given frequency

```ruby
throttled_loop(10) { do_something } # perform an operation 10 times per second
```

### Timeout, raising an exception

```ruby
# On timeout, a Polyphony::Cancel exception is raised
cancel_after(10) { do_something_slow } # timeout after 10 seconds

# Or, using the stock Timeout API, raising a Timeout::Error
Timeout.timeout(10) { do_something_slow }
```

### Timeout without raising an exception

```ruby
# On timeout, result will be set to nil
result = move_on_after(10) { do_something_slow }

# Or, with a specific value:
result = move_on_after(10, with_value: 'foo') { do_something_slow }
```

### Resettable timeout

```ruby
# works with move_on_after as well
cancel_after(10) do |timeout|
  while (data = client.gets)
    timeout&.reset
    do_something_with_data(client)
  end
end
```

## Advanced I/O

### Splice data between two file descriptors

```ruby
# At least one file descriptor should be a pipe
dest.splice_from(source, 8192) #=> returns number of bytes spliced
# or:
IO.splice(src, dest, 8192)
```

### Splice data to EOF

```ruby
dest.splice_from(source, -8192) #=> returns number of bytes spliced
# or:
IO.splice(src, dest, -8192)
```

### Tee data between two file descriptors (allowing splicing data twice)

```ruby
dest2.tee_from(source, 8192)
dest1.splice_from(source, 8192)
# or:
IO.tee(src, dest2)
IO.splice(src, dest2)
```

### Splice data between two arbitrary file descriptors, without creating a pipe

```ruby
# This will automatically create a pipe, and splice data from source to
# destination until EOF is encountered.
IO.double_splice(src, dest)
```

### Create a pipe

A `Polyphony::Pipe` instance encapsulates a pipe with two file descriptors. It
can be used just like any other IO instance for reading, writing, splicing etc.

```ruby
pipe = Polyphony::Pipe.new
# or:
pipe = Polyphony.pipe
```

### Compress/uncompress data between two IOs

```ruby
IO.gzip(src, dest)
IO.gunzip(src, dest)
IO.deflate(src, dest)
IO.inflate(src, dest)
```

### Accept connections in a loop

```ruby
server_socket.accept_loop do |conn|
  handle_connection(conn)
end
```

### Read data in a loop until EOF

```ruby
connection.read_loop do |data|
  handle_data(data)
end
```

### Read data in a loop and feed it to a parser

```ruby
unpacker = MessagePack::Unpacker.new
reader = spin do
  io.feed_loop(unpacker, :feed_each) { |msg| handle_msg(msg) }
end
```
