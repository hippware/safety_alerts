# frozen_string_literal: true

require 'safety_alerts/geometry_importer'
require 'safety_alerts/geometry_importer/us_nws'

RSpec.describe SafetyAlerts::GeometryImporter, '#run' do
  it 'loads the right module and calls #run' do
    allow(SafetyAlerts::GeometryImporter::US_NWS)
      .to receive(:run).and_return(1).once

    expect { described_class.run('us_nws') }
      .to output(/1 geometries from 'US_NWS'/).to_stdout_from_any_process
  end

  it 'raises an error with bad importer name' do
    expect { described_class.run('bogus') }.to raise_error(LoadError)
  end
end
