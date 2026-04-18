FROM quay.io/fedora/fedora-bootc:43

ARG KEEL_VERSION
ARG KEEL_BUILD_DATE

LABEL org.opencontainers.image.title="Keel Base" \
      org.opencontainers.image.description="Base bootc image" \
      org.opencontainers.image.url="https://github.com/azaurus1/keel" \
      org.opencontainers.image.source="https://github.com/azaurus1/keel" \
      org.opencontainers.image.version="${KEEL_VERSION}" \
      org.opencontainers.image.created="${KEEL_BUILD_DATE}" \
      org.opencontainers.image.revision="${KEEL_VERSION}"

# Locking root
RUN passwd -l root

COPY ./build/keel-release /usr/lib/keel/release

RUN bootc container lint --fatal-warnings