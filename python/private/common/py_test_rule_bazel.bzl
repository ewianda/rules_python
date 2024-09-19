# Copyright 2022 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Rule implementation of py_test for Bazel."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":attributes.bzl", "AGNOSTIC_TEST_ATTRS")
load(":common.bzl", "maybe_add_test_execution_info")
load("//python/private:py_executable_info.bzl", "PyExecutableInfo")
load(
    ":py_executable_bazel.bzl",
    "create_executable_rule",
    "py_executable_bazel_impl",
)

_BAZEL_PY_TEST_ATTRS = {
    # This *might* be a magic attribute to help C++ coverage work. There's no
    # docs about this; see TestActionBuilder.java
    "_collect_cc_coverage": attr.label(
        default = "@bazel_tools//tools/test:collect_cc_coverage",
        executable = True,
        cfg = "exec",
    ),
    # This *might* be a magic attribute to help C++ coverage work. There's no
    # docs about this; see TestActionBuilder.java
    "_lcov_merger": attr.label(
        default = configuration_field(fragment = "coverage", name = "output_generator"),
        cfg = "exec",
        executable = True,
    ),
}
_PY_TEST_TOOLCHAIN_TYPE = "@rules_python//python:test_runner_toolchain_type"

def _py_test_impl(ctx):
    binary_info, providers = py_executable_bazel_impl(
        ctx = ctx,
        is_test = True,
        inherited_environment = ctx.attr.env_inherit,
    )
    maybe_add_test_execution_info(providers, ctx)
    py_test_toolchain = ctx.exec_groups["test"].toolchains[_PY_TEST_TOOLCHAIN_TYPE]
    if not py_test_toolchain:
        return providers
    _ = providers.pop(0)
    test_providers = py_test_toolchain.py_test_info.get_runner.func(ctx, binary_info)
    providers.extend(test_providers)
    return providers

py_test = create_executable_rule(
    implementation = _py_test_impl,
    attrs = dicts.add(AGNOSTIC_TEST_ATTRS, _BAZEL_PY_TEST_ATTRS),
    test = True,
    exec_groups = {
        "test": exec_group(toolchains = [config_common.toolchain_type(_PY_TEST_TOOLCHAIN_TYPE, mandatory = False)]),
    },
)
