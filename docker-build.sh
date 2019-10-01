set -ex

git submodule update --init --recursive

mkdir -p build

# Build first stage docker
pushd docker-stage1
docker build --rm -f "Dockerfile" -t ug-chromium-builder-stage1:latest ./
popd

# Build second stage docker
docker build --rm -f "Dockerfile-stage2" -t ug-chromium-builder-stage2:latest ./

# start the browser build
docker run -ti -v `pwd`/build:/repo/build ug-chromium-builder-stage2:latest ./build-n-pack.sh
