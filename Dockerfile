# Build stage
FROM golang:1.19-alpine AS builder

# Install git and ca-certificates
RUN apk update && apk add --no-cache git ca-certificates

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bingo-server main.go

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/bingo-server .

# Expose port
EXPOSE 9000

# Set environment variable
ENV PORT=9000

# Run the binary
CMD ["./bingo-server"]
