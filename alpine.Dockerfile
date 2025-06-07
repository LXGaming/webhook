# syntax=docker/dockerfile:1
# Build Base
FROM --platform=$BUILDPLATFORM alpine:3.22 AS build-base
ARG BRANCH
RUN apk add --no-cache --upgrade \
        git
WORKDIR /src

RUN git clone --branch "${BRANCH:-master}" --depth 1 https://github.com/adnanh/webhook.git

# Build App
FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS build-app
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
FROM alpine:3.22
RUN apk add --no-cache --upgrade \
        curl jq tini tzdata
WORKDIR /app
COPY --from=build-app --chmod=755 /app ./
EXPOSE 9000
ENTRYPOINT ["/sbin/tini", "--", "/app/webhook"]
CMD ["-hooks", "/config/hooks.yml", "-hotreload", "-verbose"]