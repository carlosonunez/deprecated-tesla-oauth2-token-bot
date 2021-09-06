# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

module TeslaAuthBot
  module Authentication
    # Handles everything around retrieving access and secret tokens.
    module Token
      def self.begin_authenticating!(creds)
        params = {
          client_id: 'ownerapi',
          code_challenge: creds.challenge,
          code_challenge_method: 'S256',
          redirect_uri: creds.oauth_redirect_url,
          response_type: 'code',
          scope: 'openid email offline_access',
          state: creds.state
        }
        page = HTTP.get_or_raise!(creds.authorize_url, params)
        session = {}
        %w[_csrf _phase _process transaction_id cancel].each do |attr_name|
          attribute = page.at("input[@name=\"#{attr_name}\"]") or {}
          session[attr_name.to_sym] = if attribute.nil?
                                        nil
                                      else
                                        attribute['value']
                                      end
        end
        session
      end
    end

    # Methods for interacting with the Tesla authentication web pages.
    module HTTP
      def self.get_or_raise!(uri, params = {})
        page = HTTParty.get(uri, query: params)
        Nokogiri::HTML(page)
      rescue StandardError => e
        raise e
      end
    end
  end
end
