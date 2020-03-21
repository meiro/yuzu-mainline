#!/bin/bash -ex
mkdir -p "$HOME/.ccache"
echo $FLATPAK_ENC_K
# Configure docker and call the script that generates application data and build scripts
docker run --env-file .travis/common/travis-ci.env --env-file .travis/linux-flatpak/travis-ci-flatpak.env -v $(pwd):/yuzu -v "$HOME/.ccache":/root/.ccache -v "$HOME/.ssh":/root/.ssh --privileged meirod/yuzu-test:latest /bin/bash -ex /yuzu/.travis/linux-flatpak/generate-data.sh
