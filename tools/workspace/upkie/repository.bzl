# -*- python -*-
#
# SPDX-License-Identifier: Apache-2.0

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def upkie_repository():
    """
    Clone repository from GitHub and make its targets available for binding.
    """
    git_repository(
        name = "upkie",
        remote = "https://github.com/upkie/upkie.git",
        commit = "29a81385afd121888868c25217fc9cb3f5b1a694",
        shallow_since = "1723644218 +0200",
    )
