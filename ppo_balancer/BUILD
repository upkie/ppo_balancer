# -*- python -*-
#
# SPDX-License-Identifier: Apache-2.0

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "config",
    srcs = glob(["*.gin"]),
)

py_library(
    name = "common",
    srcs = [
        "envs.py",
        "settings.py",
    ],
    data = [
        ":config",
    ],
    deps = [
        "@upkie//upkie/envs",
        "@upkie//upkie/envs/wrappers",
    ],
)

py_binary(
    name = "run",
    srcs = ["run.py"],
    main = "run.py",

    # Enable `from X import y` rather than `from agents.agent_name.X import y`
    # so that the agent can be run indifferently via Python or Bazel.
    imports = ["."],

    data = [
        "policy/operative_config.gin",
        "policy/params.zip",
    ],
    deps = [
        "@upkie//upkie/envs",
        "@upkie//upkie/utils:filters",
        "@upkie//upkie/utils:raspi",
        "@upkie//upkie/utils:robot_state",
        ":common",
    ],
)

py_binary(
    name = "train",
    srcs = ["train.py"],
    main = "train.py",

    # Enable `from X import y` rather than `from agents.agent_name.X import y`
    # so that the agent can be run indifferently via Python or Bazel.
    imports = ["."],

    data = [
        "@upkie//spines:bullet_spine",
    ],
    deps = [
        ":common",
        "@rules_python//python/runfiles",
        "@upkie//upkie/envs",
        "@upkie//upkie/utils:robot_state",
        "@upkie//upkie/utils:spdlog",
    ],
)
