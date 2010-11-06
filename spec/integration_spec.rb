require File.expand_path("../spec_helper", __FILE__)
require "em-http"
require "benchmark"

describe Async do
  def request
    EM::HttpRequest.new("http://www.postrank.com")
  end

  def time
    Benchmark.realtime { yield }
  end

  it "should let use EM-operations outside EM.run block" do
    expect { request.get }.to_not raise_error
  end

  it "should not block async operations" do
    time { request.get }.should be < 0.01
  end

  it "#wait should block until async operation returns" do
    time { wait request.get }.should be > 0.05
  end

  it '#wait should return result of async operation' do
    wait(request.get).response.should include("<!DOCTYPE html>")
  end

  it "#wait should not block other async operations" do
    batch_duration = time { Array.new(5) { request.get }.map {|it| wait it }}
    batch_duration.should be < 2 * time { wait request.get }
  end
end