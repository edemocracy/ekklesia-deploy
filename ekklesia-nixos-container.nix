{
  portal =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "container";
      # Run container somewhere elsa (SSH)
      # deployment.container.host = "hostname";
    };

  vvvote1 =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "container";
    };

  vvvote2 =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "container";
    };
}
