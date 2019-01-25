FROM ubuntu:14.04

# Install https packages for apt
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv 1655a0ab68576280 && apt-key update && apt-get update

# Install necessary apt packages
RUN apt-get install -y build-essential libxml2-dev libxslt-dev git curl g++ gcc curl \
&& apt-get clean

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm install 2.3.3"
RUN /bin/bash -l -c "rvm use 2.3.3"
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN /bin/bash -l -c "gem install bundler -v "1.16.2" --no-ri --no-rdoc"

# Setup cloudhealth user
RUN useradd -d /home/cloudhealth/ -m cloudhealth

ADD docker/config/bundle/config /home/cloudhealth/.bundle/config
RUN chown -R cloudhealth:cloudhealth /home/cloudhealth/.bundle/

RUN mkdir -p /home/cloudhealth/amazon-pricing
RUN mkdir -p /home/cloudhealth/amazon-pricing/lib
RUN mkdir -p /home/cloudhealth/amazon-pricing/lib/amazon-pricing

# Copying Gemfile and related files
COPY Gemfile /home/cloudhealth/amazon-pricing
COPY amazon-pricing.gemspec /home/cloudhealth/amazon-pricing
COPY lib/amazon-pricing/version.rb /home/cloudhealth/amazon-pricing/lib/amazon-pricing

RUN chown -R cloudhealth:cloudhealth /home/cloudhealth/amazon-pricing

WORKDIR /home/cloudhealth/amazon-pricing
USER cloudhealth

RUN /bin/bash -c -l "USE_SYSTEM_GECODE=1 RAILS_ENV=test bundle install --no-deployment --binstubs=bin"