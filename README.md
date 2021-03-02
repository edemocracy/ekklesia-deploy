# Ekklesia Deploy

**WIP**

This will make deploying an Ekklesia installation quite easy using NixOS and NixOps.
There's some config for an Ekklesia Portal and 2 VVVote instances in `ekklesia.nix`.
`ekklesia-virtualbox.nix` specifies a virtualbox network with 3 VMs.

The Nix shell sets up an ready-to-use deployment environment with nixops and
the VVVote admin script which can be used to create the needed keys.

Deploy to virtualbox with:

~~~
nix-shell
nixops create -d ekklesia-vbox ./ekklesia.nix ./ekklesia-virtualbox.nix
nixops deploy -d ekklesia-vbox
~~~

The VVVote admin tool can be used like this:

~~~
vvvote-admin.sh createKeypair p 1 /tmp/vvvote/
~~~

`/tmp/vvvote` must have a subdir called `voting-keys` which is expected by the script.
