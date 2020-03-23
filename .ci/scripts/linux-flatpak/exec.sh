#!/bin/bash -ex
mkdir -p "$HOME/.ccache"

# Configure docker and call the script that generates application data and build scripts
docker run --env-file .ci/scripts/linux-flatpak/travis-ci.env --env-file .ci/scripts/linux-flatpak/travis-ci-flatpak.env -v $(pwd):/yuzu -v "$HOME/.ccache":/root/.ccache -v "$HOME/.ssh":/root/.ssh --privileged meirod/yuzu-test:latest /bin/bash -ex /yuzu/.ci/scripts/linux-flatpak/generate-data.sh

