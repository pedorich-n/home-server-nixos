{ config, containerLib, authentikLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/librechat/${localPath}:${remotePath}";

  envs = {
    POSTGRES_DB = "rag";
    POSTGRES_USER = "rag";

    RAG_PORT = "8080";
  };

  withInternalNetwork = containerLib.mkWithNetwork "librechat-internal";
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
    networks = containerLib.mkDefaultNetwork "librechat";

    containers = {
      librechat-vectordb = withInternalNetwork {
        containerConfig = {
          image = "ankane/pgvector:${containerVersions.librechat-vector}";
          name = "librechat-vectordb";
          volumes = [
            (storeFor "vectordb" "/var/lib/postgresql/data")
          ];
          environments = envs;
          environmentFiles = [ config.age.secrets.librechat.path ];
        };
      };

      librechat-mongodb = withInternalNetwork {
        containerConfig = {
          image = "mongo:${containerVersions.librechat-mongodb}";
          name = "librechat-mongodb";
          exec = "mongod --noauth";
          volumes = [
            (storeFor "mongodb" "/data/db")
          ];
        };
      };

      librechat-rag = withInternalNetwork {
        containerConfig = {
          image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:${containerVersions.librechat-rag}";
          name = "librechat-rag";
          environments = {
            VECTOR_DB_TYPE = "pgvector";
            DB_HOST = "librechat-vectordb";
            COLLECTION_NAME = "librechat";
            EMBEDDINGS_PROVIDER = "openai";
          } // envs;
          environmentFiles = [ config.age.secrets.librechat.path ];
        };

        unitConfig = {
          Requires = [
            "librechat-vectordb.service"
          ];
          After = [
            "librechat-vectordb.service"
          ];
        };
      };

      librechat = withInternalNetwork {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;

        containerConfig = containerLib.withAlpineHostsFix {
          image = "ghcr.io/danny-avila/librechat:${containerVersions.librechat-server}";
          name = "librechat";
          # See https://github.com/danny-avila/LibreChat/discussions/572#discussioncomment-7352331
          exec = "npm run backend:dev";
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
          labels = containerLib.mkTraefikLabels {
            name = "chat";
            port = 3080;
          };

        };

        unitConfig = {
          Requires = [
            "librechat-mongodb.service"
            "librechat-rag.service"
          ];
          After = [
            "librechat-mongodb.service"
            "librechat-rag.service"
          ];
        };
      };
    };
  };
}
