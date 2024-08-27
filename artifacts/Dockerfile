FROM nginx@sha256:af296b188c7b7df99ba960ca614439c99cb7cf252ed7bbc23e90cfda59092305

ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_group=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_uid=1001

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_gid=1001

# install packages and create user
RUN apt-get update -y && \
  apt-get install -y gnupg2 && \
  apt-get update -y && \
  apt-get install -y --no-install-recommends unzip wget zip openjdk-11-jdk && \
  groupadd -g ${container_user_gid} ${container_user_group} &&\
  rm -rf /var/lib/apt/lists/* &&\
  wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz &&\
  tar -xzf apache-maven-3.8.8-bin.tar.gz && mv apache-maven-3.8.8 /usr/local/maven && rm apache-maven-3.8.8-bin.tar.gz &&\
  useradd -u ${container_user_uid} -g ${container_user_group} -s /bin/sh -m ${container_user} \
  && mkdir -p /var/run/nginx /var/tmp/nginx \
  && chown -R ${container_user}:${container_user} /usr/share/nginx /var/run/nginx /var/tmp/nginx

COPY ./nginx.conf /etc/nginx/nginx.conf

ENV MAVEN_HOME /usr/local/maven
ENV PATH $MAVEN_HOME/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

# set working directory for the user
WORKDIR /home/${container_user}

ENV work_dir=/home/${container_user}

# environment variable for basepath
ENV base_path=/usr/share/nginx/html/artifactory


# environment variable for Cache Provider Jar path
ENV cache_path=${base_path}/libs-release-local/cache

# environment variable for mosip-plugins zip path
ENV mosip_plugins_zip_path=${base_path}/libs-release-local/mosip-plugins

# environment variable for i18n zip path
ENV i18n_zip_path=${base_path}/libs-release-local/i18n

# environment variable for theme zip path
ENV theme_zip_path=${base_path}/libs-release-local/theme

# environment variable for image zip path
ENV image_zip_path=${base_path}/libs-release-local/image

# environment variable for esignet wrappers zip path
ENV esignet_wrapper_lib_zip_path=${base_path}/libs-release-local/esignet

# environment variable for script path
ENV scripts_path=/home/mosip/scripts

# environment variable for jar version to be downloaed, this needed to be passed buildtime
ENV version=1.2.1-SNAPSHOT
ENV idp_auth_wrapper_version=0.0.1-SNAPSHOT

# Create all the jar, i18n & theme paths.
RUN mkdir -p ${mosip_plugins_zip_path} ${i18n_zip_path} ${theme_zip_path} ${image_zip_path} ${esignet_wrapper_lib_zip_path}/esignet-wrapper ${esignet_wrapper_lib_zip_path}/esignet-plugins
# Copy all the respective jars to the location

COPY /src/mosip-plugins/sign-in-with-esignet/sign-in-with-esignet.zip ${mosip_plugins_zip_path}/

COPY /src/i18n/oidc-demo-i18n-bundle/*  ${work_dir}/oidc-demo-i18n-bundle/

COPY /src/i18n/mock-relying-party-i18n-bundle/*  ${work_dir}/mock-relying-party-i18n-bundle/

COPY /src/i18n/esignet-i18n-bundle/*  ${work_dir}/esignet-i18n-bundle/

COPY /src/theme/esignet-theme/* ${work_dir}/esignet-theme/

COPY /src/image/esignet-image/* ${work_dir}/esignet-image/

COPY /src/image/esignet-signup-image/* ${work_dir}/esignet-signup-image/

COPY /src/i18n/esignet-signup-i18n-bundle/*  ${work_dir}/esignet-signup-i18n-bundle/

COPY /src/theme/esignet-signup-theme/* ${work_dir}/esignet-signup-theme/

COPY ./configure.sh ${work_dir}/

COPY pom.xml ${work_dir}/

RUN cd ${work_dir} && mvn dependency:resolve && mvn clean install

RUN bash configure.sh

RUN sed -i -e '/listen/!b' -e '/80;/!b' -e 's/80;/8080;/' /etc/nginx/conf.d/default.conf

# select container user for all tasks
USER ${container_user_uid}:${container_user_gid}

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
