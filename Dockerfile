#Dockerfile
FROM phusion/passenger-ruby25:0.9.35 AS airett_api
LABEL maintainer = "Gabriele Gambotto <gambotto@leva.io>"

# Ensure that our apt package list is updated and install a few
# packages to ensure that we can compile assets
RUN apt-get update && apt-get install -y -o Dpkg::Options::="--force-confold" \
imagemagick \
nodejs \
ffmpeg

# Set correct environment variables.
ENV HOME /root

# Start Nginx / Passenger
RUN rm -f /etc/service/nginx/down

# Remove the default site
RUN rm /etc/nginx/sites-enabled/default

# Prepare folders
RUN mkdir /home/app/webapp

RUN gem install bundler --no-ri --no-rdoc 

# Run Bundle in a cache efficient way
WORKDIR /tmp
ADD ./rails/Gemfile      /tmp/
ADD ./rails/Gemfile.lock /tmp/

RUN bundle install

# Install library for carrierwave-video-thumbnailer
RUN apt-get --yes install ffmpegthumbnailer

##
# Local
FROM airett_api AS api_local

# Adding this file to prevent ImageTragick
ADD ./docker/imagemagick_patch/policy.xml /etc/ImageMagick

WORKDIR /home/app/webapp

RUN chown -R app:app /home/app/webapp

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Adding file to create symlink to rails executable in container's /usr/bin
#ADD ./docker/rails-symlinks-generator.sh /home/app/webapp/docker/rails-symlinks-generator.sh

# Give executable permission to the script
#RUN chmod 700 /home/app/webapp/docker/rails-symlinks-generator.sh

# Run previus copied script
#RUN /home/app/webapp/docker/rails-symlinks-generator.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

##
# Remote
FROM airett_api AS api_remote

# Add the Rails app
ADD ./rails/ /home/app/webapp

# Adding this file to prevent ImageTragick
ADD ./docker/imagemagick_patch/policy.xml /etc/ImageMagick

WORKDIR /home/app/webapp

RUN chown -R app:app /home/app/webapp

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Adding file to create symlink to rails executable in container's /usr/bin
#ADD ./docker/rails-symlinks-generator.sh /home/app/webapp/docker/rails-symlinks-generator.sh

# Give executable permission to the script
#RUN chmod 700 /home/app/webapp/docker/rails-symlinks-generator.sh

# Run previus copied script
#RUN /home/app/webapp/docker/rails-symlinks-generator.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]