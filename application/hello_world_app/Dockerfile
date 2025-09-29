# Stage 1 - Build
FROM ruby:3.0.0-alpine as builder

# Install build dependencies
RUN apk update && apk add --no-cache \
  build-base \
  nodejs \
  postgresql-dev \
  git

# Install Bundler (Ruby dependency manager)
RUN gem install bundler

# Set working directory
WORKDIR /myapp

# Copy Gemfile and Gemfile.lock to the container
COPY Gemfile Gemfile.lock ./

# Install Ruby gems using Bundler
RUN bundle install

# Copy the entire application source code to the container
COPY . .

# Stage 2 - Run
FROM ruby:3.0.0-alpine

# Install runtime dependencies
RUN apk add --no-cache \
  nodejs \
  postgresql-dev

# Install Bundler (needed in runtime stage)
RUN gem install bundler

# Set the working directory for the final stage
WORKDIR /myapp

# Create a non-root user
RUN addgroup -S myuser && adduser -S myuser -G myuser

# Copy the application and installed gems from the build stage
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /myapp /myapp 

# Set the correct file permissions for the working directory (must be done as root)
RUN chown -R myuser:myuser /myapp

# Switch to the non-root user
USER myuser

# Expose port 3000 (default for Rails)
EXPOSE 3000

# Command to start the Rails server

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

