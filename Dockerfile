# syntax=docker/dockerfile:1
# Build Base
FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS build-base
ARG BRANCH
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src

RUN git clone --branch "${BRANCH:-master}" --depth 1 https://github.com/adnanh/webhook.git

# Build App
FROM --platform=$BUILDPLATFORM golang:1.24 AS build-app
ARG TARGETARCH
ARG TARGETOS
WORKDIR /src

COPY --from=build-base /src/webhook/go.mod /src/webhook/go.sum ./
RUN go mod download

COPY --from=build-base /src/webhook ./
RUN CGO_ENABLED=0 \
    GOARCH=$TARGETARCH \
    GOOS=$TARGETOS \
    go build -trimpath -ldflags="-s -w" -o /app/webhook

# Final
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl jq tini \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build-app --chmod=755 /app ./
EXPOSE 9000
ENTRYPOINT ["/usr/bin/tini", "--", "/app/webhook"]
CMD ["-hooks", "/config/hooks.yml", "-hotreload", "-verbose"]