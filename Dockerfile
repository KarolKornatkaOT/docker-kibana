FROM oberthur/docker-ubuntu:16.04

MAINTAINER Karol Kornatka <k.kornatka@oberthur.com>

ENV KIBANA_MAJOR=4.5
ENV KIBANA_VERSION=4.5.0
ENV TINI_VERSION=v0.9.0
ENV ELASTICSEARCH_URL="http://127.0.0.1:9200"
ENV GOSU_VERSION=1.7
ENV PATH /opt/kibana/bin:$PATH

# add our user and group first to make sure their IDs get assigned consistently
RUN set -x \
  && groupadd -r kibana && useradd -r -m -g kibana kibana \
	&& apt update && apt install wget ca-certificates \

# grab gosu for easy step-down from root
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \

# grab tini for signal processing and zombie killing
	&& wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini" \
	&& wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
	&& gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
	&& rm -r "$GNUPGHOME" /usr/local/bin/tini.asc \
	&& chmod +x /usr/local/bin/tini \
	&& tini -h \

	&& apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4 \

	&& echo "deb http://packages.elastic.co/kibana/${KIBANA_MAJOR}/debian stable main" > /etc/apt/sources.list.d/kibana.list \

	&& apt-get update \
	&& apt-get install -y --no-install-recommends kibana=$KIBANA_VERSION \
	&& chown -R kibana:kibana /opt/kibana \
	&& rm -rf /var/lib/apt/lists/* \
# ensure the default configuration is useful when using --link
	&& sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 'http://elasticsearch:9200'!" /opt/kibana/config/kibana.yml \
	&& grep -q 'elasticsearch:9200' /opt/kibana/config/kibana.yml \
        && apt-get clean autoclean \
        && apt-get autoremove --yes \
        && rm -rf /var/lib/{apt,dpkg,cache,log}/ 

COPY docker-entrypoint.sh /

EXPOSE 5601
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kibana"]
