# frozen_string_literal: true

require 'digest'
require 'dotenv'
require 'httparty'
require 'securerandom'

TESLA_AUTH_URL = 'https://auth.tesla.com/oauth2/v3'
TESLA_REDIRECT_URI = 'https://auth.tesla.com/void/callback'
TESLA_OWNERS_API_AUTH_URL = 'https://owner-api.teslamotors.com/oauth/token'

TESLA_CLIENT_ID = '81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384'
TESLA_CLIENT_SECRET = 'c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3'
TESLA_API_CODE_VERIFIER_LENGTH_CHARS = 86

def generate_challenge
  verifier = SecureRandom.hex(TESLA_API_CODE_VERIFIER_LENGTH_CHARS / 2)
  challenge = Base64.urlsafe_encode64(Digest::SHA256.hexdigest(verifier))
  [verifier, challenge]
end

def generate_state
  SecureRandom.hex(24)
end

def fail_if_missing_required_env_vars!
  %w[TESLA_USERNAME TESLA_PASSWORD].each do |var|
    raise "Please define #{var}" if ENV[var].nil?
  end
end

def initiate_tesla_authentication_flow_or_fail!(challenge:, state:)
  response = HTTParty.get("#{TESLA_AUTH_URL}/authorize",
                          query: {
                            client_id: 'ownerapi',
                            code_challenge: challenge,
                            code_challenge_method: 'S256',
                            redirect_uri: TESLA_REDIRECT_URI,
                            response_type: 'code',
                            scope: 'openid email offline_access',
                            state: state
                          })
  raise "Expected 200, but got #{response.code} with: #{response.body}" \
    unless response.code == 200

  auth_sid_cookie = response.headers['set-cookie'].split(' ').first
  [auth_sid_cookie, Hash[response.body.scan(/type="hidden" name="(.*?)" value="(.*?)"/)]]
end

def new_auth_token(challenge:, session_params:, session_cookie:, state:)
  full_uri = "#{TESLA_AUTH_URL}/authorize?" +
             URI.encode_www_form({
                                   client_id: 'ownerapi',
                                   code_challenge: challenge,
                                   code_challenge_method: 'S256',
                                   redirect_uri: TESLA_REDIRECT_URI,
                                   response_type: 'code',
                                   scope: 'openid email offline_access',
                                   state: state
                                 })
  headers = { Cookie: session_cookie }
  payload =
    URI.encode_www_form(session_params.merge(
                          identity: ENV['TESLA_USERNAME'],
                          credential: ENV['TESLA_PASSWORD']
                        ))
  response = HTTParty.post(full_uri,
                           body: payload,
                           headers: headers,
                           follow_redirects: false)
  raise "Expected 302 but received #{response.code}" unless response.code == 302

  auth_token = response.headers['Location'].scan(/code=(\w+)/).first
  raise 'Auth token not provided in response' if auth_token.nil?

  auth_token
end

def new_bearer_token(challenge_verifier:, auth_token:)
  response = HTTParty.post("#{TESLA_AUTH_URL}/token",
                           headers: {
                             Accept: 'application/json'
                           },
                           body: {
                             grant_type: 'authorization_code',
                             client_id: 'ownerapi',
                             code: auth_token,
                             code_verifier: challenge_verifier,
                             redirect_uri: TESLA_REDIRECT_URI
                           })
  json = JSON.parse(response.body)
  raise "Expected 200 but received #{response.code} with '#{json['error_description']}'" \
    unless response.code == 200

  raise 'No access token provided in response' unless json.key? 'access_token'

  [json['access_token'], json['refresh_token']]
end

def new_access_token(bearer_token)
  response = HTTParty.post(TESLA_OWNERS_API_AUTH_URL,
                           headers: {
                             Accept: 'application/json',
                             Authorization: "Bearer #{bearer_token}"
                           },
                           body: {
                             grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                             client_id: TESLA_CLIENT_ID,
                             client_secret: TESLA_CLIENT_SECRET
                           })
  json = JSON.parse(response.body)
  raise "Expected 200 but received #{response.code} with '#{json['error_description']}'" \
    unless response.code == 200

  raise 'No access token provided in response' unless json.key? 'access_token'

  [json['access_token'], json['expires_in']]
end

Dotenv.load('.env') if File.exist? '.env'
fail_if_missing_required_env_vars!

state = generate_state
code_verifier, challenge = generate_challenge
raise 'Code challenge failed to generate' if challenge.nil?

session_cookie, session_params =
  initiate_tesla_authentication_flow_or_fail!(challenge: challenge,
                                              state: state)
raise 'No session params were returned' if session_params.nil?
raise 'Unable to get auth session cookie' if session_cookie.nil?

%w[_csrf _phase _process transaction_id cancel].each do |key|
  raise "Missing session key '#{key}'" unless session_params.key? key
end

auth_token = new_auth_token(challenge: challenge,
                            session_params: session_params,
                            session_cookie: session_cookie,
                            state: state)
raise "Couldn't get auth token" if auth_token.nil?

bearer_token, refresh_token = new_bearer_token(challenge_verifier: code_verifier,
                                               auth_token: auth_token)
raise "Couldn't get bearer token" if bearer_token.nil? || refresh_token.nil?

access_token, expiration_seconds = new_access_token(bearer_token)
raise "Couldn't get access token" if access_token.nil?

expiration_days = (expiration_seconds / 60 / 60 / 24)

puts "Access token: #{access_token}"
puts "Refresh token: #{refresh_token}"
puts "Expires in: #{expiration_days} days"
