# frozen_string_literal: true

require 'spec_helper'

include TeslaAuthBot::Models
include TeslaAuthBot::Authentication

describe 'Given a library that produces access and refresh tokens' do
  before do
    @verifier = (1..86).map { |x| (96 + (x % 10)).chr }.join('')
    @state = 'fake-state'
    allow_any_instance_of(Credentials).to receive(:verifier).and_return(@verifier)
    allow_any_instance_of(Credentials).to receive(:state).and_return(@state)
  end
  example 'It retrieves session fields' do
    fake_authorize_page = File.read('./spec/fixtures/step_1.html')
    creds = Credentials.new
    expect(HTTParty)
      .to receive(:get)
      .with('https://auth.tesla.com/oauth2/v3/authorize',
            query: {
              client_id: 'ownerapi',
              code_challenge: creds.challenge,
              code_challenge_method: 'S256',
              redirect_uri: 'https://auth.tesla.com/void/callback',
              response_type: 'code',
              scope: 'openid email offline_access',
              state: @state
            })
      .and_return(fake_authorize_page)
    session = Token.begin_authenticating!(creds)
    expect(session[:_csrf]).to eq 'fake-csrf-token'
    expect(session[:_phase]).to eq 'authenticate'
    expect(session[:_process]).to eq '1'
    expect(session[:transaction_id]).to eq 'fake-transaction-id'
    expect(session[:cancel]).to eq ''
  end
end
