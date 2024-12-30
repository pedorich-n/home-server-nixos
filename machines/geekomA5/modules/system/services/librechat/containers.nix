{ config, containerLib, authentikLib, systemdLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/librechat/${localPath}:${remotePath}";

  envs = {
    POSTGRES_DB = "rag";
    POSTGRES_USER = "rag";

    RAG_PORT = "8080";
  };

  pod = "librechat.pod";
  networks = [ "librechat-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "librechat";

    pods.librechat = {
      podConfig = { inherit networks; };
    };

    containers = {
      librechat-vectordb = {
        useGlobalContainers = true;
        useProvidedHealthcheck = true;

        containerConfig = {
          volumes = [
            (storeFor "vectordb" "/var/lib/postgresql/data")
          ];
          environments = envs;
          environmentFiles = [ config.age.secrets.librechat.path ];
          inherit networks pod;
        };
      };

      librechat-mongodb = {
        useGlobalContainers = true;
        containerConfig = {
          exec = "mongod --noauth";
          volumes = [
            (storeFor "mongodb" "/data/db")
          ];
          inherit networks pod;
        };
      };

      librechat-rag = {
        useGlobalContainers = true;
        containerConfig = {
          environments = {
            VECTOR_DB_TYPE = "pgvector";
            DB_HOST = "librechat-vectordb";
            COLLECTION_NAME = "librechat";
            EMBEDDINGS_PROVIDER = "openai";
          } // envs;
          environmentFiles = [ config.age.secrets.librechat.path ];
          inherit networks pod;
        };

        unitConfig = systemdLib.requiresAfter [ "librechat-vectordb.service" ] { };
      };

      librechat-server = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;

        containerConfig = containerLib.withAlpineHostsFix {
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
          inherit networks pod;

        };

        unitConfig = systemdLib.requiresAfter
          [
            "librechat-mongodb.service"
            "librechat-rag.service"
          ]
          { };
      };
    };
  };
}
