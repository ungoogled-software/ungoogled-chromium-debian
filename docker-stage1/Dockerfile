FROM debian:bullseye

RUN apt-get update --fix-missing && apt-get -y upgrade

ADD scripts /scripts

RUN /scripts/pre-build.sh

RUN apt-get install -y apt-utils
RUN apt-get -y --no-install-recommends install git debhelper python python3 pkg-config ninja-build python-jinja2 ca-certificates gsettings-desktop-schemas-dev wget flex yasm xvfb wdiff gperf bison valgrind xz-utils x11-apps xfonts-base libglew-dev libgl1-mesa-dev libglu1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev mesa-common-dev libxt-dev libre2-dev libgbm-dev libpng-dev libxss-dev libelf-dev libvpx-dev libpci-dev libcap-dev libdrm-dev libicu-dev libffi-dev libkrb5-dev libexif-dev libflac-dev libudev-dev libopus-dev libwebp-dev libxtst-dev libjpeg-dev libxml2-dev libgtk-3-dev libxslt1-dev liblcms2-dev libpulse-dev libpam0g-dev libsnappy-dev libavutil-dev libavcodec-dev libavformat-dev libglib2.0-dev libasound2-dev libjsoncpp-dev libspeechd-dev libminizip-dev libhunspell-dev libusb-1.0-0-dev libopenjp2-7-dev libmodpbase64-dev libnss3-dev libnspr4-dev libcups2-dev libevent-dev libjs-jquery libjs-jquery-flot libgcrypt20-dev libva-dev fonts-ipafont-gothic fonts-ipafont-mincho uuid-dev nodejs uglifyjs.terser node-typescript xcb-proto python3-xcbgen python-setuptools libx11-xcb-dev libxcb-dri3-dev libxshmfence-dev imagemagick desktop-file-utils binutils libcurl4-openssl-dev lsb-release wget software-properties-common gnupg2

WORKDIR /root

RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
RUN add-apt-repository "deb http://apt.llvm.org/bullseye llvm-toolchain-bullseye-15 main"
RUN apt-get update

RUN apt-get install -y libllvm-15-ocaml-dev libllvm15 llvm-15 llvm-15-dev llvm-15-doc llvm-15-examples llvm-15-runtime clang-15 clang-tools-15 clang-15-doc libclang-common-15-dev libclang-15-dev libclang1-15 clang-format-15 clangd-15 libfuzzer-15-dev lldb-15 lld-15 libc++-15-dev libc++abi-15-dev libomp-15-dev libclc-15-dev libunwind-15-dev

RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-15 800
RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-15 800
RUN update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-15 800
RUN update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-15 800

RUN mkdir /repo
WORKDIR /repo

