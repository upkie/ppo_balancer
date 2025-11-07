# -*- python -*-
#
# SPDX-License-Identifier: Apache-2.0

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def upkie_repository(
        version = "8.1.1",
        sha256 = "a4e937aff631321628ff519650548bccf5c3453d7e7fc109bbd56c30a5f48c8e"):
    """Download release archive from GitHub.

    Args:
        version: Version of the library to download.
        sha256: SHA-256 checksum of the downloaded archive.
    """
    http_archive(
        name = "upkie",
        urls = [
            "https://github.com/upkie/upkie/archive/refs/tags/v{}.tar.gz".format(version),
        ],
        sha256 = sha256,
        strip_prefix = "upkie-{}".format(version),
    )

# You can replace the definition above by the following one to customize code
# in the upkie repository:
#
# def upkie_repository():
#     git_repository(
#         name = "upkie",
#         remote = "https://github.com/YOUR_USER/upkie",
#         commit = "YOUR_COMMIT_ID",
#         shallow_since = "DATE_BAZEL_WILL_GIVE_YOU_IN_A_WARNING",
#     )
