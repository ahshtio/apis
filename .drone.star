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
            __step_proto("go", "incident/v1alpha3", ["go_out", "go-grpc_out"]),
            {
                "name": "publish",
                "image": "alpine/git",
                "commands": [
                    # Publish the SSH Key
                    "mkdir -p ~/.ssh && chmod 700 ~/.ssh",
                    "echo \"$ID_RSA\" > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa",
                    "ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts",

                    # Set Git configuration
                    "git config --global user.email apis@cloud.drone.io",

                    # Clone the client repo
                    "git clone git@github.com:ahshtio/apis-go.git",

                    # Arrange the content
                    "find apis-go/* -maxdepth 0 -print0 | xargs -0 rm -rfv",
                    "mv dist/pkg/go/github.com/ahshtio/apis/* apis-go",
                    "cd apis-go",
                    "git add *",

                    # Push the changes"
                    """
cat <<EOF | git commit --file -
Generated@$DRONE_COMMIT

This commit is automatically generated as a consequence of upstream 
library updates in APIs repository:

  https://github.com/ahshtio/apis

See:

  https://github.com/ahshtio/apis/commit/$DRONE_COMMIT

For details.
EOF
                    """
                    , 
                    "git push"
                ],
                "environment": {
                    "ID_RSA": {
                        "from_secret": "ID_RSA"
                    }
                },
                "when": {
                    "branch": {
                        "include": [
                            "specification"
                        ]
                    },
                    "event": {
                        "include": [
                            "push"
                        ]
                    }
                }
            }
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