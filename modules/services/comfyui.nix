{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.comfyui;

  comfyui-rocm = pkgs.callPackage ../../pkgs/comfyui-rocm { };

  # Default checkpoint: Juggernaut XL v9 – a high-quality general-purpose SDXL
  # model that fits comfortably within 12 GB VRAM.  It supports both txt2img
  # and img2img natively in ComfyUI.  When used directly (without Diffusers
  # pipeline safety classifiers) the restrictions are minimal.
  defaultCheckpointUrl = "https://huggingface.co/RunDiffusion/Juggernaut-XL-v9/resolve/main/Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors";
  defaultCheckpointName = "Juggernaut-XL_v9.safetensors";

  # ComfyUI API-format workflow JSON for img2img.
  # Drop an image into /var/lib/comfyui/input/input.png, load this workflow
  # in the web UI, adjust the prompt, and click "Queue Prompt".
  img2imgWorkflow = pkgs.writeText "comfyui-img2img-workflow.json" ''
    {
      "1": {
        "inputs": {
          "ckpt_name": "${defaultCheckpointName}"
        },
        "class_type": "CheckpointLoaderSimple",
        "_meta": { "title": "Load Checkpoint" }
      },
      "2": {
        "inputs": {
          "text": "masterpiece, best quality, highly detailed",
          "clip": ["1", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": { "title": "Positive Prompt" }
      },
      "3": {
        "inputs": {
          "text": "bad quality, blurry, lowres, worst quality, jpeg artifacts",
          "clip": ["1", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": { "title": "Negative Prompt" }
      },
      "4": {
        "inputs": {
          "image": "input.png"
        },
        "class_type": "LoadImage",
        "_meta": { "title": "Load Image" }
      },
      "5": {
        "inputs": {
          "pixels": ["4", 0],
          "vae": ["1", 2]
        },
        "class_type": "VAEEncode",
        "_meta": { "title": "VAE Encode" }
      },
      "6": {
        "inputs": {
          "seed": 42,
          "steps": 25,
          "cfg": 7.0,
          "sampler_name": "euler_ancestral",
          "scheduler": "normal",
          "denoise": 0.6,
          "model": ["1", 0],
          "positive": ["2", 0],
          "negative": ["3", 0],
          "latent_image": ["5", 0]
        },
        "class_type": "KSampler",
        "_meta": { "title": "KSampler" }
      },
      "7": {
        "inputs": {
          "samples": ["6", 0],
          "vae": ["1", 2]
        },
        "class_type": "VAEDecode",
        "_meta": { "title": "VAE Decode" }
      },
      "8": {
        "inputs": {
          "filename_prefix": "img2img",
          "images": ["7", 0]
        },
        "class_type": "SaveImage",
        "_meta": { "title": "Save Image" }
      }
    }
  '';

  # ComfyUI API-format workflow JSON for txt2img.
  txt2imgWorkflow = pkgs.writeText "comfyui-txt2img-workflow.json" ''
    {
      "1": {
        "inputs": {
          "ckpt_name": "${defaultCheckpointName}"
        },
        "class_type": "CheckpointLoaderSimple",
        "_meta": { "title": "Load Checkpoint" }
      },
      "2": {
        "inputs": {
          "text": "masterpiece, best quality, highly detailed",
          "clip": ["1", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": { "title": "Positive Prompt" }
      },
      "3": {
        "inputs": {
          "text": "bad quality, blurry, lowres, worst quality, jpeg artifacts",
          "clip": ["1", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": { "title": "Negative Prompt" }
      },
      "4": {
        "inputs": {
          "width": 1024,
          "height": 1024,
          "batch_size": 1
        },
        "class_type": "EmptyLatentImage",
        "_meta": { "title": "Empty Latent Image" }
      },
      "5": {
        "inputs": {
          "seed": 42,
          "steps": 25,
          "cfg": 7.0,
          "sampler_name": "euler_ancestral",
          "scheduler": "normal",
          "denoise": 1.0,
          "model": ["1", 0],
          "positive": ["2", 0],
          "negative": ["3", 0],
          "latent_image": ["4", 0]
        },
        "class_type": "KSampler",
        "_meta": { "title": "KSampler" }
      },
      "6": {
        "inputs": {
          "samples": ["5", 0],
          "vae": ["1", 2]
        },
        "class_type": "VAEDecode",
        "_meta": { "title": "VAE Decode" }
      },
      "7": {
        "inputs": {
          "filename_prefix": "txt2img",
          "images": ["6", 0]
        },
        "class_type": "SaveImage",
        "_meta": { "title": "Save Image" }
      }
    }
  '';

  # Sensible defaults for a 12 GB RDNA2 card (RX 6700 XT).
  # These can be overridden via extraArgs.
  defaultArgs = [
    "--listen"
    cfg.listenAddress
    "--port"
    (toString cfg.port)
    "--reserve-vram"
    "1.0"
    "--bf16-unet"
    "--bf16-vae"
    "--use-pytorch-cross-attention"
  ];

  args = lib.concatStringsSep " " (defaultArgs ++ cfg.extraArgs);
in

{
  options.services.comfyui = {
    enable = lib.mkEnableOption "ComfyUI AI image generation service with ROCm";

    user = lib.mkOption {
      type = lib.types.str;
      default = "comfyui";
      description = "User account under which ComfyUI runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "comfyui";
      description = "Group under which ComfyUI runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/comfyui";
      description = "Persistent directory for models, outputs, custom_nodes, and user data.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address to bind the ComfyUI HTTP server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8188;
      description = "TCP port for the ComfyUI HTTP server.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra command-line arguments passed to ComfyUI.
        See ComfyUI's --help for available options (e.g. --lowvram, --novram,
        --fp16-unet, --force-fp16, etc.).
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the configured port in the firewall.";
    };

    downloadDefaultModels = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Download a default high-quality SDXL checkpoint on first start.
        The model is placed in the checkpoints directory and a pair of
        starter workflows (txt2img + img2img) are copied into the user
        directory.  Set to false if you prefer to manage models manually.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      description = "ComfyUI service user";
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    # Ensure model subdirectories exist and are writable.
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/checkpoints' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/vae' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/loras' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/controlnet' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/clip' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/clip_vision' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/diffusers' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/gligen' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/style_models' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/embeddings' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/upscale_models' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/vae_approx' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/ipadapter' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/unet' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/models/photomaker' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/custom_nodes' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/input' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/output' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/user' 0750 ${cfg.user} ${cfg.group} -"
      "d '${cfg.dataDir}/user/default_workflows' 0750 ${cfg.user} ${cfg.group} -"
    ];

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    # One-shot service that downloads the default checkpoint on first boot.
    # If the file already exists the download is skipped so the service is
    # idempotent.
    systemd.services.comfyui-model-setup = lib.mkIf cfg.downloadDefaultModels {
      description = "Download ComfyUI default checkpoint and workflows";
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        RemainAfterExit = true;
      };

      path = with pkgs; [ curl ];

      script = ''
        CHECKPOINT_DIR="${cfg.dataDir}/models/checkpoints"
        WORKFLOW_DIR="${cfg.dataDir}/user/default_workflows"

        mkdir -p "$CHECKPOINT_DIR" "$WORKFLOW_DIR"

        if [ ! -f "$CHECKPOINT_DIR/${defaultCheckpointName}" ]; then
          echo "Downloading default checkpoint (${defaultCheckpointName}) …"
          curl -fL -o "$CHECKPOINT_DIR/${defaultCheckpointName}.tmp" \
            "${defaultCheckpointUrl}"
          mv "$CHECKPOINT_DIR/${defaultCheckpointName}.tmp" \
            "$CHECKPOINT_DIR/${defaultCheckpointName}"
          echo "Checkpoint saved to $CHECKPOINT_DIR/${defaultCheckpointName}"
        fi

        # Copy starter workflows.
        cp ${img2imgWorkflow} "$WORKFLOW_DIR/img2img.json"
        cp ${txt2imgWorkflow}  "$WORKFLOW_DIR/txt2img.json"
      '';
    };

    systemd.services.comfyui = {
      description = "ComfyUI AI image generation (ROCm)";
      after = [
        "network.target"
      ]
      ++ lib.optional cfg.downloadDefaultModels "comfyui-model-setup.service";
      requires = lib.optional cfg.downloadDefaultModels "comfyui-model-setup.service";
      wantedBy = [ "multi-user.target" ];

      environment = {
        # AMD gfx1030 / RDNA2 workaround: pretend the GPU is gfx1030 for the
        # ROCm runtime.  Without this, torchWithRocm may fail to initialise
        # on consumer cards that are not in the official support list.
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";

        # Reduce memory fragmentation and improve stability on 12 GB cards.
        PYTORCH_HIP_ALLOC_CONF = "expandable_segments:True";

        # Point ComfyUI at our persistent data directory for all mutable state.
        COMFYUI_PATH = cfg.dataDir;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${comfyui-rocm}/bin/comfyui-rocm --base-directory ${cfg.dataDir} ${args}";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening – keep it relaxed enough for GPU and Python workloads.
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
      };
    };

    # Make ROCm debugging tools and huggingface-cli available system-wide so
    # the user can easily pull additional checkpoints / LoRAs.
    environment.systemPackages = with pkgs; [
      rocmPackages.rocminfo
      rocmPackages.rocm-smi
      (python3.withPackages (ps: [ ps.huggingface-hub ]))
    ];
  };
}
