{
  flake.nixosModules.jj =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) optionalAttrs mkOption types;
    in
    {
      options.prefs = {
        jj.user.name = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        jj.user.email = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        jj.extraConfig = mkOption {
          type = types.attrsOf types.anything;
          default = { };
        };
      };

      config = {
        environment.systemPackages = with pkgs; [
          jujutsu
          lazyjj

          difftastic
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
            // (optionalAttrs (config.prefs.jj.user.name != null) { user.name = config.prefs.jj.user.name; })
            // (optionalAttrs (config.prefs.jj.user.email != null) { user.email = config.prefs.jj.user.email; })
            // config.prefs.jj.extraConfig
          );
        };
      };
    };
}
