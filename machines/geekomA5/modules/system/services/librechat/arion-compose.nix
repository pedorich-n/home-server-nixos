{ config, dockerLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/librechat/${localPath}:${remotePath}";
  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  envs = {
    POSTGRES_DB = "rag";
    POSTGRES_USER = "rag";
  };
in
{

  virtualisation.arion.projects = {
    librechat.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "librechat") // dockerLib.externalTraefikNetwork;

      services = {
        vectordb.service = {
          image = "ankane/pgvector:v0.5.1";
          container_name = "vectordb";
          networks = [ "default" ];
          volumes = [
            (storeFor "vectordb" "/var/lib/postgresql/data")
          ];
          environment = envs;
          env_file = [ config.age.secrets.librechat_compose.path ];
          restart = "unless-stopped";
        };

        rag.service = {
          image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:12427916d74d61ca02751c6358fbd21014a5757f";
          container_name = "rag";
          networks = [ "default" ];
          environment = {
            VECTOR_DB_TYPE = "pgvector";
            DB_HOST = "vectordb";
            RAG_PORT = "8000";
            COLLECTION_NAME = "librechat";
            EMBEDDINGS_PROVIDER = "openai";
          } // envs;
          env_file = [ config.age.secrets.librechat_compose.path ];
          depends_on = [ "vectordb" ];
        };

        mongodb.service = {
          image = "mongo:5.0.27";
          container_name = "mongodb";
          command = "mongod --noauth";
          networks = [ "default" ];
          volumes = [
            (storeFor "mongodb" "/data/db")
          ];
          restart = "unless-stopped";
        };

        librechat.service = {
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
            RAG_PORT = "8000";
            RAG_API_URL = "http://rag:${RAG_PORT}";

            # DEBUG_LOGGING = "true";
            SEARCH = "false";

            ALLOW_EMAIL_LOGIN = "true";
            ALLOW_REGISTRATION = "true";
            ALLOW_SOCIAL_LOGIN = "true";
            ALLOW_SOCIAL_REGISTRATION = "true";
            OPENID_ISSUER = "http://authentik.${config.custom.networking.domain}/application/o/librechat/.well-known/openid-configuration";
            OPENID_SCOPE = "openid profile email";
            OPENID_CALLBACK_URL = "/oauth/openid/callback";
            DOMAIN_SERVER = "http://chat.${config.custom.networking.domain}";
            DOMAIN_CLIENT = DOMAIN_SERVER;
          };
          env_file = [ config.age.secrets.librechat_compose.path ];
          extra_hosts = [
            #NOTE - there's a bug with musl or C libs or something in this base image. 
            # `dig` resolves the local domain, but `curl` fails, and the call to OIDC discovery fails too.  Providing hard-coded host seems to help.
            "authentik.${config.custom.networking.domain}:192.168.15.15"
          ];
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
          });
        };
      };
    };
  };
}
