module Kernel
  def wait(object)
    Async.wait object
  end
end
