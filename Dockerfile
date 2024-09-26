FROM ubuntu:focal
LABEL maintainer="BIND 9 Developers <bind9-dev@isc.org>"

ARG DEB_VERSION="1:9.16.19-1+ubuntu20.04.1+isc+1"
ARG ISC_SIGNING_KEY="66150059ED19A2882208E278A36654A4FDD4630D"

ENV LC_ALL C.UTF-8

RUN set -eux; \
    export DEBIAN_FRONTEND="noninteractive"; \
    apt-get -qqqy update; \
    # install the isc ppa (manually)
    apt-get -qqqy install --no-install-recommends \
        dirmngr \
        gpg \
        gpg-agent \
    ; \
    export GPGHOME="$(mktemp -d)"; \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$ISC_SIGNING_KEY"; \
    gpgconf --kill all; \
    rm -rf "$GPGHOME"; \
    apt-key list >/dev/null; \
    . /etc/os-release; \
    printf 'deb http://ppa.launchpad.net/isc/bind/ubuntu %s main' \
        "$UBUNTU_CODENAME" \
        > /etc/apt/sources.list.d/isc.list; \
    apt-get -qqqy update; \
    # install bind
    apt-get -qqqy install --no-install-recommends \
        bind9=$DEB_VERSION \
        bind9-utils=$DEB_VERSION \
    ; \
    # cleanup
    apt-get -qqqy purge \
        dirmngr \
        gpg \
        gpg-agent \
    ; \
    apt-get -qqqy autoremove; \
    apt-get -qqqy clean; \
    rm -rf /var/lib/apt/lists/*;

RUN set -eux; \
    for dir in \
        /etc/bind \
        /run/named \
        /var/cache/bind \
        /var/lib/bind \
        /var/log/bind \
    ; do \
        mkdir -p "$dir"; \
        chown bind:bind "$dir"; \
        chmod 755 "$dir"; \
    done; \
    chown root:bind /etc/bind

VOLUME [ \
    "/etc/bind", \
    "/var/cache/bind", \
    "/var/lib/bind", \
    "/var/log" \
]

EXPOSE 53/udp 53/tcp 953/tcp

CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]
