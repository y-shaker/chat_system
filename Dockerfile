# Use an official lightweight Ruby image
FROM ruby:3.3.4

# Set environment variables
ENV RAILS_ENV=development \
    BUNDLE_PATH=/bundle

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm curl netcat-openbsd && \
    npm install -g yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the app
COPY . .

# Expose Rails port
EXPOSE 3000

# Default command
CMD ["bash", "-c", "bundle exec rails db:prepare && bundle exec rails s -b 0.0.0.0"]
