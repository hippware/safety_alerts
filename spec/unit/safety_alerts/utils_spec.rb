# frozen_string_literal: true

require 'safety_alerts/utils'

class TestClass
  attr_accessor :foo, :bar, :baz

  def initialize
    @foo = 1
    @bar = 2
    @baz = 3
  end
end

RSpec.describe SafetyAlerts::Utils do
  describe '#hashify' do
    it 'converts an object to a hash' do
      hsh = described_class.hashify(TestClass.new)

      expect(hsh).to be_an_instance_of(Hash)
        .and include('foo' => 1)
        .and include('bar' => 2)
        .and include('baz' => 3)
    end
  end
end
