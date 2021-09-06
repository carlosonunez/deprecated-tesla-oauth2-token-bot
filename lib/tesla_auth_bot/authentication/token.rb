# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

module TeslaAuthBot
  module Authentication
    # Handles everything around retrieving access and secret tokens.
    module Token
      def self.begin_authenticating!(creds)
        response = HTTP.execute!(uri: creds.authorize_url,
                                 query: auth_params(creds))
        page = Nokogiri::HTML(response.body)
        puts "Headers: #{response.headers}"
        session = {
          session_cookie: response.headers['Set-Cookie']
        }
        %w[_csrf _phase _process transaction_id cancel].each do |attr_name|
          attribute = page.at("input[@name=\"#{attr_name}\"]") or {}
          session[attr_name.to_sym] = attribute['value'] unless attribute.nil?
        end
        session
      end

      def self.auth_params(creds)
        {
          client_id: 'ownerapi',
          code_challenge: creds.challenge,
          code_challenge_method: 'S256',
          redirect_uri: creds.oauth_redirect_url,
          response_type: 'code',
          scope: 'openid email offline_access',
          state: creds.state
        }
      end
    end

    # Methods for interacting with the Tesla authentication web pages.
    module HTTP
      def self.execute!(uri:,
                        method: 'GET',
                        headers: {},
                        expected_code: 200,
                        query: {})
        resp = HTTParty.get(uri, method: method, headers: headers, query: query)
        raise "Expected #{expected_code} but got #{resp.code}: #{resp.body}" \
          unless resp.code == 200

        resp
      rescue StandardError => e
        raise e
      end
    end
  end
end
