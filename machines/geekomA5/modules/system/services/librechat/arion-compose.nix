{ config, dockerLib, authentikLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/librechat/${localPath}:${remotePath}";
  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  envs = {
    POSTGRES_DB = "rag";
    POSTGRES_USER = "rag";

    RAG_PORT = "8080";
  };
in
{
  systemd.services."arion-librechat" = {
    after = [ "arion-authentik.service" ];
  };

  virtualisation.arion.projects = {
    librechat.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "librechat") // dockerLib.externalTraefikNetwork;

      services = {
        vectordb.service = {
          image = "ankane/pgvector:${containerVersions.librechat-vector}";
          container_name = "librechat-vectordb";
          networks = [ "default" ];
          volumes = [
            (storeFor "vectordb" "/var/lib/postgresql/data")
          ];
          environment = envs;
          env_file = [ config.age.secrets.librechat_compose.path ];
          restart = "unless-stopped";
        };

        rag.service = {
          image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:${containerVersions.librechat-rag}";
          container_name = "librechat-rag";
          networks = [ "default" ];
          environment = {
            VECTOR_DB_TYPE = "pgvector";
            DB_HOST = "vectordb";
            COLLECTION_NAME = "librechat";
            EMBEDDINGS_PROVIDER = "openai";
          } // envs;
          env_file = [ config.age.secrets.librechat_compose.path ];
          depends_on = [ "vectordb" ];
        };

        mongodb.service = {
          image = "mongo:${containerVersions.librechat-mongodb}";
          container_name = "librechat-mongodb";
          command = "mongod --noauth";
          networks = [ "default" ];
          volumes = [
            (storeFor "mongodb" "/data/db")
          ];
          restart = "unless-stopped";
        };

        server.service = {
          image = "ghcr.io/danny-avila/librechat:${containerVersions.librechat-server}";
          container_name = "librechat-server";
          # See https://github.com/danny-avila/LibreChat/discussions/572#discussioncomment-7352331
          command = "npm run backend:dev";
          networks = [
            "default"
            "traefik"
          ];
          restart = "unless-stopped";
          user = userSetting;
          environment = rec {
            MONGO_URI = "mongodb://mongodb:27017/LibreChat";
            RAG_API_URL = "http://rag:${envs.RAG_PORT}";

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
          env_file = [ config.age.secrets.librechat_compose.path ];
          volumes = [
            (storeFor "chat/images" "/app/client/public/images")
            (storeFor "chat/logs" "/app/api/logs")
            "${./config/librechat.yaml}:/app/librechat.yaml"
          ];
          depends_on = [
            "mongodb"
            "rag"
          ];
          labels = dockerLib.mkTraefikLabels {
            name = "chat";
            port = 3080;
          };
        } // dockerLib.alpineHostsFix;
      };
    };
  };
}
