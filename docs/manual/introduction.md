# Introduction {#sec-introduction}

equinix is a comprehensive Discord management system for Nix/NixOS that integrates Discord, Equicord, and Equibop into your system configuration. It provides a seamless way to manage Discord clients with customizations through Home Manager.

## What is equinix? {#what-is-equinix}

equinix allows you to:

- **Install and manage Discord variants**: Support for Discord stable, PTB, canary, and development branches
- **Integrate Equicord**: Automatically apply Equicord modifications to Discord for enhanced functionality
- **Use Equicord**: A cross-platform Discord client that supports more features than the official client
- **Manage user plugins**: Easily add and configure custom Equicord plugins
- **Declarative configuration**: All settings managed through Nix configuration files

## Getting Started {#getting-started}

To start using equinix, add it to your Home Manager configuration:

```nix
{
  programs.equinix = {
    enable = true;
    discord.enable = true;
    equibop.enable = true;
  };
}
```

This will install Discord with Equicord and Equibop with sensible defaults. For more detailed configuration options, see the [Configuration Options](#sec-options) section.
