# frozen_string_literal: true

require 'base64'
require 'digest'

module TeslaAuthBot
  module Models
    # This describes an authentication object containing access and refresh tokens.
    class Credentials
      attr_reader :authorize_url, :oauth_redirect_url

      VERIFIER_LENGTH = 86 # This is required by the Tesla API
      STATE_LENGTH = 16 # This is arbitrary and can be set to anything.

      def initialize
        @authorize_url = 'https://auth.tesla.com/oauth2/v3/authorize'
        @oauth_redirect_url = 'https://auth.tesla.com/void/callback'
      end

      def verifier
        charset = ('A'..'Z').to_a + ('a'..'z').to_a + (1..9).to_a
        Array.new(VERIFIER_LENGTH) { charset.sample }.join
      end

      def challenge(verifier)
        Base64.urlsafe_encode64(Digest::SHA256.hexdigest(verifier))
      end

      def state
        charset = ('A'..'Z').to_a + ('a'..'z').to_a + (1..9).to_a
        Array.new(VERIFIER_LENGTH) { charset.sample }.join
      end
    end
  end
end
