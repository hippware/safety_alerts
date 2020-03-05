# frozen_string_literal: true

require 'safety_alerts/secrets'

RSpec.describe SafetyAlerts::Secrets do
  context 'when in development' do
    describe '#get_value' do
      it 'returns an empty string' do
        expect(described_class.get_value('password')).to eq('')
      end
    end
  end

  context 'when in production' do
    # How do we even test this?
  end
end
