# Tesla Auth Bot [DEPRECATED]

> ❌ **THIS PROJECT HAS BEEN DEPRECATED** ❌
>
> Tesla's Auth API has enabled reCAPTCHA on `/oauth2/v3/authorize` and
> `/oauth2/v1/authorize`. Moreover, Tesla provides the code in a `Location`
> header, which browsers will redirect to automatically. Tesla will
> present a 404 page upon doing this. Consequently, the only way to
> work around this is to use a webdriver and capture redirects, which is
> only possible (or documented) with Chrome CDP or a proxy server fronting
> the webdriver, both of which are...a lot of work to get an OAuth token.
> 
> Tim Dorr's documentation does not document this. Users for whom reCAPTCHA
> has been enabled _will not_ be able to use regular CAPTCHAs generated by the
> `/captcha` endpoint.
>
> Consider using a mobile app with an embedded webview for your token generation
> needs.

Generates Tesla authentication tokens using their OAuth2 scheme as documented
by [timdorr](https://tesla-api.timdorr.com/api-basics/authentication).

# How To Use

## Docker

1. Copy the example dotenv and replace `change_me` with real values: `cp .env.example .env`
2. `docker-compose run --rm new-token`

## Local

⚠️  Make sure that you have Ruby installed on your machine before continuing. ⚠️

1. Copy the example dotenv and replace `change_me` with real values: `cp .env.example .env`
1. Install dependencies: `bundle install --without test`
2. Run the tool: `ruby generate_token.rb`

This will provide an access token and a refresh token. Use the refresh token to
refresh the access token every 45 days.
