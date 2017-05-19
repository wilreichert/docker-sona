FROM debian:jessie
MAINTAINER Daniel Park <dan.mcpark84@gmail.com> 

# Add Java 8 repository
ENV DEBIAN_FRONTEND noninteractive
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update && apt-get install -y git && \
    git clone https://github.com/opennetworkinglab/onos.git

# Set the environment variables
ENV HOME /root
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV BUILD_NUMBER docker
ENV JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
ENV ONOS_ROOT /src/onos
ENV PATH="$PATH:/usr/bin"
ENV PATH="$PATH:/src/onos/tools/build"
ENV PATH="$PATH:/src/maven/bin"
# Copy in the source
COPY onos /src/onos/

# Build ONOS
WORKDIR /src
RUN     apt-get install -y python less zip curl oracle-java8-installer oracle-java8-set-default && \
        wget http://mirror.navercorp.com/apache/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz && \
        mkdir maven && \
        tar -xf apache-maven-3.5.0-bin.tar.gz -C maven --strip-components=1 && \
        rm -rf apache-maven-3.5.0-bin.tar.gz && \
        cd onos/tools/build && \
        onos-buck build onos && \
        onos-buck-publish-local && \
        onos-buck publish --to-local-repo //protocols/ovsdb/api:onos-protocols-ovsdb-api && \
        onos-buck publish --to-local-repo //protocols/ovsdb/rfc:onos-protocols-ovsdb-rfc && \
        onos-buck publish --to-local-repo //apps/openstacknode:onos-apps-openstacknode && \
        cd .. && \
        cd ../apps/openstacknetworking && \
        mvn clean install && \
        cp ./target/*.oar /tmp/org.onosproject.openstacknetworking.oar && \
        cd .. && \
        cd .. && \
        cp buck-out/gen/tools/package/onos-package/onos.tar.gz /tmp/ && \
        cd .. && \
        rm -rf onos && \
        rm -rf /root/.m2 && \
        apt-get remove --purge -y `apt-mark showauto` && \
        apt-get install oracle-java8-set-default -y && \
        apt-get clean && apt-get purge -y && apt-get autoremove -y && \
        rm -rf /var/lib/apt/lists/* && \
        rm -rf /var/cache/oracle-jdk8-installer

# Change to /root directory
WORKDIR /root

# Install ONOS
RUN mkdir onos && \
   mv /tmp/onos.tar.gz . && \
   tar -xf onos.tar.gz -C onos --strip-components=1 && \
   rm -rf onos.tar.gz && \
   cd onos/apps/org.onosproject.openstacknetworking && \
   rm -rf org.onosproject.openstacknetworking.oar && \
   cp /tmp/org.onosproject.openstacknetworking.oar . && \
   touch active && \
   touch ../org.onosproject.drivers/active && \
   touch ../org.onosproject.openflow-base/active 

# Ports
# 6653 - OpenFlow
# 6640 - OVSDB
# 8181 - GUI
# 8101 - ONOS CLI
# 9876 - ONOS CLUSTER COMMUNICATION
EXPOSE 6653 6640 8181 8101 9876

# Get ready to run command
WORKDIR /root/onos
ENTRYPOINT ["./bin/onos-service"]
