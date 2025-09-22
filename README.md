# equinix

<sup>not to be confused with Equinix Inc.</sup>

> [!NOTE]
> This is a fork of [nixcord] made for Equicord/Equibop instead.
> 99% of the code here is not made by me.
> please support the contributers of nixcord for their hard work 🙂

Manage [Equicord] settings and plugins
declaratively with Nix!

This repo can be used to make a clean looking config for Equicord without needing
to pollute system config with needless utils to override the discord pacakge,
and write ugly JSON code directly in .nix files.

> [!WARNING]
> Using equinix means comitting to declaratively installing plugins. This means
> that the normal "plugins" menu in Equicord will not apply permenant changes.
> You can still use it to test out plugins but on restarting the client, any
> changes will be gone.
>
> The primary goal of this project is to reduce the need to configure Equicord
> again on every new system you install.

## How to use equinix

Currently equinix only supports nix flakes as a [Home Manager] module.

First, you need to import the module:

```nix
# flake.nix
{
  # ...
  inputs.equinix = {
    url = "github:not-a-cowfr/equinix";
  };
  # ...
}
```

Next you'll have to import the home-manager module into flake.nix. This step
varies depending on how you have home-manager installed. Here is a simple
example of home-manager installed as a nixos module:

```nix
# flake.nix
{
  # ...
  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jdoe = import ./home.nix;

            home-manager.sharedModules = [
              inputs.equinix.homeModules.equinix
            ];
          }
        ];
      };
    };
  };
  # ...
}
```

or to install to a specific home

```nix
# home.nix
{
  # ...
  imports = [
    inputs.equinix.homeModules.equinix
  ];
  # ...
}
```

After installation, you can easily start editing config

## Configuration

This is an example home-manager configuration using equinix

```nix
# home.nix
{
  # ...
  programs.equinix = {
    enable = true;          # Enable equinix (It also installs Discord)
    equibop.enable = true;  # Equibop
    quickCss = "some CSS";  # quickCSS file
    config = {
      useQuickCss = true;   # use out quickCSS
      themeLinks = [        # or use an online theme
        "https://raw.githubusercontent.com/link/to/some/theme.css"
      ];
      frameless = true;                   # Set some Equicord options
      plugins = {
        hideAttachments.enable = true;    # Enable a Equicord plugin
        ignoreActivities = {              # Enable a plugin and set some options
          enable = true;
          ignorePlaying = true;
          ignoreWatching = true;
          ignoredActivities = [ "someActivity" ];
        };
      };
    };
    extraConfig = {
      # Some extra JSON config here
      # ...
    };
  };
  # ...
}
```

## Documentation

You can find the rendered docs at: https://not-a-cowfr.github.io/equinix/

Alternatively, you can build them locally with `nix build .#docs-html` and view
them with `nix run .#docs`

You can also export all options to JSON using `nix build .#docs-json`

## Special Thanks

Special Thanks to [Equicord],
[nixcord](https://github.com/KaylorBen/nixcord),
[Home Manager], and
[Nix](https://nixos.org/) and all the contributers behind them. Without them,
this project would not be possible.

## Disclaimer

Using Equicord violates Discord's terms of service.
Read more about it at [Equicord] GitHub.

[Equicord]: https://github.com/Equicord/Equicord
[Home Manager]: https://github.com/nix-community/home-manager
