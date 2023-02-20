FROM rashoru/vnc-desktop:jammy-20230220

LABEL maintainer "rashoru-infinity <65536toaru@gmail.com>"
ENV USERNAME=ubuntu
ENV GROUPNAME=ubuntu
ENV PASSWORD=ubuntu

# setup locale
RUN apt-get update \
    && apt-get install -y --no-install-recommends locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && export LANG=en_US.UTF-8 \
    && locale \
    && rm -rf /var/lib/apt/lists/* \
    /var/cache/apt/archives/*

# setup user
RUN apt-get update \
    && apt-get install -y --no-install-recommends sudo \
    gosu \
    && groupadd $GROUPNAME \
    && useradd -m -s /bin/bash -g $GROUPNAME -G sudo,vglusers $USERNAME \
    && echo $USERNAME:$PASSWORD | chpasswd \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL'  >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/* \
    /var/cache/apt/archives/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository universe \
    && apt-get update \
    && apt-get install -y --no-install-recommends curl \
    bzip2 \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | \
    tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && rm -rf /var/lib/apt/lists/* \
    /var/cache/apt/archives/*

USER $USERNAME
RUN mkdir -p $HOME/ros2_humble \
    && cd $HOME/ros2_humble \
    && curl -OL https://github.com/ros2/ros2/releases/download/release-humble-20230213/ros2-humble-20230127-linux-jammy-amd64.tar.bz2 \
    && tar xf ./ros2-humble-20230127-linux-jammy-amd64.tar.bz2 \
    && rm ./ros2-humble-20230127-linux-jammy-amd64.tar.bz2

WORKDIR /home/$USERNAME/ros2_humble
USER root
ENV ROS_DISTRO=humble
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3-rosdep \
    ros-dev-tools \
    && rosdep init \
    && gosu $USERNAME rosdep update \
    && gosu $USERNAME rosdep install --from-paths /home/$USERNAME/ros2_humble/ros2-linux/share --ignore-src -y --skip-keys "cyclonedds fastcdr fastrtps rti-connext-dds-6.0.1 urdfdom_headers" \
    && rm -rf /var/lib/apt/lists/* \
    /var/cache/apt/archives/* \
    /home/$USERNAME/.ros/rosdep/sources.cache/*
WORKDIR /