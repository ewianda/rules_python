"""
Simple toolchain which overrides env and exec requirements.
"""

PytestProvider = provider(
    fields = [
        "get_runner",
    ],
)

def _get_runner(ctx, binary_info):
    executable = ctx.actions.declare_file("{}_cov".format(ctx.label.name))
    ctx.actions.write(
        output = executable,
        is_executable = True,
        content = """#!/bin/bash
/home/ewianda/projects/rules_python/examples/bzlmod/.venv/bin/coverage run %s
coverage_dir=$COVERAGE_DIR/pylcov.dat
/home/ewianda/projects/rules_python/examples/bzlmod/.venv/bin/coverage lcov -o $coverage_dir
        """ % binary_info.executable.short_path,
    )
    default_runfiles = ctx.runfiles(
        files = [executable],
    ).merge(binary_info.default_runfiles)
    return [
        DefaultInfo(
            files = depset(transitive = [binary_info.files, depset([executable])]),
            # Here is where we would return our own runner.
            executable = executable,
            default_runfiles = default_runfiles,
            data_runfiles = binary_info.data_runfiles,
        ),
    ]

def _my_cool_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        py_test_info = PytestProvider(
            get_runner = struct(
                func = _get_runner,
                args = {
                    "execution_requirements": ctx.attr.execution_requirements,
                    "test_environment": ctx.attr.test_environment,
                },
            ),
        ),
    )]

my_cool_toolchain = rule(
    implementation = _my_cool_toolchain_impl,
    attrs = {
        "execution_requirements": attr.string_dict(),
        "test_environment": attr.string_dict(),
    },
)
