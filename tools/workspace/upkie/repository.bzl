# -*- python -*-
#
# SPDX-License-Identifier: Apache-2.0

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def upkie_http_repository(
        version = "8.0.0",
        sha256 = "36f0e31ddb76325a08e94816d5b410d50ee4e874b023f30cf7fcf43ed831400a"):
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

def upkie_repository():
    git_repository(
        name = "upkie",
        remote = "https://github.com/upkie/upkie",
        commit = "15f07c47b4abd8683bf68dcdec3c38cdcf4bc4a4",
        shallow_since = "1748874814 +0200",
    )
