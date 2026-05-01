# Stage 1: Build
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Install migrate CLI
RUN go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@v4.19.1

# Copy source and build
COPY . .
RUN go build -o bin/api cmd/api/main.go
RUN go build -o bin/seeder cmd/seeder/main.go
RUN cp /go/bin/migrate ./migrate

# Stage 2: Final image
FROM alpine:latest

WORKDIR /app

# Install certificates and timezone data
RUN apk --no-cache add ca-certificates tzdata

# Copy the compiled binary
COPY --from=builder /app/bin/api .
COPY --from=builder /app/bin/seeder .
COPY --from=builder /app/migrate .
COPY --from=builder /app/config/migrations ./config/migrations

# Copy entrypoint script
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 8081

CMD ["./entrypoint.sh"]
