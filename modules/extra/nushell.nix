{
  flake.nixosModules.nushell =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkOpt types;
    in
    {
      options.prefs = {
        nushell.package = mkOpt types.package pkgs.nushell "The package to use for nushell";
        nushell.aliases = mkOpt (types.attrsOf types.str) { } "Which alises to add to the nushell config";
        nushell.configureRoot = mkOpt types.bool true "Whether to configure nushell for the root user";
      };

      config =
        let
          userConf = {
            xdg.config.files."nushell/env.nu".text = # nu
              ''
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

                alias cat = bat
                alias df = duf
                alias search = nix-search
                alias tree = tree -lC # Make `tree` follow symlinks and always use colors
                alias less = less -R # make `less` show colors
                alias clone = git clone --depth 1 # Shallow git clone
                alias shell = nix-shell --command "nu"
                alias lg = lazygit
                alias switch = nh os switch

                alias ffmpeg = ffmpeg -hide_banner
                alias ffprobe = ffprobe -hide_banner

                alias cal = cal --week-start mo

                alias ns = nom-shell -p --command "nu"
                def nsr [pkg] {
                  nix run $"nixpkgs#($pkg)" --log-format internal-json -v o+e>| nom --json
                }

                def --env mkcd [dir: path] {
                  mkdir $dir; cd $dir
                }

                def psn [name: string] {
                  ps | where ($it.name | str contains $name)
                }

                # Alias to helix
                def v [...args] {
                  if ($args | is-empty) {
                    hx .
                  } else {
                    hx ...$args
                  }
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
              '';

            xdg.config.files."nushell/config.nu".text = # nu
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
                    external: {
                      enable: true
                      max_results: 100
                      completer: null
                    }
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
          };
        in
        {
          prefs.user.shell = config.prefs.nushell.package;

          hjem.users.${config.prefs.user.name} = userConf;
          hjem.users.root = mkIf config.prefs.nushell.configureRoot (
            {
              enable = true;
              directory = "/root";
              user = "root";
            }
            // userConf
          );
        };
    };
}
