#!/usr/bin/env bash

# Usage: sign.sh 'My App Image.app'
# with environment variables:
# cert_base64: base64-encoded signing certificate
# cert_name: full name of signing certificate
# cert_pass: signing certificate password

mydir="$(dirname "$0")"
app_path="$1"

gotall=true
for var in app_path cert_base64 cert_name cert_pass
do
    if [[ -z "${!var}" ]]
    then
        echo "Missing required parameter $var" >&2
        gotall=false
    fi
done
$gotall || exit 1

set -x -e
# ****************************************************************************
#   setup keychain
# ****************************************************************************
# The following is derived from
# https://federicoterzi.com/blog/automatic-code-signing-and-notarization-for-macos-apps-using-github-actions/
# shellcheck disable=SC2154
base64 --decode > certificate.p12 <<< "$cert_base64"

# We need to create a new keychain, otherwise using the certificate will prompt
# with a UI dialog asking for the certificate password, which we can't
# use in a headless CI environment
# Create a local keychain password
set +x
keychain_pass="$(dd bs=8 count=1 if=/dev/urandom 2>/dev/null | base64)"
echo "::add-mask::$keychain_pass"
set -x
sleep 1
security create-keychain -p "$keychain_pass" viewer.keychain
security set-keychain-settings -lut 21600 viewer.keychain
security default-keychain -s viewer.keychain
security unlock-keychain -p "$keychain_pass" viewer.keychain
# shellcheck disable=SC2154
security import certificate.p12 -k viewer.keychain -P "$cert_pass" -T /usr/bin/codesign
security set-key-partition-list -S 'apple-tool:,apple:,codesign:' -s -k "$keychain_pass" viewer.keychain
rm certificate.p12

# We sign from the inside out

# Plugin bundle
plugin_path="$app_path/Contents/Resources/SLPlugin.app"
plugin_contents="$plugin_path/Contents"

# VLC plugin
for signee in \
    "$plugin_contents"/Frameworks/libvlccore.dylib \
    "$plugin_contents"/Frameworks/libvlccore.9.dylib \
    "$plugin_contents"/Frameworks/libvlc.dylib \
    "$plugin_contents"/Frameworks/libvlc.5.dylib \
    "$plugin_contents"/Frameworks/plugins/*.dylib \
    "$plugin_contents"/Frameworks/plugins/*.dat \
    "$plugin_contents"/Frameworks/media_plugin_libvlc.dylib
do
    # shellcheck disable=SC2154
    codesign --verbose --force --timestamp --keychain viewer.keychain \
             --sign "$cert_name" "$signee"
done

# CEF plugin
for signee in \
    "$plugin_contents/Frameworks/Chromium Embedded Framework.framework/Libraries"/*.dylib \
    "$plugin_contents/Frameworks/Chromium Embedded Framework.framework/Resources"/*.bin \
    "$plugin_contents/Frameworks/Chromium Embedded Framework.framework" \
    "$plugin_contents"/Frameworks/media_plugin_cef.dylib
do
    codesign --verbose --force --timestamp --keychain viewer.keychain \
             --sign "$cert_name" "$signee"
done

# DullahanHelper and SLPlugin
for signee in \
    "$plugin_contents/Frameworks"/DullahanHelper*.app \
    "$plugin_path"
do
    codesign --verbose --force --timestamp \
             --entitlements "$mydir/installer/slplugin.entitlements" \
             --options runtime --keychain viewer.keychain \
             --sign "$cert_name" "$signee"
done

# Resources
resources="$app_path/Contents/Resources"

# SLVoice Libs
for signee in \
    "$resources"/libortp.dylib \
    "$resources"/libvivoxsdk.dylib
do
    codesign --verbose --force --timestamp --keychain viewer.keychain \
             --sign "$cert_name" "$signee"
done

# SLVoice binary
# shellcheck disable=SC2066
for signee in \
    "$resources/SLVoice"
do
    codesign --verbose --force --timestamp \
             --entitlements "$mydir/installer/slplugin.entitlements" \
             --options runtime --keychain viewer.keychain \
             --sign "$cert_name" "$signee"
done

# App Frameworks
frameworks="$app_path/Contents/Frameworks"
for signee in \
    "$frameworks"/libopenal.dylib \
    "$frameworks"/libalut.dylib \
    "$frameworks"/libfmod.dylib \
    "$frameworks"/libdiscord_partner_sdk.dylib \
    "$frameworks"/libndofdev.dylib \
    "$frameworks"/libSDL3.dylib \
    "$frameworks"/libllwebrtc.dylib
do
    codesign --verbose --force --timestamp --keychain viewer.keychain \
             --sign "$cert_name" "$signee"
done

# App Signing
# shellcheck disable=SC2066
for signee in \
    "$app_path"
do
    codesign --verbose --force --timestamp \
             --entitlements "$mydir/installer/slplugin.entitlements" \
             --options runtime --keychain viewer.keychain \
             --sign "$cert_name" "$signee"
done