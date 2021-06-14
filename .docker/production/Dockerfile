########################
### app/rails config ###
########################

FROM ruby:2.3.3 AS app

LABEL author="IdeaCrew"

# Install required packages/libraries
RUN apt-get update && \
    apt-get -yq dist-upgrade && \
    apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev libffi-dev libffi6 libreadline-dev \
                       zlibc libgdbm-dev libncurses-dev autoconf fontconfig unzip zip sshpass bzip2 libxrender1 libxext6 \
                       build-essential && \
    apt-get autoremove -y

#git gcc-c++ gcc libgcc glibc-devel glibc-headers glibc openssl-devel libyaml yaml-cpp-devel yaml-cpp libffi readline-devel zlib-devel gdbm-devel ncurses-devel autoconf unzip bzip2
# Configure bundler and PATH, install bundler version
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
    BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH $BUNDLE_BIN:$GEM_HOME/gems/bin:$PATH

ARG BUNDLER_VERSION_OVERRIDE
ENV BUNDLER_VERSION=$BUNDLER_VERSION_OVERRIDE
RUN gem update --system && gem install bundler:$BUNDLER_VERSION

# Configure app home directory
ENV HOME /soa
RUN mkdir -p $HOME
WORKDIR $HOME
COPY . $HOME

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install --jobs 20 --retry 5 --without development test 

