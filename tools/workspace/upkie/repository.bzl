# -*- python -*-
#
# SPDX-License-Identifier: Apache-2.0

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def upkie_repository(
        version = "5.1.0",
        sha256 = "016e684d1978ac0c6e8151de97b8def0f72b7b7284fd4b9553a5848298f242be"):
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
