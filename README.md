# Ekklesia Deploy

This will make deploying an Ekklesia installation quite easy using NixOS and NixOps.
## Status

**Still WIP, VirtualBox should work for Portal and VVVote**


## Quick Start (VirtualBox)

There's a working example config for an Ekklesia Portal and two VVVote instances
in `ekklesia.nix`. `ekklesia-virtualbox.nix` specifies a virtualbox network with
 3 VMs meant for testing.

The Nix shell sets up an ready-to-use deployment environment with NixOps and
the VVVote admin script which can be used to create the needed keys.

Deploy to virtualbox with:

~~~
nix-shell
# in Nix shell
nixops create -d ekklesia-vbox ./ekklesia.nix ./ekklesia-virtualbox.nix
nixops deploy -d ekklesia-vbox
~~~

Deploying the first time like that will fail because VVVote cannot find private
keys files. They need to be created in a second step, followed by a redeploy:

~~~
# in Nix shell
python3 set-up-vvvote.py
nixops deploy -d ekklesia-vbox
~~~

## VVVote Administration Notes

### Key Management

Generating and distributing keys must be done separately from the NixOps deployment.

It can be done on the deployment machine for all VVVote instances which is easy
but you may not want the private keys to be moved around so you can also create
them on the VM itself after the first deploy run. There's a script for the second
case which uses SSH via NixOps to remotely create keys on the VMs, fetch public
keys to the deployment machine and create additional secrets needed for VVVote.

Please read the [VVVote Installation Instructions](https://github.com/vvvote/vvvote/blob/master/doc/install.md#generate-and-distribute-server-keys)
first.

### Setup Script

This does everything needed to run VVVote. Keys are created if they do not exist.
Existing private keys will not be replaced automatically for safety reasons.
The script asks for an OAuth2 client secret and an Ekklesia Notify secret for both
VMs.

~~~
# in Nix shell
python3 set-up-vvvote.py
~~~

### VVVote Admin

The VVVote admin tool can be used directly like this:

~~~
vvvote-admin.sh createKeypair p 1 /tmp/vvvote/
~~~

The `vvvote-admin.sh` command works the same in the Nix shell and the on the deployed VVVote VMs.

`/tmp/vvvote` must have a subdir called `voting-keys` which is expected by the script.

~~~
