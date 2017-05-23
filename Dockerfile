FROM debian:jessie
MAINTAINER Daniel Park <dan.mcpark84@gmail.com>

# Add Java 8 repository
ENV DEBIAN_FRONTEND noninteractive
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update && apt-get install -y git

# Set the environment variables
ENV HOME /root
ENV ONOS_ROOT /root/onos
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV BUILD_NUMBER docker
ENV JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
ENV PATH="$PATH:/usr/bin"
ENV PATH="$PATH:/root/onos/tools/build"

WORKDIR /root
RUN     git clone https://github.com/opennetworkinglab/onos.git onos && \
        apt-get install -y vim maven python less zip curl oracle-java8-installer oracle-java8-set-default && \ 
        /bin/bash -c ". onos/tools/dev/bash_profile" && \
        cd onos && \
        tools/build/onos-buck build onos && \
        tools/build/onos-buck-publish-local && \
        tools/build/onos-buck publish --to-local-repo //protocols/ovsdb/api:onos-protocols-ovsdb-api && \
        tools/build/onos-buck publish --to-local-repo //protocols/ovsdb/rfc:onos-protocols-ovsdb-rfc && \
        tools/build/onos-buck publish --to-local-repo //apps/openstacknode:onos-apps-openstacknode && \
        cd apps/openstacknetworking && \
        mvn clean install

WORKDIR /root
RUN	mkdir onos-service && \
	tar -xf onos/buck-out/gen/tools/package/onos-package/onos.tar.gz -C onos-service --strip-components=1 && \
	rm onos/buck-out/gen/tools/package/onos-package/onos.tar.gz && \
        cd onos-service && \
        touch apps/org.onosproject.openstacknetworking/active && \
        touch apps/org.onosproject.drivers/active && \
        touch apps/org.onosproject.openflow-base/active && \
        cd apache-karaf*/system/org/onosproject/onos-apps-openstacknetworking*/1.1*/ && \
        rm *.jar && \
        cp /root/onos/apps/openstacknetworking/target/onos-apps-openstacknetworking-1.11.0-SNAPSHOT.jar onos-apps-openstacknetworking-1.11.0-SNAPSHOT.jar && \
        rm -rf /root/.m2 && \
        rm -rf /root/onos

EXPOSE 6653 6640 8181 8101 9876
WORKDIR /root/onos-service
ENTRYPOINT ["./bin/onos-service"]
