# syntax = docker/dockerfile:1

ARG GO_VERSION=1.23
FROM golang:$GO_VERSION AS base

# App lives here
WORKDIR /app

# Add user to run the app
RUN useradd myapp

    # Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV APP_ENV="production"

# We will throw-away the build stage to reduce size of final image
FROM base AS build

# Copy whole source
COPY . .

# Download dependencies and verify
RUN go mod download
RUN go mod verify

# Compile binary
RUN go build

RUN chown -R myapp:myapp .

# Final stage for app image
FROM gcr.io/distroless/base-debian12

# App still lives here
WORKDIR /app

# Copy build artifacts from the build stage
COPY --from=build /app/cicd-talk-server /app/cicd-talk-server
COPY --from=build /app/static/index.html /app/static/index.html

# Copy user/group from the base stage
COPY --from=base /etc/passwd /etc/passwd
COPY --from=base /etc/group /etc/group

# Set user to run the app
USER myapp:myapp

# Start the server
EXPOSE 8081
CMD ["/app/cicd-talk-server"]
