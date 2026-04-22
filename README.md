# Nixer

This repository contains nix configuration for my NixOS server.

## Using

Since some of the projects that are deployed are private, machine that evaluates this config needs
access to my private git stuff. Easiest way of doing this, is by running `nixos-rebuild` on my dev machine,
which has all the SSH keys set up, and using the remote builder functionality. Example command is:

```sh
nixos-rebuild switch --flake '.#nixer' --build-host root@116.202.25.234 --target-host root@116.202.25.234
```

Or, if you are on linux, you can just deploy it somewhere:

```sh
nixos-rebuild switch --flake '.#nixer' --target-host root@116.202.25.234
```
