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
        __go_client()
    ]

def __go_client():
    return {
    "kind": "pipeline",
    "name": "build",
    "steps": [
      {
        "name": "build",
        "image": "alpine",
        "commands": [
            "echo hello world"
        ]
      }
    ]
  }