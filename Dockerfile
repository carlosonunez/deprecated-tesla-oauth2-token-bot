FROM ruby
COPY . /app
WORKDIR /app
RUN bundle install --without test
ENTRYPOINT [ "ruby", "generate_token.rb" ]
