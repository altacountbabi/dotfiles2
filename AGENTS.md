This is a NixOS config using flake-parts

## Structure
No home management system is used, the way user apps are configured are either through wrappers or by taking advantage of `/etc/xdg` which can be written to using built-in nixos options

- `./modules/profiles.nix` - List of profiles that hosts can import
- `./modules/hosts/` - Hosts
- `./modules/pkgs/` - Custom packages
- `./modules/base/` - Base modules
- `./modules/extra/desktop` - Modules to configure the desktop
- `./modules/extra/apps` - Modules to configure graphical apps
- `./modules/extra/vcs` - Extra modules to configure VCSs
- `./modules/extra/browsers` - Browsers
- `./modules/extra/terminals` - Terminals
- `./modules/extra/iso` - Modules to generate an ISO image

## Rules
- JJ VCS is used, not git
- Never push commits, only work locally.
- To check if the config builds, use the command: `nom build .#iso`
- Module options are added on top of the `base` `nixosModule` so that even if the implementation module isn't imported, the options and their defaults will still exist.
- Use `lib.mkOpt` instead of `lib.mkOption`, see ./lib/options.nix for more details on that
- Module options are defined under the `.prefs` namespace, in this format:
  ```nix
  options.prefs = {
    foo.bar = mkOpt ...;
  };
  ```
  examples of doing it wrong:
  ```nix
  options.prefs.foo.bar = mkOpt ...;
  ```
  ```nix
  options.prefs.foo = {
    bar = mkOpt ...;
  };
  ```
  This rule applies no matter how many options `foo` has, the only time this can be ignored is if theres multiple sub-namespaces under the `.prefs` namespace, both with lots of options:
  ```nix
  options.prefs = {
    foo = {
      bar = mkOpt ...;
      bar = mkOpt ...;
    };

    baz = {
      bar = mkOpt ...;
      bar = mkOpt ...;
    };
  };
  ```
- Use this pattern when using more than 1 item from `lib`:
```nix
}:
let
  inherit (lib) mkOpt types;
in
...
```
- Since options are (always) defined under the `base` module, you don't need to place the impl module's config options under `config = { ... }`
- Use the pipeline operator if the function name or args is reasonably long
- Sort module args by length:
```nix
{
  config,
  lib,
  pkgs,
  ...
}:
```
->
```nix
{
  config,
  pkgs,
  lib,
  ...
}:
```
- Every file (except for those starting with `_`) is imported automatically with `import-tree`, no need to add modules to any imports list
