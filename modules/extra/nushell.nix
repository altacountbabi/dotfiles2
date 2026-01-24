{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.nushell";

    opts =
      {
        pkgs,
        lib,
        mkOpt,
        types,
        ...
      }:
      let
        nushellValue =
          let
            valueType = types.nullOr (
              types.oneOf [
                (lib.mkOptionType {
                  name = "nushell";
                  description = "Nushell inline value";
                  descriptionClass = "name";
                  check = lib.isType "nushell-inline";
                })
                types.bool
                types.int
                types.float
                types.str
                types.path
                (
                  types.attrsOf valueType
                  // {
                    description = "attribute set of Nushell values";
                    descriptionClass = "name";
                  }
                )
                (
                  types.listOf valueType
                  // {
                    description = "list of Nushell values";
                    descriptionClass = "name";
                  }
                )
              ]
            );
          in
          valueType;
      in
      {
        enable = mkOpt types.bool false "Enable nushell";

        package = mkOpt types.package pkgs.nushell "The package to use for nushell";

        extraConfig = mkOpt (types.listOf types.str) [ ] "Extra items to add to the config";

        excludedAliases = mkOpt (types.listOf types.str) [ ] ''
          Aliases from `environment.shellAliases` to exclude from the config.
          This can be useful if a specific alias has posix shell syntax or if there's something better than an alias that nushell can use.
        '';

        include = mkOpt (types.listOf types.path) [ ] "List of paths to source into the env config";

        settings = mkOpt (types.attrsOf nushellValue) { } ''
          Nushell settings. These will be flattened and assigned one by one to `$env.config` to avoid overwriting the default or existing options.

          For example:
          ```nix
          {
            show_banner = false;
            completions.external = {
              enable = true;
              max_results = 200;
            };
          }
          ```
          becomes:
          ```nushell
          $env.config.completions.external.enable = true
          $env.config.completions.external.max_results = 200
          $env.config.show_banner = false
          ```
        '';
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        wrapped =
          (inputs.wrappers.wrapperModules.nushell.apply {
            inherit pkgs;
            package = lib.mkForce cfg.package;

            "env.nu".content =
              let
                include = cfg.include |> map (x: "source ${x}") |> lib.concatStringsSep "\n";
                aliases =
                  config.environment.shellAliases
                  |> lib.filterAttrs (k: v: v != "" && !(lib.elem k cfg.excludedAliases))
                  |> lib.mapAttrsToList (k: v: "alias ${k} = ${v}")
                  |> lib.concatStringsSep "\n";
                autostart =
                  let
                    cmd =
                      v:
                      if lib.isString v then
                        "${lib.getExe pkgs.bash} -c \"${v}\""
                      else if lib.isPath v then
                        "${v}"
                      else
                        "${lib.getExe v}";
                  in
                  config.prefs.autostart-shell |> map cmd |> lib.concatStringsSep "\n";

                extraConfig = cfg.extraConfig |> lib.concatStringsSep "\n";
              in
              # nu
              ''
                source ${../pkgs/scripts/nushell-lib.nu}

                ${include}

                ${aliases}
                ${autostart}

                ${extraConfig}

                alias ffmpeg = ffmpeg -hide_banner
                alias ffprobe = ffprobe -hide_banner

                alias cal = cal --week-start mo

                def --env mkcd [dir: path] {
                  mkdir $dir; cd $dir
                }

                def psn [name: string] {
                  ps | where ($it.name | str contains $name)
                }

                # Single command to cat files and list directories
                def l [...paths] {
                  if ($paths | is-empty) {
                    ls
                  } else {
                    for p in $paths {
                      if ($p | path type) == 'file' {
                        cat $p
                      } else if ($p | path type) == 'dir' {
                        print (ls $p | table) -n
                      } else {
                        print $"(ansi red)error:(ansi reset) ($p) not found"
                      }
                    }
                  }
                }

                # Resolve a symlink for a file
                def "resolve link" [path: path] {
                  let original = (ls -l $path | get target.0);
                  cp $original .unlink-tmp
                  mv .unlink-tmp $path

                  if ($original | into string | str starts-with "/nix/store") {
                    chmod +w $path
                  }
                }

                # Show the status of modules in the Linux Kernel
                def lsmod [
                  --split-mods # Split the comma-separated `mods` field
                ]: nothing -> table {
                  let result = ^lsmod
                    | lines
                    | skip 1
                    | parse --regex '^(?<name>\S+)\s+(?<size>\d+)\s+(?<count>\d+)\s+(?<mods>.+)$'
                    | update size {|x| $x.size | into filesize }
                    | update count {|x| $x.count | into int }

                  if $split_mods {
                    $result | update mods {|x| $x.mods | split row "," }
                  } else {
                    $result
                  }
                }

                $env.PROMPT_COMMAND = {||
                  let dir = match (do -i { $env.PWD | path relative-to $nu.home-path }) {
                    null => $env.PWD
                    "" => "~"
                    $relative_pwd => ([~ $relative_pwd] | path join)
                  }

                  let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
                  let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
                  let path_segment = $"($path_color)($dir)(ansi reset)"
                  let shell_name = if ($env.name? | is-not-empty) {
                    $"(ansi blue_bold)\((if ($env.name == "devenv-shell-env") { "devenv" } else { $env.name })\)(ansi reset) "
                  } else { "" }

                  $"($shell_name)($path_segment)" | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
                }

                $env.PROMPT_COMMAND_RIGHT = {|| "" }

                $env.PROMPT_INDICATOR = {|| "> " }
                $env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
                $env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
                $env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

                $env.ENV_CONVERSIONS = {
                  "PATH": {
                    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
                    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
                  }
                  "Path": {
                    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
                    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
                  }
                }

                $env.NU_LIB_DIRS = [
                  ($nu.default-config-dir | path join 'scripts')
                ]

                $env.NU_PLUGIN_DIRS = [
                  ($nu.default-config-dir | path join 'plugins')
                ]

                let carapace_completer = {|spans|
                  carapace $spans.0 nushell ...$spans | from json
                }

                let fish_completer = {|spans|
                  ${pkgs.fish |> lib.getExe} --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
                    | from tsv --flexible --noheaders --no-infer
                    | rename value description
                    | update value {|row|
                      let value = $row.value
                      let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
                      if ($need_quote and ($value | path exists)) {
                        let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
                        $'"($expanded_path | str replace --all "\"" "\\\"")"'
                      } else {$value}
                    }
                }

                let external_completer = {|spans|
                  let expanded_alias = scope aliases
                    | where name == $spans.0
                    | get -o 0.expansion

                  let spans = if $expanded_alias != null {
                    $spans
                      | skip 1
                      | prepend ($expanded_alias | split row ' ' | take 1)
                  } else {
                    $spans
                  }

                  match $spans.0 {
                    # carapace completions are incorrect for nu
                    nu => $fish_completer
                    # fish completes commits and branch names in a nicer way
                    git => $fish_completer
                    _ => $carapace_completer
                  } | do $in $spans
                }

                $env.config.completions.external = {
                  enable: true
                  completer: $external_completer
                }
              '';

            "config.nu".content =
              let
                flattenSettings =
                  let
                    joinDot = a: b: "${if a == "" then "" else "${a}."}${b}";
                    unravel =
                      prefix: value:
                      if lib.isAttrs value && !lib.isNushellInline value then
                        lib.concatMap (key: unravel (joinDot prefix key) value.${key}) (builtins.attrNames value)
                      else
                        [ (lib.nameValuePair prefix value) ];
                  in
                  unravel "";
                mkLine =
                  { name, value }:
                  ''
                    $env.config.${name} = ${lib.toNushell { } value}
                  '';
                settingsLines = lib.concatMapStrings mkLine (flattenSettings cfg.settings);
              in
              lib.mkIf (cfg.settings != { }) settingsLines;
          }).wrapper;
      in
      {
        config = lib.mkIf cfg.enable {
          environment.systemPackages = with pkgs; [
            carapace
            wrapped
          ];

          programs.nushell = {
            settings = lib.mkDefault {
              show_banner = false;

              ls = {
                use_ls_colors = true;
                clickable_links = false;
              };

              rm.always_trash = false;

              table = {
                mode = "rounded";
                index_mode = "auto";
                show_empty = false;
                padding = {
                  left = 1;
                  right = 1;
                };
                trim = {
                  methodology = "wrapping";
                  wrapping_try_keep_words = true;
                  truncating_suffix = "...";
                };
                header_on_separator = false;
              };

              error_style = "fancy";

              explore = {
                status_bar_background = {
                  fg = "#1D1F21";
                  bg = "#C4C9C6";
                };
                command_bar_text.fg = "#C4C9C6";
                highlight = {
                  fg = "black";
                  bg = "yellow";
                };
                status = {
                  error = {
                    fg = "white";
                    bg = "red";
                  };
                  warn = { };
                  info = { };
                };
                table = {
                  split_line.fg = "#404040";
                  selected_cell.bg = "light_blue";
                  selected_row = { };
                  selected_column = { };
                };
              };

              history = {
                max_size = 100000;
                sync_on_enter = true;
                file_format = "plaintext";
                isolation = false;
              };

              completions = {
                case_sensitive = false;
                quick = true;
                partial = true;
                algorithm = "fuzzy";
                use_ls_colors = true;
              };

              filesize.unit = "metric";

              cursor_shape = {
                emacs = "line";
                vi_insert = "line";
                vi_normal = "line";
              };

              footer_mode = 25;
              float_precision = 2;
              buffer_editor = "";
              use_ansi_coloring = true;
              bracketed_paste = true;
              edit_mode = "emacs";
              render_right_prompt_on_last_line = false;
              use_kitty_protocol = false;
              highlight_resolved_externals = false;
              recursion_limit = 50;

              plugins = { };

              plugin_gc.default = {
                enabled = true;
                stop_after = lib.mkNushellInline "10sec";
              };

              hooks = {
                pre_prompt = lib.mkNushellInline "[{ null }]";
                pre_execution = lib.mkNushellInline "[{ null }]";
                env_change.PWD = lib.mkNushellInline "[{|before; after| null }]";
                display_output = "if (term size).columns >= 100 { table -e } else { table }";
                command_not_found = lib.mkNushellInline "{ null }";
              };
            };
          };

          prefs.user.shell = wrapped;

          # Remove pre-defined shell aliases from nixpkgs
          environment.shellAliases = {
            ls = "";
            ll = "";
            l = "";
          };
        };
      };
  };
}
