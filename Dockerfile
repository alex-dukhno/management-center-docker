FROM openjdk:11-jre-slim-sid

ENV MC_VERSION 4.2020.08
ENV MC_HOME /opt/hazelcast/management-center
ENV MC_DATA /data

ENV MC_HTTP_PORT 8080
ENV MC_HTTPS_PORT 8443
ENV MC_HEALTH_CHECK_PORT 8081
ENV MC_CONTEXT_PATH /

ARG MC_INSTALL_NAME="hazelcast-management-center-${MC_VERSION}"
ARG MC_INSTALL_ZIP="${MC_INSTALL_NAME}.zip"
ARG MC_INSTALL_JAR="hazelcast-management-center-${MC_VERSION}.jar"

ENV MC_RUNTIME "${MC_HOME}/${MC_INSTALL_JAR}"

ENV USER_NAME="hazelcast" \
    USER_UID=10001

# Install wget to download Management Center
RUN apt-get update \
 && apt-get install --no-install-recommends --yes \
      wget unzip \
 && rm -rf /var/lib/apt/lists/*

# chmod allows running container as non-root with `docker run --user` option
RUN mkdir -p ${MC_HOME} ${MC_DATA} \
 && chmod a+rwx ${MC_HOME} ${MC_DATA}
WORKDIR ${MC_HOME}

# Prepare Management Center
RUN wget -O ${MC_HOME}/${MC_INSTALL_ZIP} \
          http://download.hazelcast.com/management-center/${MC_INSTALL_ZIP} \
 && unzip ${MC_INSTALL_ZIP} \
      -x ${MC_INSTALL_NAME}/docs/* \
      -x ${MC_INSTALL_NAME}/*.bat \
 && rm -rf ${MC_INSTALL_ZIP} \
 && mv ${MC_INSTALL_NAME}/* . \
 && rm -rf ${MC_INSTALL_NAME}

# Runtime environment variables
ENV JAVA_OPTS_DEFAULT "-Dhazelcast.mc.home=${MC_DATA} -Djava.net.preferIPv4Stack=true"

ENV NO_CONTAINER_SUPPORT "false"
ENV MIN_HEAP_SIZE ""
ENV MAX_HEAP_SIZE ""

ENV JAVA_OPTS ""
ENV MC_INIT_SCRIPT ""
ENV MC_INIT_CMD ""

ENV MC_CLASSPATH ""

ENV MC_ADMIN_USER ""
ENV MC_ADMIN_PASSWORD ""

COPY files/mc-start.sh /mc-start.sh
RUN chmod +x /mc-start.sh

RUN echo "Adding non-root user" \
    && useradd -l -u $USER_UID -r -g 0 -d $MC_HOME -s /sbin/nologin -c "${USER_UID} application user" $USER_NAME \
    && chown -R $USER_UID:0 $MC_HOME ${MC_DATA} \
    && chmod -R g=u "$MC_HOME" ${MC_DATA} \
    && chmod -R +r $MC_HOME ${MC_DATA}

### Switch to hazelcast user
USER ${USER_UID}

VOLUME ["${MC_DATA}"]
EXPOSE ${MC_HTTP_PORT}
EXPOSE ${MC_HTTPS_PORT}
EXPOSE ${MC_HEALTH_CHECK_PORT}

# Start Management Center
CMD ["bash", "/mc-start.sh"]
