{
  pkgs,
  networkingLib,
  portsCfg,
  mcpServersCfg,
}:
let
  yamlFormat = pkgs.formats.yaml { };

  mkDashboardIconUrl = iconName: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/${iconName}.png";

  mkPackageWithVersionFor = name: "${mcpServersCfg.${name}.package}@${mcpServersCfg.${name}.version}";
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

  mcpSettings = {
    allowedDomains = [
      (networkingLib.mkDomain "*")
      "host.containers.internal" # Host machine from within Podman containers
    ];
  };

  mcpServers = {
    Grist = {
      command = "uvx";
      iconPath = mkDashboardIconUrl "grist";
      # https://pypi.org/project/mcp-server-grist/#history
      args = [ (mkPackageWithVersionFor "grist") ];
      env = {
        GRIST_API_KEY = "\${GRIST_API_KEY}";
        GRIST_API_HOST = "${networkingLib.mkUrl "grist"}/api";
      };
    };

    Forgejo = {
      command = "forgejo-mcp";
      iconPath = mkDashboardIconUrl "git";
      args = [
        "--transport"
        "stdio"
      ];
      env = {
        FORGEJO_ACCESS_TOKEN = "\${FORGEJO_API_KEY}";
        FORGEJO_URL = networkingLib.mkUrl "git";
        FORGEJO_USER_AGENT = "forgejo-mcp/1.0.0";
      };
    };

    Netdata = {
      type = "streamable-http";
      iconPath = mkDashboardIconUrl "netdata";
      url = "http://host.containers.internal:${portsCfg.tcp.netdata.portStr}/mcp";
      headers = {
        Authorization = "Bearer \${NETDATA_MCP_API_KEY}";
      };
    };

    NixOS = {
      command = "uvx";
      iconPath = mkDashboardIconUrl "nixos";
      # https://pypi.org/project/mcp-nixos/#history
      args = [ (mkPackageWithVersionFor "nixos") ];
    };

    SearXNG = {
      command = "npx";
      iconPath = mkDashboardIconUrl "searxng";
      # https://www.npmjs.com/package/mcp-searxng?activeTab=versions
      args = [
        "--yes"
        (mkPackageWithVersionFor "searxng")
      ];
      env = {
        SEARXNG_URL = networkingLib.mkUrl "searxng";
      };
    };

    Time = {
      command = "uvx";
      iconPath = "https://img.icons8.com/?size=128&id=423";
      # https://pypi.org/project/mcp-server-time/#history
      args = [ (mkPackageWithVersionFor "time") ];
    };

    Fetch = {
      command = "uvx";
      iconPath = "https://img.icons8.com/?size=128&id=21339";
      # https://pypi.org/project/mcp-server-fetch/#history
      args = [ (mkPackageWithVersionFor "fetch") ];
    };
  };
}
