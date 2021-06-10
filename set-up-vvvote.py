import sys
from getpass import getpass
from pathlib import Path
from pprint import pprint
import subprocess
import json


KEEP_KEYS = True


def run(cmd):
    return subprocess.run(cmd, capture_output=True, check=True, shell=True)


def ret(cmd):
    return subprocess.run(cmd, capture_output=True, shell=True).returncode


def sh(cmd):
    print(cmd)
    run(cmd)


def secret(cmd_template, **secrets):
    print(cmd_template)
    run(cmd_template.format(**secrets))


def get_ekklesia_settings(vm_name):
    settings = json.loads(
        run(f"nixops show-option -d ekklesia-vbox {vm_name} services.ekklesia --json").stdout)

    #pprint(settings)
    return settings


def create_and_fetch_keys(server_number):
    vm_name = f"vvvote{server_number}"
    settings = get_ekklesia_settings(vm_name)
    keydir = Path(settings["vvvote"]["privateKeydir"])

    ssh = f"nixops ssh -d ekklesia-vbox {vm_name}"
    fetch = f"nixops scp -d ekklesia-vbox --from {vm_name}"

    if not KEEP_KEYS or ret(f"{ssh} stat {keydir.parent}/.dont_overwrite_keys") > 0:
        sh(f"{ssh} mkdir -p {keydir.parent}/voting-keys")
        sh(f"{ssh} mkdir -p {keydir}")
        sh(f"{ssh} vvvote-admin.sh createKeypair p {server_number} {keydir.parent}")
        sh(f"{ssh} vvvote-admin.sh createKeypair t {server_number} {keydir.parent}")
        sh(f"{ssh} mv {keydir.parent}/voting-keys/\*private\* {keydir}")
        sh(f"{ssh} touch /var/lib/vvvote/.dont_overwrite_keys")
    else:
        print(f"Keys are already set up for {vm_name}, refusing to create private keys. "
        + f"Remove {keydir.parent}/.dont_overwrite_keys to force key creation.")

    sh(f"{fetch} {keydir.parent}/voting-keys/\*public\* vvvote-public-keys/")


def push_public_keys(server_number):
    vm_name = f"vvvote{server_number}"
    settings = get_ekklesia_settings(vm_name)
    keydir = Path(settings["vvvote"]["settings"]["publicKeydir"])

    ssh = f"nixops ssh -d ekklesia-vbox {vm_name}"
    push = f"nixops scp -d ekklesia-vbox --to {vm_name}"

    sh(f"{ssh} mkdir -p {keydir}")
    keys = Path("vvvote-public-keys").glob("*.publickey.pem")
    for key in keys:
        sh(f"{push} {str(key)} {keydir}")


def set_up_secrets(server_number):
    vm_name = f"vvvote{server_number}"
    settings = get_ekklesia_settings(vm_name)
    oauth_path = settings["vvvote"]["oauthClientSecretFile"]
    notify_path = settings["vvvote"]["notifyClientSecretFile"]

    ssh = f"nixops ssh -d ekklesia-vbox {vm_name}"
    oauth_client_secret = getpass(f"oauth client secret for {vm_name} (Enter means no change):")
    notify_secret = getpass(f"notify client secret for {vm_name} (Enter means no change):")

    if oauth_client_secret:
        secret(f"{ssh} 'echo {{oauth_client_secret}} > {oauth_path}'", oauth_client_secret=oauth_client_secret)

    if notify_secret:
        secret(f"{ssh} 'echo {{notify_secret}} > {notify_path}'", notify_secret=notify_secret)


sh("mkdir -p vvvote-public-keys")


create_and_fetch_keys(1)
create_and_fetch_keys(2)
push_public_keys(1)
push_public_keys(2)
set_up_secrets(1)
set_up_secrets(2)
