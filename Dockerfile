FROM library/ubuntu:16.04

# https://github.com/facebook/react-native/blob/8c7b32d5f1da34613628b4b8e0474bc1e185a618/ContainerShip/Dockerfile.android-base

# set default build arguments
ARG ANDROID_TOOLS_VERSION=26.0.3
ARG NODE_VERSION=9.5.0


ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=\"-Xmx512m -XX:+HeapDumpOnOutOfMemoryError\"" \
	LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8' \
	ADB_INSTALL_TIMEOUT=10 \
	PATH=${PATH}:/opt/buck/bin/ \
	ANDROID_HOME=/opt/android \
	ANDROID_SDK_HOME=${ANDROID_HOME} \
	PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools \
	PATH=${PATH}:${HOME}/.fastlane/bin \
	NPM_CONFIG_LOGLEVEL=info \
	PATH=${PATH}:/opt/tools

# install system dependencies
RUN apt-get update -y && \
	apt-get install -y \
	autoconf \
	automake \
	expect \
	curl \
	g++ \
	gcc \
	git \
	libqt5widgets5 \
	lib32z1 \
	lib32stdc++6 \
	make \
	maven \
	openjdk-8-jdk \
	python-dev \
	python3-dev \
	qml-module-qtquick-controls \
	qtdeclarative5-dev \
	unzip \
	ruby \
	ruby-dev \
	xz-utils \
	locales \
	&& \
	rm -rf /var/lib/apt/lists/* && \
	apt-get autoremove -y && \
	apt-get clean 

# fix crashing gradle because of non ascii characters in ENV variables: https://github.com/gradle/gradle/issues/3117
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# install nodejs
# https://github.com/nodejs/docker-node/blob/a5141d841167d109bcad542c9fb636607dabc8b1/6.10/Dockerfile
# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
	&& for key in \
	94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
	FD3A5288F042B6850C66B31F09FE44734EB7990E \
	71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
	DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
	C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
	B9AE9905FFD7803F25714661B63B535A4C206CA9 \
	56730D5401028683275BD23C23EFEFE93C4CFFFE \
	77984A986EBC2AA786BC0F66B01FBB92821C587A \
	; do \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done && \
	curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
	&& curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
	&& tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
	&& ln -s /usr/bin/node /usr/bin/nodejs

# configure npm
RUN npm config set spin=false
RUN npm config set progress=false

RUN npm install -g react-native-cli

# Full reference at https://dl.google.com/android/repository/repository2-1.xml
# download and unpack android
RUN mkdir -p /opt/android && mkdir -p /opt/tools
WORKDIR /opt/android
RUN curl --silent https://dl.google.com/android/repository/tools_r$ANDROID_TOOLS_VERSION-linux.zip > android.zip && \
	unzip android.zip && \
	rm android.zip

# copy tools folder
COPY tools/android-accept-licenses.sh /opt/tools/android-accept-licenses.sh

RUN mkdir -p $ANDROID_HOME/licenses/ \
	&& echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > $ANDROID_HOME/licenses/android-sdk-license \
	&& echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

# sdk
RUN /opt/tools/android-accept-licenses.sh "$ANDROID_HOME/tools/bin/sdkmanager \
	tools \
	\"platform-tools\" \
	\"build-tools;25.0.3\" \
	\"platforms;android-23\" \
	\"platforms;android-25\" \
	\"platforms;android-26\" \
	\"extras;android;m2repository\" \
	\"extras;google;m2repository\" \
	\"add-ons;addon-google_apis-google-24\" \
	\"extras;google;google_play_services\"" \
	&& $ANDROID_HOME/tools/bin/sdkmanager --update

# Install fastlane 
RUN gem install fastlane

VOLUME ["/app"]
WORKDIR /app
