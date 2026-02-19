ARG REDMINE_VERSION=6.0
FROM redmine:${REDMINE_VERSION}

USER root

#Install dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    build-essential \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment variables
COPY config/configuration.yml /usr/src/redmine/config/configuration.yml
COPY config/database.yml /usr/src/redmine/config/database.yml

# Copy plugins
COPY plugins/ /usr/src/redmine/plugins/

# Schema format for SLA plugin
RUN echo "Rails.application.config.active_record.schema_format = :sql" >> config/application.rb

# 5. Install gems
RUN bundle config set --local without 'development test' \
    && bundle install

# Assign redmine user to the db and plugins folder 
RUN chown -R redmine:redmine \
    /usr/src/redmine/db \
    /usr/src/redmine/plugins \
    /usr/src/redmine/tmp \
    /usr/src/redmine/public/plugin_assets \
    /usr/src/redmine/files \
    /usr/src/redmine/log

# Switch to Redmine user 
USER redmine

# Set Entrypoint and Command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]
