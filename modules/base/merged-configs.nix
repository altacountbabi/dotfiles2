{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    opts =
      {
        pkgs,
        lib,
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
              overlay = mkOpt' (attrsOf anything) "Content to overlay onto `cfg.path`";

              format =
                let
                  formats =
                    self.lib.nushellRun {
                      inherit pkgs;
                      name = "merged-configs-formats";
                      text = # nushell
                        ''
                          def get-cmds [name: string]: nothing -> list<string> {
                            scope commands
                              | where ($it.name | str starts-with $name)
                              | get name
                              | each {|x| $x | str replace $name "" }
                              | uniq
                          }

                          let from = get-cmds "from "
                          let to = get-cmds "to "

                          $from
                            | where ($it in $to)
                            | to json
                            | save -f $env.out
                        '';
                    }
                    |> builtins.readFile
                    |> builtins.fromJSON
                    |> lib.filter (x: lib.elem x (lib.attrNames pkgs.formats));
                in
                mkOpt (enum formats) "json" "Which format the config uses";

              nixGenOpts = mkOpt (attrsOf anything) { } ''
                List of options to pass to `pkgs.formats.\${cfg.format}` when generating the specified format from `\${cfg.overlay}`
              '';
              deOpts = mkOpt str "" "List of options to pass when deserializing in nushell";
              serOpts = mkOpt str "" "List of options to pass when serializing in nushell";
            };
          }))
        ) { } "List of configs to merge";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
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
                              let overlay = open -r $overlay | from ${v.format} ${v.deOpts}
                              let config = try { open -r $path } catch { "{}" } | from ${v.format} ${v.deOpts}

                              mkdir ($path | path dirname)

                              let new_config = $config | merge deep $overlay
                              let fmt = $new_config | to ${v.format} ${v.serOpts}

                              $fmt | save -f $path
                            }
                          '';
                      }
                      |> lib.getExe;
                    overlay = (pkgs.formats.${v.format} v.nixGenOpts).generate "${k}-config" v.overlay;
                  in
                  {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart = "${mergeConfig} ${v.path} ${overlay}";
                  };
              };
            }
          );
      };
  };
}
