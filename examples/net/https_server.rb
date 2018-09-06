#!/usr/bin/env ruby
# frozen_string_literal: true

require 'modulation'
require 'json'
require 'localhost/authority'

HTTP = import('../../lib/nuclear/http')

body = 'Hello, world!'
reply = "HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\n\r\n#{body}"

server = HTTP::Server.new do |socket, req|
  # object = {
  #   url: req.request_url,
  #   headers: req.headers,
  #   upgrade: req.upgrade_data
  # }
  # body = object.to_json

  # reply = "HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\n\r\n#{body}"

  socket << reply
end

# Get the self-signed authority for localhost:
authority = Localhost::Authority.fetch
server.listen(port: 1234, secure_context: authority.server_context)
puts "listening on port 1234"