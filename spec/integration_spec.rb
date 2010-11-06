require File.expand_path("../spec_helper", __FILE__)
require "em-http"
require "benchmark"

describe Async do
  def request
    EM::HttpRequest.new("http://www.postrank.com")
  end

  it "should let use EM-operations outside EM.run block" do
    lambda { request.get }.should_not raise_error
  end

  it "should not block async operations" do
    Benchmark.realtime { request.get }.should be < 0.01
  end

  it "#wait should block until async operation returns" do
    Benchmark.realtime { wait request.get }.should be > 0.05
  end

  it '#wait should return result of async operation' do
    wait(request.get).response.should include("<!DOCTYPE html>")
  end

  it "#wait should not block other async operations" do
    time_for_one_request = Benchmark.realtime { wait request.get }
    time = Benchmark.realtime { Array.new(5) { request.get }.map {|it| wait it }}
    time.should be < 2*time_for_one_request
  end
end