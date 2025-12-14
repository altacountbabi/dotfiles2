{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "xdg";

    opts =
      { mkOpt, types, ... }:
      {
        patchSSH =
          mkOpt types.bool true
            "Whether to patch openssh to use $XDG_CONFIG_DIR/ssh instead of $HOME/.ssh";
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
        inherit (lib) mkIf concatMapStringsSep mkMerge;
      in
      mkMerge [
        {
          nixpkgs.overlays = [
            (final: prev: {
              # I would use `wrapPackage` from the wrappers flake here, but that uses `lib.escapeShellArg` which wraps everything in quotes, which triggers SC2016
              wget = prev.symlinkJoin {
                name = "wget-wrapped";
                paths = [ prev.wget ];
                buildInputs = [ prev.makeWrapper ];
                postBuild = ''
                  wrapProgram $out/bin/wget --add-flags "--hsts-file=\$XDG_STATE_HOME/wget-hsts"
                '';
              };
            })
          ];

          nix.settings.use-xdg-base-directories = !config.isDroid;

          environment.systemPackages = with pkgs; [
            xdg-user-dirs
          ];

          environment.sessionVariables = rec {
            HOME = config.prefs.user.home;
            XDG_CACHE_HOME = "${HOME}/.cache";
            XDG_CONFIG_HOME = "${HOME}/.config";
            XDG_DATA_HOME = "${HOME}/.local/share";
            XDG_STATE_HOME = "${HOME}/.local/state";

            ANDROID_AVD_HOME = "${XDG_CONFIG_HOME}/android";
            ANDROID_SDK_HOME = "${XDG_CONFIG_HOME}/android";
            GRADLE_USER_HOME = "${XDG_DATA_HOME}/gradle";

            CARGO_HOME = "${XDG_DATA_HOME}/cargo";

            GTK2_RC_FILES = "${XDG_CONFIG_HOME}/gtk-2.0/gtkrc-2.0";

            HISTFILE = "${XDG_STATE_HOME}/bash/history";
            PYTHONHISTFILE = "${XDG_STATE_HOME}/python/history";
            NODE_REPL_HISTORY = "${XDG_STATE_HOME}/nodejs/repl-history";
            ANDROID_EMULATOR_HOME = "${XDG_STATE_HOME}/android-emulator";

            BASH_COMPLETION_USER_FILE = "${XDG_CONFIG_HOME}/bash/completion";

            INPUTRC = "${XDG_CONFIG_HOME}/inputrc";
            ICEAUTHORITY = "${XDG_CACHE_HOME}/ICEauthority";
            LESSHISTFILE = "${XDG_STATE_HOME}/less/history";
            LESSKEY = "${XDG_CONFIG_HOME}/less/keys";

            __GL_SHADER_DISK_CACHE_PATH = "${XDG_CACHE_HOME}/nv";
            XCOMPOSECACHE = "${XDG_CACHE_HOME}/xcompose";
          };

          system.userActivationScripts.initXDG = mkMerge [
            {
              text = # bash
                ''
                  for dir in "$XDG_DESKTOP_DIR" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "$XDG_CONFIG_HOME"; do
                    mkdir -p "$dir" -m 700
                  done

                  rm -rf "$HOME/.pki"
                  mkdir -p "$XDG_DATA_HOME/pki/nssdb"
                '';
            }

            (mkIf (config.services.openssh.enable && cfg.patchSSH) {
              text = # bash
                ''
                  mkdir -p "$XDG_CONFIG_HOME/ssh"
                '';
            })
          ];

          # dbus-broker doesn't produce a $HOME/.dbus like the dbus daemon does.
          services.dbus.implementation = "broker";
        }

        (
          let
            keyFiles = [
              "id_dsa"
              "id_ecdsa"
              "id_ecdsa_sk"
              "id_ed25519"
              "id_ed25519_sk"
              "id_rsa"
            ];
            keyFilesStr = builtins.concatStringsSep " " keyFiles;
            sshConfigDir = "$XDG_CONFIG_HOME/ssh";
          in
          mkIf (config.services.openssh.enable && cfg.patchSSH) {
            # To spare us passing the extra options to the executables, we set these
            # in the system config file.
            programs.ssh.extraConfig = ''
              Host *
                ${concatMapStringsSep "\n" (key: "IdentityFile ~/.config/ssh/${key}") keyFiles}
                UserKnownHostsFile ~/.config/ssh/known_hosts
            '';

            # Massive shitfuckery, I have no clue what is going on here
            # https://github.com/hlissner/dotfiles/blob/b51c0d90673a3f3779197ca53952bfe85718f708/modules/xdg.nix#L158C5-L158C7
            environment.systemPackages =
              with pkgs;
              let
                mkWrapper =
                  package: postBuild:
                  let
                    name = if builtins.isList package then elemAt package 0 else package;
                    paths = if builtins.isList package then package else [ package ];
                  in
                  pkgs.symlinkJoin {
                    inherit paths postBuild;
                    name = "${name}-wrapped";
                    buildInputs = [ pkgs.makeWrapper ];
                  };
              in
              [
                (mkWrapper openssh ''
                  dir='${sshConfigDir}'
                  cfg="$dir/config"
                  wrapProgram "$out/bin/ssh" \
                    --run "[[ \$@ != *\ -F\ * && -s \"$cfg\" ]] && dir=\"$cfg\"" \
                    --add-flags '${"$"}{dir:+-F "$dir"}'
                  wrapProgram "$out/bin/scp" \
                    --run "[[ \$@ != *\ -F\ * && -s \"$cfg\" ]] && dir=\"$cfg\"" \
                    --add-flags '${"$"}{dir:+-F "$dir"}'
                  wrapProgram "$out/bin/ssh-add" \
                    --run "dir=\"$dir\"" \
                    --run 'args=()' \
                    --run '[ $# -eq 0 ] && for f in ${keyFilesStr}; do [ -f "$dir/$f" ] && args+="$dir/$f"; done' \
                    --add-flags '${"$"}{args:+-H "$dir/known_hosts"}' \
                    --add-flags '${"$"}{args:+-H "/etc/ssh/ssh_known_hosts"}' \
                    --add-flags '"''${args[@]}"'
                '')
                (mkWrapper ssh-copy-id ''
                  wrapProgram "$out/bin/ssh-copy-id" \
                    --run 'dir="${sshConfigDir}"' \
                    --run 'opts=()' \
                    --run '[[ $@ != *\ -i\ * ]] && for f in ${keyFilesStr}; do [ -f "$dir/$f" ] && opts+="-i '$dir/$f'"; done' \
                    --append-flags '"''${opts[@]}"'
                '')
              ];
          }
        )
      ];
  };
}
