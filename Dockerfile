# This Dockerfile supports the execution of the NVIDIA SDK Manager GUI. It is
# used for support of the NVIDIA Jetson Dev Kits.
#
# Last modified: 2024-11-05
#
FROM ubuntu:22.04

# Set environment variables to avoid user prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies
RUN apt-get update && \
    apt-get install -y \
    apt-utils \
    binfmt-support \
    bridge-utils \
    debconf-utils \
    dialog \
    dnsutils \
    gnupg2 \
    iproute2 \
    kmod \
    less \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    libgetopt-complete-perl \
    libusb-1.0-0 \
    libvirt-clients \
    libvirt-daemon-system \
    libx11-6 \
    libxext6 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    lsb-release \
    netcat \
    network-manager \
    openssh-client \
    policykit-1 \
    python3 \
    qemu-kvm \
    qemu-user-static \
    software-properties-common \
    software-properties-common \
    sudo \
    usbutils \
    wget \
    whois \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*
  

# Register QEMU support for ARM and AARCH64
RUN sudo update-binfmts --enable qemu-arm \
  && sudo update-binfmts --enable qemu-aarch64

# Add NVIDIA repository key
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.1-1_all.deb \
  && sudo dpkg -i cuda-keyring_1.1-1_all.deb

# Update repository list and install SDK Manager
RUN apt-get update && \
    apt-get install -y sdkmanager \
    && rm -rf /var/lib/apt/lists/*

# Create a user named 'nvidia' with sudo privileges
RUN useradd -m -s /bin/bash nvidia && echo "nvidia:nvidia" | chpasswd && adduser nvidia sudo

# Switch to the 'nvidia' user
USER nvidia
WORKDIR /home/nvidia

# Copy our startup script to the image to be used as the entrypoint
COPY --chmod=755 start.sh /start.sh
ENTRYPOINT ["/start.sh"]