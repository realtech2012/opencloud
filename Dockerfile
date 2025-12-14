# Please use this Dockerfile only if
# you want to build an image from source without
# pnpm and Go installed on your dev machine.

# You can build OpenCloud using this Dockerfile
# by running following command:
# `docker build -t opencloud/opencloud:custom .`

# In most other cases you might want to run the
# following command instead:
# `make -C opencloud dev-docker`
# It will build a `opencloud/opencloud:dev` image for you
# and use your local pnpm and Go caches and therefore
# is a lot faster than the build steps below.


FROM owncloudci/nodejs:18 AS generate

COPY ./ /opencloud/

# Run generation from repo root so module `services/...` paths resolve correctly.
WORKDIR /opencloud
RUN make node-generate-prod || true && \
        if [ ! -d services/idp/assets ] || [ ! -s services/idp/assets/identifier/index.html ]; then \
                cd services/idp && pnpm install --no-frozen-lockfile && pnpm build; \
        fi

FROM golang:1.24-alpine AS build
RUN apk add bash make git curl gcc musl-dev libc-dev binutils-gold inotify-tools vips-dev

COPY --from=generate /opencloud /opencloud

WORKDIR /opencloud/opencloud
RUN make go-generate build ENABLE_VIPS=true

FROM alpine:3.20

RUN apk add --no-cache attr ca-certificates curl mailcap tree vips && \
	echo 'hosts: files dns' >| /etc/nsswitch.conf

LABEL maintainer="OpenCloud GmbH <devops@opencloud.eu>" \
        org.opencontainers.image.title="OpenCloud" \
        org.opencontainers.image.vendor="OpenCloud GmbH" \
        org.opencontainers.image.authors="OpenCloud GmbH" \
        org.opencontainers.image.description="OpenCloud is a modern file-sync and share platform" \
        org.opencontainers.image.licenses="Apache-2.0" \
        org.opencontainers.image.documentation="https://github.com/opencloud-eu/opencloud" \
        org.opencontainers.image.source="https://github.com/realtech2012/opencloud"

ARG REVISION=""
LABEL org.opencontainers.image.revision="$REVISION"

EXPOSE 9200 5200 9174

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -k -f https://127.0.0.1:9200/ || exit 1

ENTRYPOINT ["/usr/bin/opencloud"]
CMD ["server"]

COPY --from=build /opencloud/opencloud/bin/opencloud /usr/bin/opencloud
