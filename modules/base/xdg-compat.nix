{
  flake.nixosModules.base =
    {
      config,
      pkgs,
      ...
    }:
    {
      nixpkgs.overlays = [
        (_: prev: {
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

      system.userActivationScripts.initXDG = {
        text = # bash
          ''
            for dir in "$XDG_DESKTOP_DIR" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "$XDG_CONFIG_HOME"; do
              mkdir -p "$dir" -m 700
            done

            rm -rf "$HOME/.pki"
            mkdir -p "$XDG_DATA_HOME/pki/nssdb"
          '';
      };

      # dbus-broker doesn't produce a $HOME/.dbus like the dbus daemon does.
      services.dbus.implementation = "broker";
    };
}
