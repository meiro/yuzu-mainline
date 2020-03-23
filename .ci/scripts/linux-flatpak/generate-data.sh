#!/bin/bash -ex
# This script generates the appdata.xml and org.yuzu.$REPO_NAME.json files
# needed to define application metadata and build yuzu depending on what version
# of yuzu we're building (nightly or canary)

# Converts "yuzu-emu/yuzu-nightly" to "yuzu-nightly"
REPO_NAME=$(echo $AZURE_REPO_SLUG | cut -d'/' -f 2)
# Converts "yuzu-nightly" to "yuzu Nightly"
REPO_NAME_FRIENDLY=$(echo $REPO_NAME | sed -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g')

# Generate the correct appdata.xml for the version of yuzu we're building
cat > /tmp/appdata.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<application>
  <id type="desktop">org.yuzu.$REPO_NAME.desktop</id>
  <name>$REPO_NAME_FRIENDLY</name>
  <summary>Nintendo 3DS emulator</summary>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>GPL-2.0</project_license>
  <description>
    <p>TODO
    <p>
  </description>
  <url type="homepage">https://yuzu-emu.org/</url>
  <url type="donation">https://yuzu-emu.org/donate/</url>
  <url type="bugtracker">https://github.com/yuzu-emu/yuzu/issues</url>
  <url type="faq">https://yuzu-emu.org/wiki/faq/</url>
  <url type="help">https://yuzu-emu.org/wiki/home/</url>
  <screenshot>https://raw.githubusercontent.com/yuzu-emu/yuzu-web/master/site/static/images/screenshots/01-Super%20Mario%203D%20Land.jpg</screenshot>
  <screenshot>https://raw.githubusercontent.com/yuzu-emu/yuzu-web/master/site/static/images/screenshots/02-Mario%20Kart%207.jpg</screenshot>
  <screenshot>https://raw.githubusercontent.com/yuzu-emu/yuzu-web/master/site/static/images/screenshots/28-The%20Legend%20of%20Zelda%20Ocarina%20of%20Time%203D.jpg</screenshot>
  <screenshot>https://raw.githubusercontent.com/yuzu-emu/yuzu-web/master/site/static/images/screenshots/35-Pok%C3%A9mon%20ORAS.png</screenshot>
  <categories>
    <category>Games</category>
    <category>Emulator</category>
  </categories>
</application>
EOF

# Generate the yuzu flatpak manifest, appending certain variables depending on
# whether we're building nightly or canary.
cat > /tmp/org.yuzu.$REPO_NAME.json <<EOF
{
    "app-id": "org.yuzu.$REPO_NAME",
    "runtime": "org.kde.Platform",
    "runtime-version": "5.13",
    "sdk": "org.kde.Sdk",
    "command": "yuzu",
    "rename-desktop-file": "yuzu.desktop",
    "rename-icon": "yuzu",
    "rename-appdata-file": "org.yuzu.$REPO_NAME.appdata.xml",
    "build-options": {
        "build-args": [
            "--share=network"
        ],
        "env": {
            "CI": "$CI",
            "AZURE": "$AZURE",
            "CONTINUOUS_INTEGRATION": "$CONTINUOUS_INTEGRATION",
            "AZURE_BRANCH": "$AZURE_BRANCH",
            "AZURE_BUILD_ID": "$AZURE_BUILD_ID",
            "AZURE_BUILD_NUMBER": "$AZURE_BUILD_NUMBER",
            "AZURE_COMMIT": "$AZURE_COMMIT",
            "AZURE_JOB_ID": "$AZURE_JOB_ID",
            "AZURE_JOB_NUMBER": "$AZURE_JOB_NUMBER",
            "AZURE_REPO_SLUG": "$AZURE_REPO_SLUG",
            "AZURE_TAG": "$AZURE_TAG"
        }
    },
    "finish-args": [
        "--device=all",
        "--socket=x11",
        "--socket=pulseaudio",
        "--share=network",
        "--share=ipc",
        "--filesystem=xdg-config/yuzu-emu:create",
        "--filesystem=xdg-data/yuzu-emu:create",
        "--filesystem=host:ro"
    ],
    "modules": [
    {
        "name": "python2",
        "sources": [
            {
            "type": "archive",
            "url": "https://www.python.org/ftp/python/2.7.17/Python-2.7.17.tar.xz",
            "sha256": "4d43f033cdbd0aa7b7023c81b0e986fd11e653b5248dac9144d508f11812ba41"
            }
        ],
        "config-opts": [
            "--enable-shared",
            "--with-ensurepip=yes",
            "--with-system-expat",
            "--with-system-ffi",
            "--enable-loadable-sqlite-extensions",
            "--with-dbmliborder=gdbm",
            "--enable-unicode=ucs4"
        ],
        "post-install": [
        ],
        "cleanup": [
            "'*'"
        ]
    },
        {
            "name": "yuzu",
            "buildsystem": "cmake-ninja",
            "builddir": true,
            "config-opts": [
		"-DDISPLAY_VERSION=$1",
                "-DYUZU_USE_BUNDLED_UNICORN=ON",
		"-DYUZU_USE_QT_WEB_ENGINE=ON",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DYUZU_ENABLE_COMPATIBILITY_REPORTING=ON",
		"-DENABLE_COMPATIBILITY_LIST_DOWNLOAD=ON",	
                "-DUSE_DISCORD_PRESENCE=ON",
		"-DENABLE_VULKAN=No"
            ],
            "cleanup": [
              "/bin/yuzu-cmd",
              "/share/man",
              "/share/pixmaps"
            ],
            "post-install": [
                "install -Dm644 ../appdata.xml /app/share/appdata/org.yuzu.$REPO_NAME.appdata.xml",
                "desktop-file-install --dir=/app/share/applications ../dist/yuzu.desktop",
                "install -Dm644 ../dist/yuzu.svg /app/share/icons/hicolor/scalable/apps/yuzu.svg",
                "sed -i 's/Name=yuzu/Name=$REPO_NAME_FRIENDLY/g' /app/share/applications/yuzu.desktop",
                "mv /app/share/mime/packages/yuzu.xml /app/share/mime/packages/org.yuzu.$REPO_NAME.xml",
                "sed 's/yuzu/org.yuzu.yuzu-nightly/g' -i /app/share/mime/packages/org.yuzu.$REPO_NAME.xml"
            ],
            "sources": [
                {
                    "type": "git",
                    "url": "https://github.com/yuzu-emu/$REPO_NAME.git",
                    "branch": "$AZURE_BRANCH",
                    "disable-shallow-clone": true
                },
                {
                    "type": "file",
                    "path": "/tmp/appdata.xml"
                }
            ]
        }
    ]
}
EOF

