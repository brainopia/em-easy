require "fiber"
require "eventmachine"
require "em-easy/extensions/kernel"
require "em-easy/extensions/enumerable"

Fiber = Rubinius::Fiber if defined? Rubinius

module Async
  extend self
  attr_reader :evented_loop

  class Enumerator
    include Enumerable

    def initialize(collection)
      @collection = collection
      @total = collection.size
    end

    def each(&block)
      @finished = 0
      @block = block
      iterate_collection = proc do
        @collection.each do |it|
          if it.respond_to? :callback
            it.callback {|result| finished result }
          else
            finished it
          end
        end
      end
      Async.evented_loop.resume :block => iterate_collection, :smart => true
    end

    private

    def finished(result)
      @block.call result
      @finished += 1
      Async.send :next_iteration, Fiber.yield(@collection) if @finished == @total
    end
  end

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