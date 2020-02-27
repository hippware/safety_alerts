require 'vault'

module SafetyAlerts
  class Secrets
    attr_reader :prefix

    def initialize
      @prefix = ENV['WOCKY_VAULT_PREFIX']

      if @prefix
        signature = `curl http://169.254.169.254/latest/dynamic/instance-identity/pkcs7`
        iam_role = `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/`
        token = Vault.auth.aws_ec2(iam_role, signature, nil)

        @client = Vault::Client.new(
          address: 'http://vault-vault.vault:8200',
          token: vault_token.auth.client_token
        )
      end
    end

    def get_value(key)
      @client&.logical.read("#{@prefix}/#{key}") || ''
    end
  end
end
