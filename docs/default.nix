# Credit to: https://github.com/nix-community/plasma-manager/blob/b7697abe89967839b273a863a3805345ea54ab56/docs/default.nix#L55
{ pkgs, lib, ... }:
let
  inherit (lib) mkDefault;

  dontCheckModules = {
    _module.check = false;
  };

  # Minimal Home Manager configuration for generating docs
  baseHMConfig =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      visible = false;
    in
    {
      options = {
        home.homeDirectory = lib.mkOption {
          inherit visible;
          type = lib.types.path;
          default = "/home/user";
          description = "User's home directory";
        };
        xdg.configHome = lib.mkOption {
          inherit visible;
          type = lib.types.path;
          default = "/home/user/.config";
          description = "XDG config directory";
        };
      };
      config = {
        home.homeDirectory = mkDefault "/home/user";
        xdg.configHome = mkDefault "/home/user/.config";
      };
    };

  modules = [
    baseHMConfig
    ../modules/hm-module.nix
    dontCheckModules
  ];

  githubDeclaration = user: repo: branch: subpath: {
    url = "https://github.com/${user}/${repo}/blob/${branch}/${subpath}";
    name = "<${repo}/${subpath}>";
  };

  equinixPath = toString ./..;

  transformOptions =
    opt:
    opt
    // {
      declarations = (
        map (
          decl:
          if (lib.hasPrefix equinixPath (toString decl)) then
            (githubDeclaration "not-a-cowfr" "equinix" "main" (
              lib.removePrefix "/" (lib.removePrefix equinixPath (toString decl))
            ))
          else
            decl
        ) opt.declarations
      );
    };

  buildOptionsDocs = (
    args@{ modules, ... }:
    let
      opts =
        (lib.evalModules {
          inherit modules;
          class = "homeManager";
          specialArgs = { inherit pkgs; };
        }).options;
      options = builtins.removeAttrs opts [ "_module" ];
    in
    pkgs.buildPackages.nixosOptionsDoc {
      inherit options;
      inherit transformOptions;
      warningsAreErrors = false;
    }
  );

  equinixOptionsDoc = buildOptionsDocs { inherit modules; };

  equinix-options = pkgs.callPackage ./equinix-options.nix {
    nixos-render-docs = pkgs.nixos-render-docs;
    equinix-options = equinixOptionsDoc.optionsJSON;
    revision = "latest";
  };
in
{
  html = equinix-options;
  json = equinixOptionsDoc.optionsJSON;
}
