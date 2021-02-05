# Tesla Auth Bot

Generates Tesla authentication tokens using their OAuth2 scheme as documented
by [timdorr](https://tesla-api.timdorr.com/api-basics/authentication).

# How To Use

⚠️  Make sure that you have Ruby installed on your machine before continuing. ⚠️

1. Install dependencies: `bundle install`
2. Run the tool: `ruby generate_token.rb`

This will provide an access token and a refresh token. Use the refresh token to
refresh the access token every 45 days.
