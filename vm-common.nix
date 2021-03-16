{ config, pkgs, lib, ... }:
{
  options = with lib; {
    settings = mkOption {
      type = types.attrs;
      default = {};
    };
  };

  config = {
    environment.shellAliases = {
      sc = "systemctl";
      jc = "journalctl";
      l = "journalctl";
    };

    settings = {
      domain = "localhost";
      notifyUrl = "https://notify.test.ekklesiademocracy.org/freeform_message";
      vvvote1Hostname = "vvvote1.test.ekklesiademocracy.org";
      vvvote2Hostname = "vvvote2.test.ekklesiademocracy.org";
      keycloakUrl = "https://keycloak.test.ekklesiademocracy.org/auth/realms/test/protocol/openid-connect/";

      basicVhostSettings = {
        #forceSSL = true;
        #enableACME = true;
      };
    };
  };

}
