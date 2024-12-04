{ config, dockerLib, authentikLib, lib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/librechat/${localPath}:${remotePath}";

  envs = {
    POSTGRES_DB = "rag";
    POSTGRES_USER = "rag";

    RAG_PORT = "8080";
  };
in
{
  systemd.targets.librechat = {
    wants = [
      "librechat-internal-network.service"
      "librechat-vectordb.service"
      "librecaht-mongodb.service"
      "librechat-rag.service"
      "librechat.service"
    ];
  };

  virtualisation.quadlet = {
    networks = {
      librechat-internal.networkConfig.name = "librechat-internal";
    };

    containers = {
      librechat-vectordb = {
        containerConfig = {
          image = "ankane/pgvector:${containerVersions.librechat-vector}";
          name = "librechat-vectordb";
          networks = [ "librechat-internal" ];
          volumes = [
            (storeFor "vectordb" "/var/lib/postgresql/data")
          ];
          environments = envs;
          environmentFiles = [ config.age.secrets.librechat.path ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          Requires = [
            "librechat-internal-network.service"
          ];
        };
      };

      librechat-mongodb = {
        containerConfig = {
          image = "mongo:${containerVersions.librechat-mongodb}";
          name = "librechat-mongodb";
          exec = "mongod --noauth";
          networks = [ "librechat-internal" ];
          volumes = [
            (storeFor "mongodb" "/data/db")
          ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          Requires = [
            "librechat-internal-network.service"
          ];
        };
      };

      librechat-rag = {
        containerConfig = {
          image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:${containerVersions.librechat-rag}";
          name = "librechat-rag";
          networks = [ "librechat-internal" ];
          environments = {
            VECTOR_DB_TYPE = "pgvector";
            DB_HOST = "librechat-vectordb";
            COLLECTION_NAME = "librechat";
            EMBEDDINGS_PROVIDER = "openai";
          } // envs;
          environmentFiles = [ config.age.secrets.librechat.path ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          Requires = [
            "librechat-internal-network.service"
            "librechat-vectordb.service"
          ];
        };
      };

      librechat = {
        containerConfig = {
          image = "ghcr.io/danny-avila/librechat:${containerVersions.librechat-server}";
          name = "librechat";
          # See https://github.com/danny-avila/LibreChat/discussions/572#discussioncomment-7352331
          exec = "npm run backend:dev";
          addHosts = [ "authentik.${config.custom.networking.domain}:192.168.10.15" ];
          networks = [
            "librechat-internal"
            "traefik"
          ];
          # user = userSetting;
          environments = rec {
            MONGO_URI = "mongodb://librechat-mongodb:27017/LibreChat";
            RAG_API_URL = "http://librechat-rag:${envs.RAG_PORT}";

            # DEBUG_LOGGING = "true";
            SEARCH = "false";

            ALLOW_EMAIL_LOGIN = "false";
            ALLOW_REGISTRATION = "false";

            ALLOW_SOCIAL_LOGIN = "true";
            ALLOW_SOCIAL_REGISTRATION = "true";
            OPENID_ISSUER = authentikLib.mkIssuerUrl "librechat";
            OPENID_SCOPE = authentikLib.openIdScopes;
            OPENID_CALLBACK_URL = "/oauth/openid/callback";
            DOMAIN_SERVER = "http://chat.${config.custom.networking.domain}";
            DOMAIN_CLIENT = DOMAIN_SERVER;
          } // envs;
          environmentFiles = [ config.age.secrets.librechat.path ];
          volumes = [
            (storeFor "chat/images" "/app/client/public/images")
            (storeFor "chat/logs" "/app/api/logs")
            "${./config/librechat.yaml}:/app/librechat.yaml"
          ];
          #TODO: make mkTraefikLabels return a list
          labels = lib.mapAttrsToList (name: value: "${name}=${value}") (dockerLib.mkTraefikLabels {
            name = "chat";
            port = 3080;
          });

        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          Requires = [
            "librechat-internal-network.service"
            "librechat-mongodb.service"
            "librechat-rag.service"
          ];
          After = [
            "authentik.target"
            "traefik-network.service"
          ];
        };
      };
    };
  };
}
