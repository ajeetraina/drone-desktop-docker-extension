FROM golang:1.18-alpine AS builder
ENV CGO_ENABLED=0
RUN apk add --update make git
WORKDIR /backend
COPY go.* .
RUN go install github.com/goreleaser/goreleaser@latest 
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    make bin-all

FROM --platform=$BUILDPLATFORM node:17.7-alpine3.14 AS client-builder
WORKDIR /ui
# cache packages in layer
COPY ui/package.json /ui/package.json
COPY ui/package-lock.json /ui/package-lock.json
RUN --mount=type=cache,target=/usr/src/app/.npm \
    npm set cache /usr/src/app/.npm && \
    npm ci
# install
COPY ui /ui
RUN npm run build

FROM alpine AS dl

RUN apk add --update --no-cache curl \
    && mkdir -p /tools/darwin/amd64 /tools/darwin/arm64 \
    && mkdir -p /tools/linux/ /tools/linux/arm64 \
    && mkdir -p /tools/windows/amd64 /tools/windows/arm64
 
## TODO https://docs.docker.com/desktop/extensions-sdk/extensions/multi-arch/
RUN curl -sL https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_darwin_amd64 -o /tools/darwin/amd64/yq \
  &&  curl -sL https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_darwin_arm64 -o /tools/darwin/arm64/yq \
  && chmod +x /tools/darwin/arm64/yq \
  && chmod +x /tools/darwin/amd64/yq
  
FROM alpine
LABEL org.opencontainers.image.title="drone-desktop" \
    org.opencontainers.image.description="An extension to help developers do CI on their laptops using Drone" \
    org.opencontainers.image.vendor="Harness Inc" \
    com.docker.desktop.extension.api.version=">= 0.2.3" \
    com.docker.extension.screenshots="" \
    com.docker.extension.detailed-description="" \
    com.docker.extension.publisher-url="" \
    com.docker.extension.additional-urls="" \
    com.docker.extension.changelog=""

#Darwin Tools -- Arch Harded coded now
COPY --from=dl /tools/darwin/arm64/yq /usr/local/bin/yq
COPY --from=builder /backend/dist/pipelines-finder_darwin_arm64/pipelines-finder /usr/local/bin/pipelines-finder

# Linux Tools

#Windows Tools

# Use Target Arch
COPY --from=builder /backend/dist/backend_linux_arm64/backend /
COPY docker-compose.yaml .
COPY metadata.json .
COPY *.svg .
COPY --from=client-builder /ui/build ui
RUN mkdir -p /data
CMD /backend -socket /run/guest-services/extension-drone-desktop.sock
