#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2025, 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Define patch cache directory as global variable, set to be in this directory,
# shared by this Tool-Solutions. Collisions are almost impossible, even between
# projects
patch_cache_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")/patch_cache"
mkdir -p "$patch_cache_dir"
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

    local github_url='https://github.com'
    local github_api_url='https://api.github.com/repos'

    local patch_file="$patch_cache_dir/$2.patch"

    if [ ! -f "$patch_file" ]; then
        # Download the .patch file.
        if [[ "${GITHUB_TOKEN+x}" ]]; then
            curl --silent \
                -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3.patch" \
                -L $github_api_url/$1/commits/$2 -o "$patch_file"
        else
            curl --silent -L $github_url/$1/commit/$2.patch -o "$patch_file"
        fi
    fi

    _git_with_credentials() {
        git -c user.name="apply-github-patch" -c user.email="noreply@example.com" "$@"
    }

    # Approach #1: Try a simple patch application with 'git am'
    _git_with_credentials am --keep-cr "$patch_file" && return 0
    _git_with_credentials am --abort || true # wokeignore:rule=abort/terminate

    # Approach #2: Try a three-way merge after fetching the parent commit. It can handle
    # scenarios in which the context of the patch has moved. However, we need the parent
    # commit of the patch for this so we'll try to fetch it with the '--depth=2'
    local fetch_url="${github_url}/$1.git"
    if [[ "${GITHUB_TOKEN+x}" ]]; then
        fetch_url="https://x-access-token:${GITHUB_TOKEN}@github.com/$1.git"
    fi
    git fetch --no-tags --quiet --depth=2 "$fetch_url" "$2" || true
    _git_with_credentials am --3way --keep-cr "$patch_file" && return 0
    _git_with_credentials am --abort || true # wokeignore:rule=abort/terminate

    # Approach #3: Fall back to GNU 'patch'
    patch -p1 < "$patch_file" || return 1
    git add -A
    _git_with_credentials commit -m "Applied patch $2 from $1."
    return 0
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
