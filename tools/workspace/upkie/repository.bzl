# -*- python -*-
#
# SPDX-License-Identifier: Apache-2.0

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def upkie_repository(
        version = "5.2.0",
        sha256 = "6a61a357f1a90d795d9327f58c2ce7b34239bf9ac242568dad06182f90783c2b"):
    """
    Download release archive from GitHub.

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
