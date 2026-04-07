{
  pkgs,
  networkingLib,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
yamlFormat.generate "librechat.yaml" {
  version = "1.2.1";
  cache = true;

  interface = {
    modelSelect = true;
    presets = true;
    parameters = true;
  };

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

  ocr = {
    strategy = "mistral_ocr";
    apiKey = "\${OCR_API_KEY}";
    baseURL = "https://api.mistral.ai/v1";
    mistralModel = "mistral-ocr-latest";
  };

  modelSpecs = {
    prioritize = true;
    list = [
      {
        name = "default-gemini";
        label = "Gemini 3 Flash";
        default = true;
        preset = {
          endpoint = "google";
          model = "gemini-3-flash-preview";
        };
      }
    ];
  };

  mcpServers = {
    Grist = {
      command = "uvx";
      # https://pypi.org/project/mcp-server-grist/#history
      args = [ "mcp-server-grist@0.2.1" ];
      env = {
        GRIST_API_KEY = "\${GRIST_API_KEY}";
        GRIST_API_HOST = "${networkingLib.mkUrl "grist"}/api";
      };
    };
  };
}
