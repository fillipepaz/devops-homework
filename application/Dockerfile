# Single stage build for simplicity with Alpine
FROM ruby:3.0-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    sqlite-dev \
    tzdata \
    libc6-compat \
    libstdc++

# Create non-root user
RUN adduser -D -h /app -s /bin/false app && \
    mkdir -p /app/vendor/bundle && \
    chown -R app:app /app/vendor

# Set working directory
WORKDIR /app

# Install specific bundler version
RUN gem install bundler:2.4.22

# Switch to non-root user
USER app

# Configure bundler
ENV BUNDLE_PATH=/app/vendor/bundle \
    BUNDLE_BIN=/app/vendor/bundle/bin \
    BUNDLE_APP_CONFIG=/app/vendor/bundle

# Copy application files
COPY --chown=app:app . .

# Install dependencies as app user
RUN bundle config set --local path vendor/bundle && \
    bundle install --jobs=4 --retry=3

# Set production environment
ENV RACK_ENV=production

# Expose port
EXPOSE 3000

# Start the application
CMD ["bundle", "exec", "rackup", "config.ru", "-o", "0.0.0.0", "-p", "3000"]