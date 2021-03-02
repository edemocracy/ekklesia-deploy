{ sources ? null }:
with builtins;

let
  sources_ = if (sources == null) then import ./nix/sources.nix else sources;
  ekklesia-portal-src = sources_.ekklesia-portal;
  ekklesia-vvvote-src = sources_.nix-ekklesia-vvvote;

  vvvote1Hostname = "vvvote1.test.ekklesiademocracy.org";
  vvvote2Hostname = "vvvote2.test.ekklesiademocracy.org";
  keycloakAuthUrl = "https://keycloak.test.ekklesiademocracy.org/auth/realms/test/protocol/openid-connect/";

  basicVhostSettings = {
    #forceSSL = true;
    #enableACME = true;
  };

in
{
  network.description = "Test deploy";

  portal =
    { config, pkgs, ...}:
    {
      imports = [
        "${ekklesia-portal-src}/nix/modules"
      ];

      services.nginx = {
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

        virtualHosts."portal.test.ekklesiademocracy.org" =
          basicVhostSettings // {
            locations = {
              "/" = {
                proxyPass = "http://127.0.0.1:10000";
              };

              "= /favicon.ico" = {
                extraConfig = "return 404;";
              };

            };
          };
      };

      services.postgresql.enable = true;
      services.postgresql.package = pkgs.postgresql_12;
      services.postgresql.ensureDatabases = [ "ekklesia-portal" ];
      services.postgresql.ensureUsers = [
        {
          name = "ekklesia-portal";
          ensurePermissions = { "DATABASE ekklesia-portal" = "ALL PRIVILEGES"; };
        }
      ];

      services.ekklesia.portal.enable = true;
      services.ekklesia.portal.extraConfig = {
        app = {
          force_ssl = true;
          login_visible = true;
          instance_name = "test.ekklesiademocracy.org";
          title = "TEST-Portal";
          insecure_development_mode = true;
          languages = [ "de" "en" ];
          fallback_language = "de";
        };

        browser_session = {
          secret_key = "@secret_key@";
          permanent_lifetime = 86400;
          cookie_secure = true;
        };

        database = {
          uri = "postgresql+psycopg2://ekklesia:e@127.0.0.1/ekklesia_portal";
          fts_language = "german";
        };

        ekklesia_auth =
        let
          keycloakUrl = "https://keycloak.test.ekklesiademocracy.org/auth/realms/test/protocol/openid-connect";
        in {
          enabled = true;
          client_id = "portal";
          client_secret = "@client_secret@";
          authorization_url = "${keycloakUrl}/auth";
          token_url = "${keycloakUrl}/token";
          userinfo_url = "${keycloakUrl}/userinfo";
          logout_url = "${keycloakUrl}/logout";
          display_name = "Test-Keycloak";
        };

        importer = {
          testdiscourse = {
              schema = "discourse_topic";
              base_url = "https://testdiscourse.televotia.ch";
              api_key = "@discourse_api_key@";
              api_username = "test-antragsportal";
          };
        };

        exporter = {
          testdiscourse = {
            api_key = "@discourse_api_key@";
            api_username = "test-antragsportal";
            category = 18;
            importer = "testdiscourse";
            base_url = "https://testdiscourse.televotia.ch";
          };
        };

        voting_modules = {
          vvvote_test_ekklesiademocracy = {
            api_urls = [
              "https://vvvote1.test.ekklesiademocracy.org/backend/api/v1"
              "https://vvvote2.test.ekklesiademocracy.org/backend/api/v1"
            ];
            defaults = {
              auth_server_id = "ekklesia";
              must_be_verified = true;
              must_be_eligible = true;
              required_role = "Piratenpartei Deutschland";
            };
            type = "vvvote";
          };
        };
      };

    };

  vvvote1 =
    { config, pkgs, ...}:
    {
      imports = [
        "${ekklesia-vvvote-src}/modules"
      ];

      services.ekklesia.vvvote = {
        enableBackend = true;
        backendPrefix = "/backend";
        backendHostname = vvvote1Hostname;

        createDatabaseLocally = true;
        enableWebclient = true;
        webclientHostname = vvvote1Hostname;
        notifyClientSecretFile = "/var/lib/vvvote/notifyClientSecret";
        oauthClientSecretFile = "/var/lib/vvvote/oauthClientSecret";
        permissionPrivateKeyFile = "/var/lib/vvvote/private_keys/PermissionServer1.privatekey.pem.php";
        tallyPrivateKeyFile = "/var/lib/vvvote/private_keys/TallyServer1.privatekey.pem.php";

        settings = {
          backendUrls = [ "https://${vvvote1Hostname}/backend" "https://${vvvote2Hostname}/backend" ];
          debug = true;
          idServerUrl = keycloakAuthUrl;
          publicKeydir = /var/lib/vvvote/public_keys;
          serverNumber = 1;
          votePort = 443;
          webclientUrl = "http://${vvvote1Hostname}/vvvote";
          oauth = {
            clientIds = [ vvvote1Hostname vvvote2Hostname ];
            notifyUrl = "https://notify.test.ekklesiademocracy.org/freeform_message";
            oauthUrl = keycloakAuthUrl;
            resourcesUrl = keycloakAuthUrl;
            notifyClientId = "example_app";
          };
        };
      };

      services.mysql.enable = true;
      services.mysql.package = pkgs.mariadb;

    };

  vvvote2 =
    { config, pkgs, ...}:
    {

      imports = [
        "${ekklesia-vvvote-src}/modules"
      ];

      services.ekklesia.vvvote = {
        enableBackend = true;
        backendPrefix = "/backend";
        backendHostname = vvvote2Hostname;

        createDatabaseLocally = true;
        notifyClientSecretFile = "/var/lib/vvvote/notifyClientSecret";
        oauthClientSecretFile = "/var/lib/vvvote/oauthClientSecret";
        permissionPrivateKeyFile = "/var/lib/vvvote/private_keys/PermissionServer2.privatekey.pem.php";
        tallyPrivateKeyFile = "/var/lib/vvvote/private_keys/TallyServer2.privatekey.pem.php";

        settings = {
          backendUrls = [ "https://${vvvote1Hostname}/backend" "https://${vvvote2Hostname}/backend" ];
          debug = true;
          idServerUrl = keycloakAuthUrl;
          isTallyServer = true;
          publicKeydir = /var/lib/vvvote/public_keys;
          serverNumber = 2;
          votePort = 443;
          webclientUrl = "http://${vvvote1Hostname}/vvvote";
          oauth = {
            clientIds = [ vvvote1Hostname vvvote2Hostname ];
            notifyUrl = "https://notify.test.ekklesiademocracy.org/freeform_message";
            oauthUrl = keycloakAuthUrl;
            resourcesUrl = keycloakAuthUrl;
            notifyClientId = "example_app";
          };
        };
      };

      services.mysql.enable = true;
      services.mysql.package = pkgs.mariadb;

    };
}
