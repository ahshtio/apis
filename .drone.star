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
        __ruby_client(),
        __js_client(),
        __java_client(),
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
            {
                "name": "publish",
                "image": "alpine/git",
                "commands": [
                    # Publish the SSH Key
                    "mkdir -p ~/.ssh && chmod 700 ~/.ssh",
                    "echo \"$ID_RSA\" > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa",
                    "ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts",

                    # Set Git configuration
                    "git remote set-url origin git@github.com:$DRONE_REPO",
                    "git config --global user.email apis@cloud.drone.io",

                    # Switch to the appropriate refspec
                    "git fetch --depth=1000",
                    "git checkout go",

                    # Arrange the content
                    "rm -rf v*",
                    "mv dist/pkg/go/github.com/ahshtio/apis/* .",
                    "git add v*",

                    # Push the changes"
                    "git commit -m 'Generated@$DRONE_COMMIT'",
                    "git push --force-with-lease",
                ],
                "environment": {
                    "ID_RSA": {
                        "from_secret": "ID_RSA"
                    }
                },
                "when": {
                    "branch": {
                        "include": [
                            "master"
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

def __ruby_client():
    """Generate and public the go client

    Returns:
      A valid pipeline object
    """
    return {
        "kind": "pipeline",
        "name": "ruby-client",
        "steps": [
            __step_proto("ruby", "v1alpha1/types", ["ruby_out"]),
            __step_proto("ruby", "v1alpha1/services", ["ruby_out"]),
            
            # Todo: Publish to GitHub Package Store
        ]
    }

def __js_client():
    """Generate and public the go client

    Returns:
      A valid pipeline object
    """
    return {
        "kind": "pipeline",
        "name": "js-client",
        "steps": [
            __step_proto("js", "v1alpha1/types", ["js_out"]),
            __step_proto("js", "v1alpha1/services", ["js_out"]),

            # Todo: Publish to GitHub Package Store
        ]
    }

def __java_client():
    """Generate and public the go client

    Returns:
      A valid pipeline object
    """
    return {
        "kind": "pipeline",
        "name": "java-client",
        "steps": [
            __step_proto("java", "v1alpha1/types", ["java_out"]),
            __step_proto("java", "v1alpha1/services", ["java_out"]),

            # Todo: Publish to GitHub Package Store
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