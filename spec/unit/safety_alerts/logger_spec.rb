# frozen_string_literal: true

require 'safety_alerts/logger'

RSpec.describe SafetyAlerts::Logger do
  # Since all of the logging methods are delegated, we only need to test
  # one to ensure that the delegation is working properly
  describe '#unknown' do
    it 'outputs logs at the unknown level' do
      expect { described_class.unknown 'Testing' }
        .to output(/ANY.*Testing/)
        .to_stdout_from_any_process
    end
  end
end
