#!/bin/bash -ex

# Converts "yuzu-emu/yuzu-nightly" to "yuzu-nightly"
REPO_NAME=$(echo $TRAVIS_REPO_SLUG | cut -d'/' -f 2)
CITRA_SRC_DIR="/yuzu"
BUILD_DIR="$CITRA_SRC_DIR/build"
REPO_DIR_REMOTE="$CITRA_SRC_DIR/repo"
REPO_DIR="/tmp/repo"
STATE_DIR="$CITRA_SRC_DIR/.flatpak-builder"
KEYS_ARCHIVE="/tmp/keys.tar"
SSH_DIR="/upload"
SSH_KEY="/tmp/ssh.key"
GPG_KEY="/tmp/gpg.key"

# Extract keys
openssl aes-256-cbc -K $FLATPAK_ENC_K -iv $FLATPAK_ENC_IV -in "$CITRA_SRC_DIR/keys.tar.enc" -out "$KEYS_ARCHIVE" -d
tar -C /tmp -xvf $KEYS_ARCHIVE


# Configure SSH keys
eval "$(ssh-agent -s)"
chmod -R 600 "$HOME/.ssh"
chown -R root "$HOME/.ssh"
chmod 600 "$SSH_KEY"
ssh-add "$SSH_KEY"
echo "[$FLATPAK_SSH_HOSTNAME]:$FLATPAK_SSH_PORT,[$(dig +short $FLATPAK_SSH_HOSTNAME)]:$FLATPAK_SSH_PORT $FLATPAK_SSH_PUBLIC_KEY" > ~/.ssh/known_hosts

# Configure GPG keys
gpg2 --import "$GPG_KEY"

# Mount our flatpak repository
mkdir -p "$REPO_DIR"
mkdir -p "$REPO_DIR_REMOTE"
sshfs "$FLATPAK_SSH_USER@$FLATPAK_SSH_HOSTNAME:$SSH_DIR_REMOTE" "$REPO_DIR_REMOTE" -C -p "$FLATPAK_SSH_PORT" -o IdentityFile="$SSH_KEY" -o "StrictHostKeyChecking=no" -o ServerAliveInterval=60

# DEBUGGING STUFF:
ls -la $REPO_DIR_REMOTE
touch $REPO_DIR_REMOTE/TEST
echo "TESTING" >> $REPO_DIR_REMOTE/TEST2
echo "TESTING2" >> $REPO_DIR_REMOTE/TEST
rm $REPO_DIR_REMOTE/TEST2
rm $REPO_DIR_REMOTE/TEST

# setup ccache location
mkdir -p "$STATE_DIR"
ln -sv --force /root/.ccache "$STATE_DIR/ccache"

# Build the yuzu flatpak
flatpak-builder -v --jobs=4 --ccache --force-clean --state-dir="$STATE_DIR" --gpg-sign="$FLATPAK_GPG_PUBLIC_KEY" --repo="$REPO_DIR" "$BUILD_DIR" "/tmp/org.yuzu.$REPO_NAME.json"
flatpak build-update-repo "$REPO_DIR" -v --generate-static-deltas --gpg-sign="$FLATPAK_GPG_PUBLIC_KEY"

cp -r $REPO_DIR/* $REPO_DIR/.* $REPO_DIR_REMOTE/

