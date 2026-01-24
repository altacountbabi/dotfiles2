{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    opts =
      {
        pkgs,
        mkOpt,
        mkOpt',
        types,
        ...
      }:
      {
        merged-configs = mkOpt (
          with types;
          (attrsOf (submodule {
            options = {
              path = mkOpt' str "Path to config";
              overlay = mkOpt' (attrsOf (pkgs.formats.json { }).type) "JSON to overlay onto `path`";
              formatting = {
                indent = mkOpt int 2 "JSON Indentation";
                raw = mkOpt bool false "Whether to format the JSON at all";
              };
            };
          }))
        ) { } "List of configs to merge (json only)";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        mergeConfig =
          self.lib.nushellScript {
            inherit pkgs;
            name = "merge-config";
            text = # nushell
              ''
                def main [
                  path: path
                  overlay: path
                  --indent: number
                  --raw
                ] {
                  let overlay = open -r $overlay | from json
                  let config = try { open -r $path } catch { "{}" } | from json

                  mkdir ($path | path dirname)

                  let new_config = $config | merge deep $overlay
                  let json = if $raw {
                    $new_config | to json --raw
                  } else {
                    $new_config | to json --indent $indent
                  }

                  $json | save -f $path
                }
              '';
          }
          |> lib.getExe;
      in
      {
        systemd.user.services =
          cfg.merged-configs
          |> lib.concatMapAttrs (
            k: v: {
              "${k}-config" = {
                after = [ "default.target" ];
                wantedBy = [ "default.target" ];
                serviceConfig =
                  let
                    overlay = (pkgs.formats.json { }).generate "${k}-config" v.overlay;
                  in
                  {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart = "${mergeConfig} ${v.path} ${overlay} --indent ${toString v.formatting.indent} ${lib.optionalString (v.formatting.raw) "--raw"}";
                  };
              };
            }
          );
      };
  };
}
