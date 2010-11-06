require "fiber"
require "eventmachine"
require "em-easy/extensions/kernel"

Fiber = Rubinius::Fiber if defined? Rubinius

module Async
  extend self
  attr_reader :evented_loop

  @evented_loop = Fiber.new do
    EM.run { next_iteration }
  end

  def wait(object)
    handle_callback = proc do
      object.callback {|*args| next_iteration Fiber.yield(*args) }
    end
    @evented_loop.resume :block => handle_callback, :smart => true
  end

  private

  def next_iteration(options=nil)
    block = options && options[:block]

    if block && options[:smart]
      block.call
    else
      instructions = Fiber.yield(block && block.call)
      EM.next_tick do
        next_iteration instructions
      end
    end
  end

  @evented_loop.resume
end