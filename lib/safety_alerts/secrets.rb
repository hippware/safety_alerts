# frozen_string_literal: true

require 'vault'

module SafetyAlerts
  # Simple class to manage access to sensitive strings such as passwords.
  # The current implementation relies on an external Vault service.
  class Secrets
    attr_reader :prefix

    def initialize
      @client = nil
      @prefix = ENV['WOCKY_VAULT_PREFIX']

      return unless @prefix

      signature = `curl http://169.254.169.254/latest/dynamic/instance-identity/pkcs7`
      iam_role = `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/`
      token = Vault.auth.aws_ec2(iam_role, signature, nil)

      @client = Vault::Client.new(
        address: 'http://vault-vault.vault:8200',
        token: token.auth.client_token
      )
    end

    def get_value(key)
      @client&.read("#{@prefix}/#{key}") || ''
    end
  end
end
