#!/bin/bash

# *******************************************************************************
# Copyright 2025 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************

# Define patch cache directory as global variable, set to be in this directory,
# shared by this Tool-Solutions. Collisions are almost impossible, even between
# projects
patch_cache_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")/patch_cache"
mkdir -p $patch_cache_dir
export patch_cache_dir

function git-shallow-clone {
    (
        local repo_name=$(basename "$1" .git)
        if ! cd "$repo_name" ; then
            echo "$repo_name doesn't exist, so we are making"
            mkdir "$repo_name"
            cd "$repo_name"
            git init
            git remote add origin $1
        fi
        git fetch --depth=1 --recurse-submodules=no origin $2
        # We do a force checkout + clean to overwrite previous patches
        git checkout -f FETCH_HEAD
        git clean -fd
    )
}

function apply-github-patch {
    # Apply a specific GitHub commit.
    # $1 is 'organisation/repo', $2 is the commit hash
    # To use an API token, which may avoid rate limits, set the environment variable GITHUB_TOKEN

    set -u
    patch_file="$patch_cache_dir/$2.patch"
    if [ ! -f "$patch_file" ]; then
        local github_api_url='https://api.github.com/repos'
        local github_url='https://github.com'

        # Download the .patch file.
        if [[ "${GITHUB_TOKEN+x}" ]]; then
            curl --silent -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3.patch" -L $github_api_url/$1/commits/$2 -o "$patch_file"
        else
            curl --silent -L $github_url/$1/commit/$2.patch -o "$patch_file"
        fi
    fi

    # Apply the patch
    patch -p1 < "$patch_file"
    return 0
}

function apply-gerrit-patch {
    # $1 must be the url to a specific patch set
    # We get the repo by removing /c and chopping off the change number
    # e.g. https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1 -> https://review.mlplatform.org/ml/ComputeLibrary/
    local repo_url=$(echo "$1" | sed 's#/c/#/#' | cut -d'+' -f1)
    # e.g. refs/changes/18/12818/1 Note that where the middle number is the last 2 digits of the patch number
    local refname=$(echo "$1" | awk -F'/' '{print "refs/changes/" substr($(NF-1),length($(NF-1))-1,2) "/" $(NF-1) "/" $(NF)}')
    git fetch $repo_url $refname && git cherry-pick --no-commit FETCH_HEAD
}

function setup_submodule() {
    local original_dir=$(pwd)
    rm -rf "$2"
    git clone $1 $2
    cd $2
    git checkout $3
    cd $original_dir
}

function reset_submodule() {
    if [ -d "$1" ]; then
        rm -rf "$1"
    fi
}
