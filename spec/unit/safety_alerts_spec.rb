# frozen_string_literal: true

require 'safety_alerts'

RSpec.describe SafetyAlerts do
  describe '#run_alert_import' do
    it 'calls AlertImporter#run' do
      allow(SafetyAlerts::AlertImporter).to receive(:run).with('US_NWS').once
      described_class.run_alert_import('US_NWS')
    end
  end

  describe '#run_geometry_import' do
    it 'calls GeometryImporter#run' do
      allow(SafetyAlerts::GeometryImporter).to receive(:run).with('US_NWS').once
      described_class.run_geometry_import('US_NWS')
    end
  end
end
