FROM gradle:jdk11 AS builder

# Make tmp directory and set workdir.
RUN mkdir /tmp/hivemq-source
WORKDIR /tmp/hivemq-source
ARG HIVEMQ_VERSION=2021.3

COPY ./ ./

# Install dos2unix (for docker issue).
RUN apt -o Acquire::Check-Date=false update
RUN apt install -y apt-utils
RUN apt install dos2unix
RUN dos2unix ./gradlew

# Copy source code and build HiveMQ.
RUN whoami
RUN ./gradlew clean build hivemqZip -x test && ls -la && ls -la ./build && ls -la ./build/zip

# Unzip HiveMQ and run dos2unix on every file (issue with docker).
RUN unzip ./build/zip/hivemq-ce-${HIVEMQ_VERSION}.zip -d ./build/zip/
RUN find ./build/zip/hivemq-ce-${HIVEMQ_VERSION} -type f -print0 | xargs -0 dos2unix

FROM docker.com2m.de/iot/core/iot-base-image:zulu-openjdk-17.0.3-alpine-0

ARG HIVEMQ_VERSION=2021.3
ENV HIVEMQ_GID=10000
ENV HIVEMQ_UID=10000

# Additional JVM options, may be overwritten by user
ENV JAVA_OPTS "-XX:+UnlockExperimentalVMOptions -XX:+UseNUMA"

# Default allow all extension, set this to false to disable it
ENV HIVEMQ_ALLOW_ALL_CLIENTS "false"

# Set locale
ENV LANG=en_US.UTF-8

RUN set -x \
	&& apk update \
	&& apk add --no-cache tini

COPY config.xml /opt/config.xml
COPY docker-entrypoint.sh /opt/docker-entrypoint.sh

# HiveMQ setup
COPY --from=builder /tmp/hivemq-source/build/zip/hivemq-ce-${HIVEMQ_VERSION} /opt/hivemq-ce-${HIVEMQ_VERSION}
RUN ln -s /opt/hivemq-ce-${HIVEMQ_VERSION} /opt/hivemq

RUN ls -la /opt
RUN ls -la /opt/hivemq-ce-${HIVEMQ_VERSION}

WORKDIR /opt/hivemq

# Configure user and group for HiveMQ
RUN addgroup -g ${HIVEMQ_GID} hivemq \
    && adduser -D -G hivemq -h /opt/hivemq-ce-${HIVEMQ_VERSION} --u ${HIVEMQ_UID} hivemq \
    && chown -R hivemq:hivemq /opt/hivemq-ce-${HIVEMQ_VERSION} \
    && chmod -R 777 /opt \
    && chmod +x /opt/hivemq/bin/run.sh /opt/docker-entrypoint.sh

# Substitute eval for exec and replace OOM flag if necessary (for older releases). This is necessary for proper signal propagation
RUN sed -i -e 's|eval \\"java\\" "$HOME_OPT" "$JAVA_OPTS" -jar "$JAR_PATH"|exec "java" $HOME_OPT $JAVA_OPTS -jar "$JAR_PATH"|' /opt/hivemq/bin/run.sh && \
    sed -i -e "s|-XX:OnOutOfMemoryError='sleep 5; kill -9 %p'|-XX:+CrashOnOutOfMemoryError|" /opt/hivemq/bin/run.sh

RUN sed -i -e 's|exec "java" "${HOME_OPT}" "${HEAPDUMP_PATH_OPT}" ${JAVA_OPTS} -jar "${JAR_PATH}"|exec "java" "${HOME_OPT}" "${HEAPDUMP_PATH_OPT}" ${JAVA_OPTS} -XX:OnOutOfMemoryError="kill 0" -jar "${JAR_PATH}"|' /opt/hivemq/bin/run.sh

# Make broker data persistent throughout stop/start cycles
VOLUME /opt/hivemq/data

# Persist log data
VOLUME /opt/hivemq/log

#mqtt-clients
EXPOSE 1883

#websockets
EXPOSE 8000

WORKDIR /opt/hivemq

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/opt/hivemq/bin/run.sh"]
