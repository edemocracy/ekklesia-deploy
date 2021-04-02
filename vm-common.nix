{ config, pkgs, lib, ... }:
{
  options = with lib; {
    settings = mkOption {
      type = types.attrs;
      default = {};
    };
  };

  config = {

    nixpkgs.localSystem.system = "x86_64-linux";

    environment.shellAliases = {
      sc = "systemctl";
      jc = "journalctl";
      l = "journalctl";
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = with config.settings; {
      enable = true;
      enableReload = true;
      statusPage = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      sslCiphers = lib.concatStringsSep ":" [
        "ECDHE-ECDSA-AES256-GCM-SHA384"
        "ECDHE-ECDSA-CHACHA20-POLY1305"
        "ECDHE-RSA-AES256-GCM-SHA384"
        "ECDHE-RSA-CHACHA20-POLY1305"
      ];

      commonHttpConfig = ''
        log_format request_body $request_body;
      '';
    };

    settings = rec {
      domain = "localhost";
      notifyUrl = "https://notify.test.ekklesiademocracy.org/freeform_message";
      vvvote1Hostname = "vvvote1.${domain}";
      vvvote2Hostname = "vvvote2.${domain}";
      keycloakUrl = "https://keycloak.test.ekklesiademocracy.org/auth/realms/test/protocol/openid-connect/";

      basicVhostSettings = {
        #forceSSL = true;
        #enableACME = true;
      };
    };
  };

}
