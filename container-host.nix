{
  hostvm = { config, pkgs, ...}:
  {
    deployment.targetEnv = "virtualbox";

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = "1";
      "net.ipv6.conf.all.forwarding" = "1";
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/5ycROJkSWCJRRf1MacRjvbw/N0FB++ML12QqhNbTE nixops_root_hostvm"
    ];
  };
}
