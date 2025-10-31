{
  flake.nixosModules.base =
    { lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        jj.user.name = mkOpt (types.nullOr types.str) null "The username to use when creating jj commits";
        jj.user.email = mkOpt (types.nullOr types.str) null "The email to use when creating jj commits";

        jj.extraConfig =
          mkOpt (types.attrsOf types.anything) { }
            "Extra properties to set in the jj config";
      };
    };

  flake.nixosModules.jj =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        jujutsu
        lazyjj

        difftastic
      ];

      environment.shellAliases = {
        jjs = "jj status";
        jjd = "jj describe";
        jjdf = "jj diff";
        jjb = "jj bookmark move --from @- --to @";
        jjp = "jj git push";
      };

      prefs.nushell.excludedAliases = [ "jjn" ];
      prefs.nushell.extraConfig = [
        ''
          def jjn --wrapped [...args] {
            jj new ...$args; jj bookmark move --from @- --to @ ...$args
          }
        ''
      ];

      hjem.users.${config.prefs.user.name} = {
        xdg.config.files."jj/config.toml".source = (pkgs.formats.toml { }).generate "config.toml" (
          {
            ui.default-command = [
              "log"
              "-r"
              "all()"
            ];
            ui.diff-formatter = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];

            git.push-new-bookmarks = true;
          }
          // (lib.optionalAttrs (config.prefs.jj.user.name != null) {
            user.name = config.prefs.jj.user.name;
          })
          // (lib.optionalAttrs (config.prefs.jj.user.email != null) {
            user.email = config.prefs.jj.user.email;
          })
          // config.prefs.jj.extraConfig
        );
      };
    };
}
