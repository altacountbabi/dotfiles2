{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "jj" {
    path = "jj";

    opts =
      { mkOpt, types, ... }:
      {
        user.name = mkOpt (types.nullOr types.str) null "The username to use when creating jj commits";
        user.email = mkOpt (types.nullOr types.str) null "The email to use when creating jj commits";

        extraConfig = mkOpt (types.attrsOf types.anything) { } "Extra properties to set in the jj config";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        wrapped =
          (inputs.wrappers.wrapperModules.jujutsu.apply {
            inherit pkgs;
            settings = {
              ui.default-command = [
                "log"
                "-r"
                "all()"
              ];
              ui.diff-formatter = [
                "${pkgs.difftastic |> lib.getExe}"
                "--color=always"
                "$left"
                "$right"
              ];

              git.push-new-bookmarks = true;
            }
            // (lib.optionalAttrs (cfg.user.name != null) {
              user.name = cfg.user.name;
            })
            // (lib.optionalAttrs (cfg.user.email != null) {
              user.email = cfg.user.email;
            })
            // cfg.extraConfig;
          }).wrapper;
      in
      {
        environment.systemPackages = with pkgs; [
          wrapped
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
          # nushell
          ''
            def jjn --wrapped [...args] {
              jj new ...$args; jj bookmark move --from @- --to @ ...$args
            }
          ''
        ];
      };
  };
}
