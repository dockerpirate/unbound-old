FROM alpine

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL org.opencontainers.image.title "dockerpirate/unbound"
LABEL org.opencontainers.image.description "Unbound is a validating, recursive, caching DNS resolver"
LABEL org.opencontainers.image.created "${BUILD_DATE}"
LABEL org.opencontainers.image.version "${BUILD_VERSION}"
LABEL org.opencontainers.image.revision "${VCS_REF}"

RUN apk update && \
	apk add unbound ldns drill
#RUN chown=nobody:nogroup /var/run/unbound /var/run/unbound

COPY a-records.conf unbound.conf /opt/unbound/etc/unbound/

#USER nobody

ENTRYPOINT ["unbound", "-d"]

# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
	# CMD [ "drill", "-p", "5053", "nlnetlabs.nl", "@127.0.0.1" ]

RUN ["unbound", "-V"]

RUN ["drill", "-v"]
