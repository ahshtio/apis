"""
This file is the bazel definition for the CI pipeline.

The file is to be consumed with the Drone CLI tool:

  $ drone starlark

To generate the required yaml. Alternatively if the plugin is installed, it can be consumed directly via the drone
server.
"""

def main(ctx):
    """The entrypoint to generate pipelines. To generate the yaml definitions.

    Args:
      ctx: Unknown

    Returns:
      An array of build steps for use rendering into Yaml
    """
    return [
        __go_client(),
    ]

def __go_client():
    """Generate and public the go client

    Returns:
      A valid pipeline object
    """
    return {
        "kind": "pipeline",
        "name": "go-client",
        "steps": [
            __step_proto("go", "v1alpha1/types", ["go_out", "go-grpc_out"]),
            __step_proto("go", "v1alpha1/services", ["go_out", "go-grpc_out"]),

            # Todo: Publish to GitHub branch
        ]
    }

def __step_proto(name, src, plugins):
    """Runs the generation of the client libraries from a protobuf definition

    Returns:
      A valid step object
    """

    # Compile the destination
    dest = "dist/pkg/%s" % name

    # Compile the protobuf invocation command
    command = "protoc -I/usr/local/include -I."
    for p in plugins:
        command += " --%s=%s" % (p, dest)

    command += " %s/*" % src

    # Compile the step
    return  {
        "name": "%s: %s" % (name, src),
        "image": "littleman/proto:latest",
        "commands": [
            "mkdir -p %s" % dest,
            command
        ]
    }