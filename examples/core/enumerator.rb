# frozen_string_literal: true

require 'bundler/setup'
require 'polyphony'

enum = [1,2,3].each

coproc do
  while e = enum.next rescue nil
    puts e
    sleep 1
  end
end