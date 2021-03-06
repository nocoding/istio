# syntax = docker/dockerfile:experimental

ARG VERSION
ARG BASE_DISTRIBUTION=default

FROM istio/pilot:${VERSION} as pilot-amd64

FROM golang:1.15 as pilot-arm64-builder

ARG VERSION
ARG GOPROXY=https://goproxy.io,direct

RUN git clone --depth=1 -b ${VERSION} https://github.com/istio/istio /go/src/istio.io/istio
WORKDIR /go/src/istio.io/istio

# build pilot-discovery
RUN --mount=type=cache,id=gomod,target=/go/pkg/mod \
    STATIC=0 \
    GOOS=$(go env GOOS) \
    GOARCH=$(go env GOARCH) \
    LDFLAGS='-extldflags -static -s -w' \
    common/scripts/gobuild.sh /go/bin/ ./pilot/cmd/pilot-discovery

# https://github.com/istio/istio/blob/master/pilot/docker/Dockerfile.pilot
FROM ${BASE_DISTRIBUTION} as pilot-arm64

# copy bin
COPY --from=pilot-arm64-builder /go/bin/pilot-discovery /usr/local/bin/pilot-discovery

# copy pem from offical amd64 image
COPY --from=pilot-amd64 /cacert.pem /cacert.pem

USER 1337:1337

ENTRYPOINT ["/usr/local/bin/pilot-discovery"]

# for oci image, amd64 from offical, arm64 from rebuild
FROM pilot-${TARGETARCH}