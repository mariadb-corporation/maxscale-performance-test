#!/bin/bash
# This script bundles the performance test application as the AppImage.
# You should pass the build version as the parameter to the script.
# Resulting file will reside in build/out subdirectory
set -e

BUILD_VERSION=$1

if [ -z "$BUILD_VERSION" ]; then
  cat <<EOF
Please specify the release name as the first parameter to the script:
$0 VERSION
EOF
  exit 1
fi

CURRENT_DIR="$(pwd)"

BUILD_DIR="$(pwd)/build"
if [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"

# Copy all files that should be distributed to the build directory
PERFORMANCE_BUILD_DIR="$BUILD_DIR/performance-test"
mkdir -p $PERFORMANCE_BUILD_DIR
for file in bin chef-repository Gemfile Gemfile.lock lib templates tests
do
    cp -r "../$file" $PERFORMANCE_BUILD_DIR
done

# Copy all files required by ruby.appimage
for extension in desktop png sh
do
  cp performance_test."$extension" "$BUILD_DIR/"
done

# Copy the runner directory to the build
cp -r "runner" "$BUILD_DIR/"

# Start the build using ruby.appimage
pushd $BUILD_DIR
"$CURRENT_DIR/ruby.appimage/docker_build.sh" performance_test $BUILD_VERSION
popd
