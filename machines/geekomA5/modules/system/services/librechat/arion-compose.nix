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

  virtualisation.arion.projects = {
    librechat.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "librechat") // dockerLib.externalTraefikNetwork;

      services = {
        vectordb.service = {
          image = "ankane/pgvector:${containerVersions.librechat-vector}";
          container_name = "vectordb";
          networks = [ "default" ];
          volumes = [
            (storeFor "vectordb" "/var/lib/postgresql/data")
          ];
          environment = envs;
          env_file = [ config.age.secrets.librechat_compose.path ];
          restart = "unless-stopped";
          labels = {
            "wud.tag.include" = ''^v\d+\.\d+\.\d+'';
          };
        };

        rag.service = {
          image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:${containerVersions.librechat-rag}";
          container_name = "rag";
          networks = [ "default" ];
          environment = {
            VECTOR_DB_TYPE = "pgvector";
            DB_HOST = "vectordb";
            COLLECTION_NAME = "librechat";
            EMBEDDINGS_PROVIDER = "openai";
          } // envs;
          env_file = [ config.age.secrets.librechat_compose.path ];
          depends_on = [ "vectordb" ];
          labels = {
            "wud.watch" = "false"; # There are no proper releases, so better to update manually
          };
        };

        mongodb.service = {
          image = "mongo:${containerVersions.librechat-mongodb}";
          container_name = "mongodb";
          command = "mongod --noauth";
          networks = [ "default" ];
          volumes = [
            (storeFor "mongodb" "/data/db")
          ];
          restart = "unless-stopped";
          labels = {
            "wud.tag.include" = ''^\d+\.\d+\.\d+$'';
          };
        };

        librechat.service = {
          # No proper tags on that image :(
          image = "ghcr.io/danny-avila/librechat-dev:92232afacab63a76d1b11d56921f77723a2cf90d";
          container_name = "librechat";
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
          labels = (dockerLib.mkTraefikLabels {
            name = "chat";
            port = 3080;
          }) // (dockerLib.mkHomepageLabels {
            name = "Libre Chat";
            group = "Services";
            slug = "chat";
            icon = "https://raw.githubusercontent.com/danny-avila/LibreChat/92232afacab63a76d1b11d56921f77723a2cf90d/client/public/assets/logo.svg";
            weight = 30;
          }) // {
            "wud.watch" = "false"; # There are no proper releases, so better to update manually
          };
        } // dockerLib.alpineHostsFix;
      };
    };
  };
}
