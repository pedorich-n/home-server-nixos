{
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
yamlFormat.generate "librechat.yaml" {
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
}
