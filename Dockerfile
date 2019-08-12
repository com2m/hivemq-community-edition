FROM gradle:jdk11 AS builder
# Build HiveMQ on gradle:jdk11 image.

# Make tmp directory and set workdir.
RUN mkdir /tmp/hivemq-source
WORKDIR /tmp/hivemq-source

COPY ./ ./

# Install dos2unix (for docker issue).
RUN apt-get update
RUN apt-get install dos2unix
RUN dos2unix ./gradlew

# Copy source code and build HiveMQ.
RUN whoami
RUN ./gradlew clean packaging -x test && ls -la && ls -la ./build && ls -la ./build/zip

# Unzip HiveMQ and run dos2unix on every file (issue with docker).
RUN unzip ./build/zip/hivemq-ce-2019.2-SNAPSHOT.zip -d ./build/zip/
RUN find ./build/zip/hivemq-ce-2019.2-SNAPSHOT -type f -print0 | xargs -0 dos2unix

# FROM com2m Alpine Base Image
FROM docker.com2m.de/iot/core/iot-openjdk11-alpine-base:snapshot

# Script parameter for HiveMQ Version, Group ID and User ID.
ARG HIVEMQ_GID=10000
ARG HIVEMQ_UID=10000

# Additional JVM options, may be overwritten by user
ENV JAVA_OPTS "-XX:+UseNUMA"

RUN set -x \
	&& apk update \
	&& apk add --no-cache tini

# Build HiveMQ

COPY --from=builder /tmp/hivemq-source/build/zip/hivemq-ce-2019.2-SNAPSHOT /opt/hivemq-ce-2019.2-SNAPSHOT
RUN ln -s /opt/hivemq-ce-2019.2-SNAPSHOT /opt/hivemq

RUN ls -la /opt
RUN ls -la /opt/hivemq-ce-2019.2-SNAPSHOT

WORKDIR /opt/hivemq

# Configure user and group for HiveMQ
RUN addgroup -g ${HIVEMQ_GID} hivemq \
    && adduser -D -G hivemq -h /opt/hivemq-ce-2019.2-SNAPSHOT -u ${HIVEMQ_UID} hivemq \
    && chown -R hivemq:hivemq /opt/hivemq-ce-2019.2-SNAPSHOT \
    && chmod -R 777 /opt \
    && chmod +x /opt/hivemq-ce-2019.2-SNAPSHOT/bin/run.sh

# Substitute eval for exec and replace OOM flag if necessary (for older releases). This is necessary for proper signal propagation
RUN sed -i -e 's|eval \\"java\\" "$HOME_OPT" "$JAVA_OPTS" -jar "$JAR_PATH"|exec "java" $HOME_OPT $JAVA_OPTS -jar "$JAR_PATH"|' /opt/hivemq/bin/run.sh && \
    sed -i -e "s|-XX:OnOutOfMemoryError='sleep 5; kill -9 %p'|-XX:+CrashOnOutOfMemoryError|" /opt/hivemq/bin/run.sh

# Make config folder available on host
VOLUME /opt/hivemq/conf

# Make broker data persistent throughout stop/start cycles
VOLUME /opt/hivemq/data

# Persist log data
VOLUME /opt/hivemq/log

EXPOSE 1883
EXPOSE 8083

WORKDIR /opt/hivemq
# USER ${HIVEMQ_UID}

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/opt/hivemq-ce-2019.2-SNAPSHOT/bin/run.sh"]