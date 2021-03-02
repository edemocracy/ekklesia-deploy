{
  portal =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024;
      deployment.virtualbox.vcpu = 1;
    };

  vvvote1 =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024;
      deployment.virtualbox.vcpu = 1;
    };

  vvvote2 =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024;
      deployment.virtualbox.vcpu = 1;
    };
}
