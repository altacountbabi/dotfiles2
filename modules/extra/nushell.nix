{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "nushell" {
    path = "nushell";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.nushell "The package to use for nushell";

        extraConfig = mkOpt (types.listOf types.str) [ ] "Extra items to add to the config";

        excludedAliases =
          mkOpt (types.listOf types.str) [ ]
            "Aliases from `environment.shellAliases` to exclude from the config";

        include = mkOpt (types.listOf types.path) [ ] "List of paths to source into the env config";
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
        inherit (lib)
          mkForce
          getExe
          filterAttrs
          mapAttrsToList
          concatStringsSep
          elem
          isString
          isPath
          ;

        wrapped =
          (inputs.wrappers.wrapperModules.nushell.apply {
            inherit pkgs;
            package = mkForce cfg.package;

            "env.nu".content =
              let
                include = cfg.include |> map (x: "source ${x}") |> concatStringsSep "\n";
                aliases =
                  config.environment.shellAliases
                  |> filterAttrs (k: v: v != "" && !(elem k cfg.excludedAliases))
                  |> mapAttrsToList (k: v: "alias ${k} = ${v}")
                  |> concatStringsSep "\n";
                autostart =
                  let
                    cmd =
                      v:
                      if isString v then
                        "${getExe pkgs.bash} -c \"${v}\""
                      else if isPath v then
                        "${v}"
                      else
                        "${getExe v}";
                  in
                  config.prefs.autostart-shell |> map cmd |> concatStringsSep "\n";

                extraConfig = cfg.extraConfig |> concatStringsSep "\n";
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
                  ${pkgs.fish |> getExe} --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
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

            "config.nu".content = # nu
              ''
                $env.config = {
                  show_banner: false

                  ls: {
                    use_ls_colors: true
                    clickable_links: false
                  }

                  rm: {
                    always_trash: false
                  }

                  table: {
                    mode: rounded
                    index_mode: auto
                    show_empty: false
                    padding: { left: 1, right: 1 }
                    trim: {
                      methodology: wrapping
                      wrapping_try_keep_words: true
                      truncating_suffix: "..."
                    }
                    header_on_separator: false
                  }

                  error_style: "fancy"

                  explore: {
                    status_bar_background: { fg: "#1D1F21", bg: "#C4C9C6" },
                    command_bar_text: { fg: "#C4C9C6" },
                    highlight: { fg: "black", bg: "yellow" },
                    status: {
                      error: { fg: "white", bg: "red" },
                      warn: {}
                      info: {}
                    },
                    table: {
                      split_line: { fg: "#404040" },
                      selected_cell: { bg: light_blue },
                      selected_row: {},
                      selected_column: {},
                    },
                  }

                  history: {
                    max_size: 100_000
                    sync_on_enter: true
                    file_format: "plaintext"
                    isolation: false
                  }

                  completions: {
                    case_sensitive: false
                    quick: true
                    partial: true
                    algorithm: "fuzzy"
                    use_ls_colors: true
                  }

                  filesize: {
                    unit: "metric" # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
                  }

                  cursor_shape: {
                    emacs: line
                    vi_insert: line
                    vi_normal: line
                  }

                  footer_mode: 25
                  float_precision: 2
                  buffer_editor: ""
                  use_ansi_coloring: true
                  bracketed_paste: true
                  edit_mode: emacs
                  render_right_prompt_on_last_line: false
                  use_kitty_protocol: false
                  highlight_resolved_externals: false
                  recursion_limit: 50

                  plugins: {}

                  plugin_gc: {
                    default: {
                      enabled: true
                      stop_after: 10sec
                    }
                  }

                  hooks: {
                    pre_prompt: [{ null }]
                    pre_execution: [{ null }]
                    env_change: {
                      PWD: [{|before, after| null }]
                    }
                    display_output: "if (term size).columns >= 100 { table -e } else { table }"
                    command_not_found: { null }
                  }
                }
              '';
          }).wrapper;
      in
      {
        environment.systemPackages = with pkgs; [
          carapace
          wrapped
        ];

        prefs.user.shell = wrapped;

        # Remove pre-defined shell aliases from nixpkgs but still allow for shell aliases in this config.
        environment.shellAliases = {
          ls = "";
          ll = "";
          l = "";
        };
      };
  };
}
