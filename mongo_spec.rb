require 'spec_helper'

# Mongo service
describe service('mongodb') do
    it { should be_enabled }
    it { should be_running }
end

ports = [27017, 28017]

ports.each do |port|
    describe port(port) do
        it { should be_listening }
    end
end