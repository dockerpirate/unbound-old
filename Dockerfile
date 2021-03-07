ARG ALPINE_M
ARG ALPINE_P

FROM alpine:$ALPINE_M.$ALPINE_P

ARG UNBOUND_M
ARG UNBOUND_P
ARG LDNS

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache \
	build-base \
	curl \
	expat-dev \
	libevent-dev \
	libevent-static \
	linux-headers \
	openssl-dev \
	perl

WORKDIR /tmp/unbound

ARG UNBOUND_SOURCE=https://www.nlnetlabs.nl/downloads/unbound/unbound-
ARG UNBOUND_VERSION=1.13.1
ARG UNBOUND_SHA256=8504d97b8fc5bd897345c95d116e0ee0ddf8c8ff99590ab2b4bd13278c9f50b8

RUN curl -fsSL --retry 3 "${UNBOUND_SOURCE}${UNBOUND_VERSION}.tar.gz" -o unbound.tar.gz \
	&& echo "${UNBOUND_SHA256}  unbound.tar.gz" | sha256sum -c - \
	&& tar xzf unbound.tar.gz --strip 1 \
	&& ./configure --with-pthreads --with-libevent --prefix=/opt/unbound --with-run-dir=/var/run/unbound --with-username= --with-chroot-dir= --enable-fully-static --disable-shared --enable-event-api --disable-flto \
	&& make -j 4 install

WORKDIR /tmp/ldns

ARG LDNS_SOURCE=https://www.nlnetlabs.nl/downloads/ldns/ldns-
ARG LDNS_VERSION=1.7.1
ARG LDNS_SHA1=d075a08972c0f573101fb4a6250471daaa53cb3e

RUN curl -fsSL --retry 3 "${LDNS_SOURCE}${LDNS_VERSION}.tar.gz" -o ldns.tar.gz \
	&& echo "${LDNS_SHA1}  ldns.tar.gz" | sha1sum -c - \
	&& tar xzf ldns.tar.gz --strip 1 \
	&& sed -e 's/@LDFLAGS@/@LDFLAGS@ -all-static/' -i Makefile.in \
	&& ./configure --prefix=/opt/ldns --with-drill --disable-shared \
	&& make -j 4 \
	&& make install

WORKDIR /var/run/unbound

RUN mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/example.conf \
	&& rm -rf /tmp/* /opt/*/include /opt/*/man /opt/*/share \
	&& strip /opt/unbound/sbin/unbound \
	&& strip /opt/ldns/bin/drill \
	&& (/opt/unbound/sbin/unbound-anchor -v || :)

# ----------------------------------------------------------------------------

FROM scratch

LABEL org.opencontainers.image.authors "Kyle Harding <https://klutchell.dev>"
LABEL org.opencontainers.image.url "https://gitlab.com/klutchell/unbound"
LABEL org.opencontainers.image.documentation "https://gitlab.com/klutchell/unbound"
LABEL org.opencontainers.image.source "https://gitlab.com/klutchell/unbound"
LABEL org.opencontainers.image.title "klutchell/unbound"
LABEL org.opencontainers.image.description "Unbound is a validating, recursive, caching DNS resolver"

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /lib/ld-musl-*.so.1 /lib/

COPY --from=build /opt /opt
COPY --from=build --chown=nobody:nogroup /var/run/unbound /var/run/unbound

COPY a-records.conf unbound.conf /opt/unbound/etc/unbound/

USER nobody

ENV PATH /opt/unbound/sbin:/opt/ldns/bin:${PATH}

ENTRYPOINT ["unbound", "-d"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
	CMD [ "drill", "-p", "5053", "nlnetlabs.nl", "@127.0.0.1" ]
