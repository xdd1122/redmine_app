ARG REDMINE_VERSION=6.0
FROM redmine:${REDMINE_VERSION}

USER root

# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment variables
COPY config/configuration.yml /usr/src/redmine/config/configuration.yml
COPY config/database.yml /usr/src/redmine/config/database.yml

RUN apk add --no-cache postgresql-client

# Copy plugins
COPY plugins/ /usr/src/redmine/plugins/

# Schema format for SLA plugin
RUN echo "Rails.application.config.active_record.schema_format = :sql" >> config/application.rb

# Install gems
RUN apt-get update && apt-get install -y build-essential libxml2-dev && rm -rf /var/lib/apt/lists/*
RUN bundle config set --local without 'development test' \
    && bundle install

# Permissions to root
RUN chown -R root:root /usr/src/redmine

# 2. Folders write-access for redmine user
RUN mkdir -p /usr/src/redmine/tmp \
             /usr/src/redmine/public/plugin_assets \
             /usr/src/redmine/files \
             /usr/src/redmine/log \
    && chown -R redmine:redmine /usr/src/redmine/tmp \
                                /usr/src/redmine/public/plugin_assets \
                                /usr/src/redmine/files \
                                /usr/src/redmine/log

# Switch to Redmine user 
USER redmine

# Set Entrypoint and Command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]
