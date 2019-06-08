FROM reactnativecommunity/react-native-android

# Install fastlane 
RUN apt-get update -y && \
	apt-get install -y \
	ruby \
	ruby-dev && \
	gem install fastlane -NV

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8