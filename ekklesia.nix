{ sources ? null }:

with builtins;

let
  sources_ = if (sources == null) then import ./nix/sources.nix else sources;
  #ekklesia-portal-src = sources_.ekklesia-portal;
  # Point to local portal code to make experimenting easier.
  ekklesia-portal-src = ../ekklesia-portal;
  ekklesia-vvvote-src = sources_.nix-ekklesia-vvvote;
  # ekklesia-vvvote-src = ../nix-ekklesia-vvvote;

in
{
  network.description = "Test deploy";

  portal =
    { config, pkgs, lib, ...}:
    {
      imports = [
        "${ekklesia-portal-src}/nix/modules"
        ./vm-common.nix
      ];

      environment.systemPackages = [
        config.services.postgresql.package
        pkgs.jq
      ];

      services.nginx = with config.settings; {
        virtualHosts."portal.${domain}" =
          basicVhostSettings // {
            locations = {
              "/" = {
                proxyPass = "http://127.0.0.1:10000";
              };

              "/static/" = {
                alias = "${config.services.ekklesia.portal.staticFiles}/";
              };

              "= /favicon.ico" = {
                extraConfig = "return 404;";
              };

            };
          };
      };

      services.postgresql.enable = true;
      services.postgresql.package = pkgs.postgresql_12;

      services.ekklesia.portal = with config.settings; {
        enable = true;
        secretFiles = {
          discourse_api_key = "/var/lib/ekklesia-portal/discourse-api-key";
          #notify_client_secret = "/var/lib/ekklesia-portal/notify_client_secret";
          oauth_client_secret = "/var/lib/ekklesia-portal/oauth-client-secret";
        };

        extraConfig = {
          app = {
            force_ssl = true;
            login_visible = true;
            instance_name = domain;
            title = "TEST-Portal";
            insecure_development_mode = true;
            languages = [ "de" "en" ];
            fallback_language = "de";
          };

          browser_session = {
            secret_key = "@browser_session_secret_key@";
            permanent_lifetime = 86400;
            cookie_secure = false;
          };

          database = {
            uri = "postgresql+psycopg2:///ekklesia-portal?host=/run/postgresql";
            fts_language = "german";
          };

          ekklesia_auth = {
            enabled = true;
            client_id = "portal";
            client_secret = "@oauth_client_secret@";
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
                "${vvvote1Hostname}/backend/api/v1"
                "${vvvote2Hostname}/backend/api/v1"
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

      systemd.services.ekklesia-portal-db = {
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
        path = [ config.services.postgresql.package ];
        script = ''
          psql -c 'CREATE DATABASE "ekklesia-portal"' || true
          psql -c 'CREATE USER "ekklesia-portal"' || true
          psql -c 'GRANT ALL ON DATABASE "ekklesia-portal" TO "ekklesia-portal"'
        '';

        serviceConfig = {
          User = "postgres";
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      systemd.services.ekklesia-portal-test-data = {
        before = [ "ekklesia-portal.service" ];
        after = [ "ekklesia-portal-db.service" ];
        requires = [ "ekklesia-portal-db.service" ];
        requiredBy = [ "ekklesia-portal.service" ];

        script = ''
          cd ${ekklesia-portal-src}
          export PYTHONPATH=./src
          ${config.services.ekklesia.portal.app}/bin/python \
            tests/create_test_db.py \
            -c ${config.services.ekklesia.portal.configFile} --doit
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "ekklesia-portal";
          Group = "ekklesia-portal";
          RemainAfterExit = true;
        };
      };
    };

  vvvote1 =
    { config, pkgs, ...}:
    {
      imports = [
        "${ekklesia-vvvote-src}/modules"
        ./vm-common.nix
      ];

      services.ekklesia.vvvote = with config.settings; {
        enableBackend = true;
        backendPrefix = "/backend";
        backendHostname = vvvote1Hostname;

        createDatabaseLocally = true;
        enableWebclient = true;
        webclientHostname = vvvote1Hostname;
        privateKeydir = "/var/lib/vvvote/private-keys";
        permissionPrivateKeyFile = "PermissionServer1.privatekey.pem.php";
        tallyPrivateKeyFile = "TallyServer1.privatekey.pem.php";

        settings = {
          backendUrls = [ "https://${vvvote1Hostname}/backend" "https://${vvvote2Hostname}/backend" ];
          debug = true;
          idServerUrl = keycloakUrl;
          publicKeydir = "/var/lib/vvvote/public-keys";
          serverNumber = 1;
          votePort = 80;
          webclientUrl = "http://${vvvote1Hostname}/vvvote";
          oauth = {
            clientIds = [ vvvote1Hostname vvvote2Hostname ];
            inherit notifyUrl;
            oauthUrl = keycloakUrl;
            resourcesUrl = keycloakUrl;
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
        ./vm-common.nix
      ];

      services.ekklesia.vvvote = with config.settings; {
        enableBackend = true;
        backendPrefix = "/backend";
        backendHostname = vvvote2Hostname;

        createDatabaseLocally = true;
        privateKeydir = "/var/lib/vvvote/private-keys";
        permissionPrivateKeyFile = "PermissionServer2.privatekey.pem.php";
        tallyPrivateKeyFile = "TallyServer2.privatekey.pem.php";

        settings = {
          backendUrls = [ "http://${vvvote1Hostname}/backend" "http://${vvvote2Hostname}/backend" ];
          debug = true;
          idServerUrl = keycloakUrl;
          isTallyServer = true;
          publicKeydir = "/var/lib/vvvote/public-keys";
          serverNumber = 2;
          votePort = 80;
          webclientUrl = "http://${vvvote1Hostname}/vvvote";
          oauth = {
            clientIds = [ vvvote1Hostname vvvote2Hostname ];
            inherit notifyUrl;
            oauthUrl = keycloakUrl;
            resourcesUrl = keycloakUrl;
            notifyClientId = "example_app";
          };
        };
      };

      services.mysql.enable = true;
      services.mysql.package = pkgs.mariadb;

    };
}
