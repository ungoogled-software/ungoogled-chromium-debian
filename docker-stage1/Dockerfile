FROM debian:bullseye

RUN apt-get update --fix-missing && apt-get -y upgrade

ADD scripts /scripts

RUN /scripts/pre-build.sh

RUN apt-get install -y apt-utils && apt-get -y --no-install-recommends install git debhelper clang-11 lld-11 llvm-11-dev python python3 pkg-config ninja-build python-jinja2 ca-certificates gsettings-desktop-schemas-dev wget flex yasm xvfb wdiff gperf bison valgrind xz-utils x11-apps xfonts-base libglew-dev libgl1-mesa-dev libglu1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev mesa-common-dev libxt-dev libre2-dev libgbm-dev libpng-dev libxss-dev libelf-dev libvpx-dev libpci-dev libcap-dev libdrm-dev libicu-dev libffi-dev libkrb5-dev libexif-dev libflac-dev libudev-dev libopus-dev libwebp-dev libxtst-dev libjpeg-dev libxml2-dev libgtk-3-dev libxslt1-dev liblcms2-dev libpulse-dev libpam0g-dev libsnappy-dev libavutil-dev libavcodec-dev libavformat-dev libglib2.0-dev libasound2-dev libjsoncpp-dev libspeechd-dev libminizip-dev libhunspell-dev libusb-1.0-0-dev libopenjp2-7-dev libmodpbase64-dev libnss3-dev libnspr4-dev libcups2-dev libevent-dev libjs-jquery libjs-jquery-flot libgcrypt20-dev libva-dev fonts-ipafont-gothic fonts-ipafont-mincho uuid-dev nodejs xcb-proto python3-xcbgen python-setuptools libx11-xcb-dev libxcb-dri3-dev libxshmfence-dev && \
  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-11 800 && \
  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-11 800 && \
  update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-11 800 && \
  update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-11 800
