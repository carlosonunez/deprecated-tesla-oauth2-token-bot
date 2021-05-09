FROM ruby
COPY ./Gemfile .
RUN bundle install --without test
COPY . /app
WORKDIR /app
ENTRYPOINT [ "ruby", "generate_token.rb" ]
