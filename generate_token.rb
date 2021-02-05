# frozen_string_literal: true

require 'digest'
require 'dotenv'
require 'httparty'
require 'securerandom'

@tesla_client_id = '81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384'
@tesla_client_secret = 'c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3'
@tesla_api_code_verifier_length_chars = 86

def generate_challenge
  verifier = SecureRandom.hex(@tesla_api_code_verifier_length_chars)
  challenge = Base64.urlsafe_encode64(Digest::SHA256.hexdigest(verifier))
  [verifier, challenge]
end

def fail_if_missing_required_env_vars!
  %w[TESLA_USERNAME TESLA_PASSWORD].each do |var|
    raise "Please define #{var}" if ENV[var].nil?
  end
end

Dotenv.load('.env') if File.exist? '.env'
fail_if_missing_required_env_vars!

code_verifier, challenge = generate_challenge
raise 'Code challenge failed to generate' if challenge.nil?

require 'pry'; binding.pry # vim breakpoint

return

session_params = initiate_tesla_authentication_flow(challenge)
raise 'No session params were returned' if session_params.nil?

%w[csrf phase process transaction_id cancel].each do |key|
  raise "Missing session key '#{key}'" unless session_params.key? key
end

auth_token = new_auth_token(challenge, session_params)
raise "Couldn't get auth token" if auth_token.nil?

bearer_token = new_bearer_token(code_verifier, challenge)
raise "Couldn't get bearer token" if bearer_token.nil?

access_token, refresh_token = new_access_token(bearer_token)
raise "Couldn't get access token" if access_token.nil? || refresh_token.nil?

puts "Access token: #{access_token}"
puts "Refresh token: #{refresh_token}"
