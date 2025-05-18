# syntax=docker/dockerfile:1

# --> Stage 1: Runtime and Build Base Image
ARG RUBY_VERSION=3.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base
WORKDIR /app
SHELL [ "/bin/bash", "-c" ]

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"

#ENV BUNDLE_WITHOUT="development"


# --> Stage 2: Build Environment
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git pkg-config libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*# Throw-away build stage to reduce size of final image

COPY . .

# --> Stage 3: Actual application deployment
FROM base
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /app /app

RUN groupadd --system --gid 1000 app && \
    useradd app --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R 1000:1000 .

USER 1000:1000

ENV RACK_ENV=production
ENV REDIS_URL=redis://localhost:6379
ENV FORCE_SSL=0

CMD [ "bundle", "exec", "puma", "-b", "tcp://0.0.0.0:9292" ]
