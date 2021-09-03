FROM ruby
ARG WITH_TEST=false
COPY ./Gemfile .
RUN if echo "$WITH_TEST" | grep -q 'true'; \
    then bundle install; \
    else bundle install --without test; \
    fi;
COPY . /app
WORKDIR /app
ENTRYPOINT [ "ruby", "generate_token.rb" ]
