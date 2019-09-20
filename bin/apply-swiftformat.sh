#!/bin/sh

if [[ "${CI}" ]]; then
    echo "CI environment detected. Skipping SwiftFormat."
    exit 0
fi

if which swiftformat >/dev/null; then
    swiftformat . --swiftversion $SWIFT_VERSION
else
    echo "WARNING: SwiftFormat is missing. Please install it manually and try again."
fi
