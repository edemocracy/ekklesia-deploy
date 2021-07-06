{
  portal =
    { config, pkgs, ...}:
    {
      # NixOps always uses SSH to set up containers,
      # even if it's deploying on the local host.
      deployment.targetEnv = "container";
      # Run container somewhere else.
      # deployment.container.host = "hostvm";
    };

  vvvote1 =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "container";
      #deployment.container.host = "hostvm";
    };

  vvvote2 =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "container";
      #deployment.container.host = "hostvm";
    };
}
