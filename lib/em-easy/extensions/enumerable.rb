module Enumerable
  def async
    Async::Enumerator.new self
  end
end