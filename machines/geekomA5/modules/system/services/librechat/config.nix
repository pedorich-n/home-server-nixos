{
  config,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  sops.templates."librechat/librechat.yaml" = {
    owner = config.users.users.user.name;
    group = config.users.users.user.group;

    file = yamlFormat.generate "librechat-template.yaml" {
      version = "1.2.1";
      cache = true;

      endpoints = {
        custom = [
          {
            name = "OpenRouter";
            apiKey = "\${OPENROUTER_KEY}";
            baseURL = "https://openrouter.ai/api/v1";
            modelDisplayLabel = "OpenRouter";
            models = {
              default = [
                "deepseek/deepseek-chat-v3.1"
                "qwen/qwen3-235b-a22b"
              ];
            };
          }
        ];
      };
    };
  };
}
