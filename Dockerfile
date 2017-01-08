FROM finalduty/archlinux
MAINTAINER Julian Xhokaxhiu <info at julianxhokaxhiu dot com>

# Environment variables
#######################

ENV SRC_DIR /srv/src
ENV CCACHE_DIR /srv/ccache
ENV OUT_DIR /srv/out

# Configurable environment variables
####################################

# By default we want to use CCACHE, you can disable this
# WARNING: disabling this may slow down a lot your builds!
ENV USE_CCACHE 1

# Environment for the LineageOS Branch name
ENV BRANCH_NAME 'cm-14.1'

# Environment for the device list ( separate by comma if more than one)
# eg. DEVICE_LIST=hammerhead,bullhead,angler
ENV DEVICE_LIST ''

# OTA URL that will be used inside CMUpdater
# Use this in combination with LineageOTA to make sure your device can auto-update itself from this buildbot
ENV OTA_URL ''

# User identity
ENV USER_NAME 'LineageOS Buildbot'
ENV USER_MAIL 'lineageos-buildbot@docker.host'

# If you want to start always fresh ( re-download all the source code everytime ) set this to 'true'
ENV CLEAN_SRCDIR false

# If you want to preserve old ZIPs set this to 'false'
ENV CLEAN_OUTDIR true

# Change this cron rule to what fits best for you
# By Default = At 10:00 UTC ~ 2am PST/PDT
ENV CRONTAB_TIME '0 10 * * *'

# Set here the URL to your custom manifest in order to use it for your custom builds
ENV CUSTOM_MANIFEST_URL ''

# Create Volume entry points
############################

VOLUME $SRC_DIR
VOLUME $CCACHE_DIR
VOLUME $OUT_DIR

# Copy required files and fix permissions
#####################

COPY src/* /root/
RUN chmod 0755 /root/*.sh

# Create missing directories
############################

RUN mkdir -p $SRC_DIR
RUN mkdir -p $CCACHE_DIR
RUN mkdir -p $OUT_DIR

# Set the work directory
########################

WORKDIR $SRC_DIR

# Fix permissions
#################

RUN chmod 0755 /root/build.sh
RUN chmod 0644 /etc/cron.d/crontab

# Get the repo CLI tool from Google
###################################

ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 0755 /usr/local/bin/repo

# Enable multilib support
#########################

RUN sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Replace conflicting packages
##############################

RUN yes | pacman -Sy --needed gcc-multilib

# Install AUR package manager
#############################

RUN pacman -U --noconfirm /root/apacman-3.1-1-any.pkg.tar.xz \
    && rm /root/apacman-3.1-1-any.pkg.tar.xz

# Install missing AUR packages
##############################

RUN apacman -S --noconfirm \
    ncurses5-compat-libs \
    lib32-ncurses5-compat-libs \
    jdk

# Install required Android AOSP packages
########################################

RUN pacman -Sy --needed --noconfirm \
      git \
      gnupg \
      flex \
      bison \
      gperf \
      sdl \
      wxgtk \
      squashfs-tools \
      curl \
      ncurses \
      zlib \
      schedtool \
      perl-switch \
      zip \
      unzip \
      libxslt \
      bc \
      lib32-zlib \
      lib32-ncurses \
      lib32-readline \
      rsync \
      maven \
      repo \
      imagemagick \
      ccache \
      libxml2 \
      cronie \
      ninja

# Create missing symlink to python2
###################################
RUN ln -s /usr/bin/python2 /usr/local/bin/python

# Cleanup
#########

RUN yes | pacman -Scc \
    && yes | pacman -Sc --cachedir=/var/cache/apacman/pkg

# Set the entry point to init.sh
###########################################

ENTRYPOINT /root/init.sh