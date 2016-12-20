#!/usr/bin/env bash
set -o errexit #abort if any command fails
jazzy
GIT_DEPLOY_DIR=docs GIT_DEPLOY_BRANCH=gh-pages GIT_DEPLOY_REPO=git@github.com:rnine/AMCoreAudio.git ./bin/deploy-docs.sh
