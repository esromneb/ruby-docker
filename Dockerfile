ARG RUBY_VERSION=3.0.1



# See explanation below
FROM ruby:$RUBY_VERSION-slim-buster
# after from, all args are reset, seems like maybe args used in the from are exempt!? very weird!
# https://github.com/moby/moby/issues/34129

# Yarn can go to 1.22.5
ARG YARN_VERSION=1.13.0
ARG PG_MAJOR=13
ARG NODE_MAJOR=14
ARG BUNDLER_VERSION=2.0.2


# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# RUN exit 1

# Download MIME types database for mimemagic
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  shared-mime-info \
  && cp /usr/share/mime/packages/freedesktop.org.xml ./ \
  && apt-get remove -y --purge shared-mime-info \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log \
  && mkdir -p /usr/share/mime/packages \
  && cp ./freedesktop.org.xml /usr/share/mime/packages/

# Add PostgreSQL to sources list
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade

# RUN echo HEREd
# RUN echo ruby says $RUBY_VERSION done
# RUN echo yarn says $YARN_VERSION done

# RUN echo hi && apt-get install -yq --no-install-recommends yarn=$YARN_VERSION-1

# RUN exit 1

# Application dependencies
# We use an external Aptfile for that, stay tuned
COPY Aptfile /tmp/Aptfile
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libsqlite3-dev \
    libpq-dev \
    postgresql-client-$PG_MAJOR \
    nodejs \
    yarn=$YARN_VERSION-1 \
    $(grep -Ev '^\s*#' /tmp/Aptfile | xargs) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Configure bundler
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

# Uncomment this line if you store Bundler settings in the project's root
# ENV BUNDLE_APP_CONFIG=.bundle

# Uncomment this line if you want to run binstubs without prefixing with `bin/` or `bundle exec`
# ENV PATH /app/bin:$PATH

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION && gem install rails

ENV PORT 3000

EXPOSE $PORT

# Create a directory for the app code
# RUN mkdir -p /app

WORKDIR /src


RUN gem install sqlite3 -v '1.4.2' --source 'https://rubygems.org/'

