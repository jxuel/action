# 1. Start with a "chef" image to manage dependency caching
FROM lukemathwalker/cargo-chef:latest-rust-1.80 AS chef
WORKDIR /app

# 2. Planner stage: Prepare a "recipe" of your dependencies
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# 3. Builder stage: Build dependencies and then your application
FROM chef AS builder 
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this layer is cached unless Cargo.toml changes
RUN cargo chef cook --release --recipe-path recipe.json

# Build the actual application
COPY . .
RUN cargo build --release --bin your_project_name

# 4. Runtime stage: Use a minimal base image for the final container
FROM debian:bookworm-slim AS runtime
WORKDIR /app

# Install OpenSSL and CA certificates (often needed for web services)
RUN apt-get update && apt-get install -y libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the binary from the builder stage
COPY --from=builder /app/target/release/your_project_name /usr/local/bin/app

# Set the environment and expose the port
ENV RUST_LOG=info
EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/app"]
