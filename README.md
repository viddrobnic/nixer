# Nixer

This repository contains nix configuration for my NixOS server.

## Using

Since some of the projects that are deployed are private, machine that evaluates this config needs
access to my private git stuff. Easiest way of doing this, is by running `nixos-rebuild` on my dev machine,
which has all the SSH keys set up, and using the remote builder functionality. Example command is:

```sh
nixos-rebuild switch --flake '.#nixer' --build-host root@116.202.25.234 --target-host root@116.202.25.234 --ask-sudo-password
```

Or, if you are on linux, you can just deploy it somewhere:

```sh
nixos-rebuild switch --flake '.#nixer' --target-host nixer --ask-sudo-password
```

## Manual Things

Some things still have to be done manually instead of declarative. Most of the things are secrets:

- set `root` password during install
- set `vidd` password
- for `sparovec` and `lshop` admin user might have to be created manually
- for `forgejo` registration has to be enabled so that admin user can be created. After that, registration
  should be disabled!

## Note

When building on my tower, `--max-jobs 8 --cores 0` options yield fastest nix builds.

## License

This software is licensed under [GNU GPL v3 license](LICENSE).
