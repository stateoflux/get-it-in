ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

begin
  require_relative '../get_it_in'
  # require_relative 'get_it_in'
rescue NameError
  # 
  require File.expand_path('get_it_in', __FILE__)
end

