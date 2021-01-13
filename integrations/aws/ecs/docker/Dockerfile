FROM fluent/fluentd:v1.11-1
USER root
RUN apk add --no-cache --update --virtual .build-deps build-base ruby-dev && \
    gem install fluent-plugin-docker_metadata_filter \
                fluent-plugin-concat \
                fluent-plugin-detect-exceptions \
                fluent-plugin-s3 \
                fluent-plugin-coralogix && \
    gem sources --clear-all && \
    apk del .build-deps && \
    rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

COPY fluent.conf /fluentd/etc/
