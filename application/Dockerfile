### Build stage
FROM ruby:3.2-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    libgcc \
    libstdc++

# Create app directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile* ./
RUN bundle install

### Runtime stage
FROM ruby:3.2-alpine


RUN apk add --no-cache \
    libgcc \
    libstdc++

# Create non-root user
RUN adduser -D -h /app appuser

WORKDIR /app

# Copy gems from builder stage
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "-s", "puma", "-o", "0.0.0.0", "-p", "4567"]