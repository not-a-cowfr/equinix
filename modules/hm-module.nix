{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.equinix;

  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    attrsets
    lists
    ;

  dop = with types; coercedTo package (a: a.outPath) pathInStore;

  recursiveUpdateAttrsList =
    list:
    if (builtins.length list <= 1) then
      (builtins.elemAt list 0)
    else
      recursiveUpdateAttrsList (
        [
          (attrsets.recursiveUpdate (builtins.elemAt list 0) (builtins.elemAt list 1))
        ]
        ++ (lists.drop 2 list)
      );

  applyPostPatch =
    pkg:
    pkg.overrideAttrs (o: {
      postPatch = lib.concatLines (
        lib.optional (cfg.userPlugins != { }) "mkdir -p src/userplugins"
        ++ lib.mapAttrsToList (
          name: path:
          "ln -s ${lib.escapeShellArg path} src/userplugins/${lib.escapeShellArg name} && ls src/userplugins"
        ) cfg.userPlugins
      );

      postInstall = (o.postInstall or "") + ''
        cp package.json $out
      '';
    });

  defaultEquicord = applyPostPatch (
    pkgs.callPackage ../pkgs/equicord.nix { unstable = cfg.discord.equicord.unstable; }
  );
in
{
  options.programs.equinix = {
    enable = mkEnableOption "Enables Discord with Equicord";
    discord = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable discord
          Disable to only install Equibop
        '';
      };
      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ../pkgs/discord.nix (
          lib.optionalAttrs (
            pkgs.stdenvNoCC.isLinux && builtins.fromJSON (lib.versions.major lib.version) < 25
          ) { libgbm = pkgs.mesa; }
        );
        description = ''
          The Discord package to use
        '';
      };
      branch = mkOption {
        type = types.enum [
          "stable"
          "ptb"
          "canary"
          "development"
        ];
        default = "stable";
        description = "The Discord branch to use";
      };
      configDir = mkOption {
        type = types.path;
        default =
          let
            branch = config.programs.equinix.discord.branch;
            baseConfigPath =
              if pkgs.stdenvNoCC.isLinux then
                config.xdg.configHome
              else
                "${config.home.homeDirectory}/Library/Application Support";
            branchDirName =
              {
                stable = "discord";
                ptb = "discordptb";
                canary = "discordcanary";
                development = "discorddevelopment";
              }
              .${branch};
          in
          "${baseConfigPath}/${branchDirName}";
        description = "Config path for Discord";
      };
      equicord = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Equicord (for non-equibop)";
        };
        package = mkOption {
          type = types.package;
          default = defaultEquicord;
          description = ''
            The Equicord package to use
          '';
        };
        unstable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable unstable Equicord build from repository's master branch";
        };
      };
      openASAR.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable OpenASAR (for non-equibop)";
      };
      autoscroll.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable middle-click autoscrolling";
      };
      settings = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Settings to be placed in discordConfigDir/settings.json
        '';
      };
    };
    equibop = {
      enable = mkEnableOption ''
        Whether to enable Equibop
      '';
      package = mkOption {
        type = types.package;
        default = pkgs.equibop;
        description = ''
          The Equibop package to use
        '';
      };
      useSystemEquicord = mkOption {
        type = types.bool;
        default = true;
        description = "Use system Equicord package";
      };
      configDir = mkOption {
        type = types.path;
        default = "${
          if pkgs.stdenvNoCC.isLinux then
            config.xdg.configHome
          else
            "${config.home.homeDirectory}/Library/Application Support"
        }/equibop";
        description = "Config path for Equibop";
      };
      settings = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Settings to be placed in equibop.configDir/settings.json
        '';
      };
      state = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Settings to be placed in equibop.configDir/state.json
        '';
      };
      autoscroll.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable middle-click autoscrolling";
      };
    };
    package = mkOption {
      type = with types; nullOr package;
      default = null;
      description = ''
        Deprecated
        The Discord package to use
      '';
    };
    equibopPackage = mkOption {
      type = with types; nullOr package;
      default = null;
      description = ''
        The Equibop package to use
      '';
    };
    configDir = mkOption {
      type = types.path;
      default = "${
        if pkgs.stdenvNoCC.isLinux then
          config.xdg.configHome
        else
          "${config.home.homeDirectory}/Library/Application Support"
      }/Equicord";
      description = "Equicord config directory";
    };
    equibopConfigDir = mkOption {
      type = with types; nullOr path;
      default = null;
      description = "Config path for equibop";
    };
    openASAR.enable = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = "Enable OpenASAR (for non-equibop)";
    };
    quickCss = mkOption {
      type = types.str;
      default = "";
      description = "Equicord quick CSS";
    };
    config = {
      notifyAboutUpdates = mkEnableOption "Notify when updates are available";
      autoUpdate = mkEnableOption "Automatically update Equicord";
      autoUpdateNotification = mkEnableOption "Notify user about auto updates";
      useQuickCss = mkEnableOption "Enable quick CSS file";
      themeLinks = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "A list of links to online Equicord themes";
        example = [ "https://raw.githubusercontent.com/rose-pine/discord/main/rose-pine.theme.css" ];
      };
      enabledThemes = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "A list of themes to enable from themes directory";
      };
      enableReactDevtools = mkEnableOption "Enable React developer tools";
      frameless = mkEnableOption "Make client frameless";
      transparent = mkEnableOption "Enable client transparency";
      winCtrlQ = mkEnableOption "Enable meta + ctrl + Q to close the app";
      disableMinSize = mkEnableOption "Disable minimum window size for client";
      winNativeTitleBar = mkEnableOption "Whether to use the WM native title bar";
      plugins = import ./plugins.nix { inherit lib; };
    };
    equibopConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        additional config to be added to programs.equinix.config
        for Equibop only
      '';
    };
    equicordConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        additional config to be added to programs.equinix.config
        for Equicord only
      '';
    };
    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        additional config to be added to programs.equinix.config
        for both Equicord and Equibop
      '';
    };
    userPlugins =
      let
        regex = "github:([[:alnum:].-]+)/([[:alnum:]/-]+)/([0-9a-f]{40})";
        coerce =
          value:
          let
            matches = builtins.match regex value;
            owner = builtins.elemAt matches 0;
            repo = builtins.elemAt matches 1;
            rev = builtins.elemAt matches 2;
          in
          builtins.fetchGit {
            url = "https://github.com/${owner}/${repo}";
            inherit rev;
          };
      in
      mkOption {
        type = with types; attrsOf (coercedTo (strMatching regex) coerce dop);
        description = "User plugin to fetch and install. Note that any json required must be enabled in extraConfig";
        default = { };
        example = {
          someCoolPlugin = "github:someUser/someCoolPlugin/someHashHere";
        };
      };
    parseRules = {
      upperNames = mkOption {
        type = with types; listOf str;
        description = "option names to become UPPER_SNAKE_CASE";
        default = [ ];
      };
      lowerPluginTitles = mkOption {
        type = with types; listOf str;
        description = "plugins with lowercase names in json";
        default = [ ];
        example = [ "petpet" ];
      };
      fakeEnums = {
        zero = mkOption {
          type = with types; listOf str;
          description = "strings to evaluate to 0 in JSON";
          default = [ ];
        };
        one = mkOption {
          type = with types; listOf str;
          description = "strings to evaluate to 1 in JSON";
          default = [ ];
        };
        two = mkOption {
          type = with types; listOf str;
          description = "strings to evaluate to 2 in JSON";
          default = [ ];
        };
        three = mkOption {
          type = with types; listOf str;
          description = "strings to evaluate to 3 in JSON";
          default = [ ];
        };
        four = mkOption {
          type = with types; listOf str;
          description = "strings to evaluate to 4 in JSON";
          default = [ ];
        };
        # I've never seen a plugin with more than 5 options for 1 setting
      };
    };

    finalPackage = {
      discord = mkOption {
        type = with types; package;
        readOnly = true;
        description = "The final discord package that is created";
      };

      equibop = mkOption {
        type = with types; package;
        readOnly = true;
        description = "The final equibop package that is created";
        default = null;
      };
    };
  };

  config =
    let
      parseRules = cfg.parseRules;
      inherit (pkgs.callPackage ./lib.nix { inherit lib parseRules; })
        mkEquicordCfg
        ;

      equicord = applyPostPatch cfg.discord.equicord.package;

      isQuickCssUsed =
        appConfig:
        (cfg.config.useQuickCss || appConfig ? "useQuickCss" && appConfig.useQuickCss)
        && cfg.quickCss != "";
    in
    mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = !(cfg.discord.equicord.package != defaultEquicord && cfg.discord.equicord.unstable);
            message = "programs.equinix.discord.equicord: Cannot set both 'package' and 'unstable = true'. Choose one or the other.";
          }
        ];

        programs.equinix.finalPackage.discord = 
          cfg.discord.package.override ({
            withEquicord = cfg.discord.equicord.enable;
            withOpenASAR = cfg.discord.openASAR.enable;
            enableAutoscroll = cfg.discord.autoscroll.enable;
            branch = cfg.discord.branch;
            inherit equicord;
          });

        programs.equinix.finalPackage.equibop = 
          cfg.equibop.package.override {
            # withSystemEquicord = cfg.equibop.useSystemEquicord;
            withMiddleClickScroll = cfg.equibop.autoscroll.enable;
            inherit equicord;
          };
        
        home.packages = [
          (mkIf cfg.discord.enable cfg.finalPackage.discord)
          (mkIf cfg.vesktop.enable cfg.finalPackage.vesktop)
        ];
      }
      (mkIf cfg.discord.enable (mkMerge [
        {
          home.activation.disableDiscordUpdates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            set -euo pipefail
            mkdir -p "${cfg.discord.configDir}"
            config_dir="${cfg.discord.configDir}"
            if [ -f "$config_dir/settings.json" ]; then
              jq '. + {"SKIP_HOST_UPDATE": true}' "$config_dir/settings.json" > "$config_dir/settings.json.tmp" && mv "$config_dir/settings.json.tmp" "$config_dir/settings.json"
            else
              echo '{"SKIP_HOST_UPDATE": true}' > "$config_dir/settings.json"
            fi
          '';
          home.activation.fixDiscordModules = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            set -euo pipefail

            config_base="${
              if pkgs.stdenvNoCC.isDarwin then
                "${config.home.homeDirectory}/Library/Application Support"
              else
                "${config.xdg.configHome}"
            }"

            for branch in discord discord-ptb discord-canary discord-development; do
              config_dir="$config_base/$branch"
              [ ! -d "$config_dir" ] && continue
              cd "$config_dir" || continue
              # Find versioned directories (e.g., 0.0.89, 0.0.90)
              versions=($(ls -1d [0-9]*.[0-9]*.[0-9]* 2>/dev/null | sort -V || true))
              n=''${#versions[@]}
              if [ "$n" -ge 2 ]; then
                prev="''${versions[$((n-2))]}"
                curr="''${versions[$((n-1))]}"
                prev_modules="$config_dir/$prev/modules"
                curr_modules="$config_dir/$curr/modules"
                # If curr modules is missing or only has 'pending'
                if [ ! -d "$curr_modules" ] || [ "$(ls -A "$curr_modules" 2>/dev/null | grep -v '^pending$' | wc -l)" -eq 0 ]; then
                  if [ -d "$prev_modules" ]; then
                    echo "Copying Discord modules for $branch from $prev to $curr"
                    rm -rf "$curr_modules"
                    cp -a "$prev_modules" "$curr_modules"
                  fi
                fi
              fi
            done
          '';
        }
        # QuickCSS
        (mkIf (isQuickCssUsed cfg.equicordConfig) {
          home.file."${cfg.configDir}/settings/quickCss.css".text = cfg.quickCss;
        })
        # Equicord Settings
        {
          home.file."${cfg.configDir}/settings/settings.json".text = builtins.toJSON (
            mkEquicordCfg (recursiveUpdateAttrsList [
              cfg.config
              cfg.extraConfig
              cfg.equicordConfig
            ])
          );
        }
        # Client Settings
        (mkIf (cfg.discord.settings != { }) {
          home.file."${cfg.discord.configDir}/settings.json".text = builtins.toJSON (
            mkEquicordCfg cfg.discord.settings
          );
        })
      ]))
      (mkIf cfg.equibop.enable (mkMerge [
        # QuickCSS
        (mkIf (isQuickCssUsed cfg.equibopConfig) {
          home.file."${cfg.equibop.configDir}/settings/quickCss.css".text = cfg.quickCss;
        })
        # Equicord Settings
        {
          home.file."${cfg.equibop.configDir}/settings/settings.json".text = builtins.toJSON (
            mkEquicordCfg (recursiveUpdateAttrsList [
              cfg.config
              cfg.extraConfig
              cfg.equibopConfig
            ])
          );
        }
        # Equibop Client Settings
        (mkIf (cfg.equibop.settings != { }) {
          home.file."${cfg.equibop.configDir}/settings.json".text = builtins.toJSON (
            mkEquicordCfg cfg.equibop.settings
          );
        })
        # Equibop Client State
        (mkIf (cfg.equibop.state != { }) {
          home.file."${cfg.equibop.configDir}/state.json".text = builtins.toJSON (
            mkEquicordCfg cfg.equibop.state
          );
        })
      ]))
      # Warnings
      {
        warnings = import ../warnings.nix { inherit cfg mkIf; };
      }
    ]);
}
