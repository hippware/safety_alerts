# frozen_string_literal: true

require 'aws-sdk-core'
require 'vault'

module SafetyAlerts
  # Simple class to manage access to sensitive strings such as passwords.
  # The current implementation relies on an external Vault service.
  class Secrets
    @prefix = ENV['WOCKY_VAULT_PREFIX']

    def self.configure
      return unless @prefix

      Vault.configure do |config|
        config.address = 'http://vault-vault.vault:8200'
      end

      iam_role = `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/`

      Vault.auth.aws_iam(iam_role, Aws::InstanceProfileCredentials.new)
    end

    def self.get_value(key)
      return '' unless @prefix

      Vault.logical.read("#{@prefix}#{key}").data[:value] || ''
    end
  end
end
