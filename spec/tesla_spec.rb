# frozen_string_literal: true

require 'spec_helper'

include TeslaAuthBot::Models

describe 'Given an object that stores Tesla access and refresh tokens' do
  before do
    @verifier = (1..86).map { |x| (96 + (x % 10)).chr }.join('')
    @challenge = Base64.urlsafe_encode64(Digest::SHA256.hexdigest(@verifier))
    allow_any_instance_of(Credentials).to receive(:verifier).and_return(@verifier)
  end
  example 'it should produce a valid verifier and challenge when initialized' do
    creds = Credentials.new
    expect(creds.verifier).to eq @verifier
    expect(creds.challenge(@verifier)).to eq @challenge
  end
end
