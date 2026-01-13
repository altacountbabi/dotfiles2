{ self, inputs, ... }:

{
  flake.nixosModules.niri =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.niri;

      inherit (builtins) toPath isString;
      inherit (lib)
        mkOpt
        types
        mkDefault
        mapAttrs
        # genAttrs
        optional
        getExe
        mkIf
        ;
      inherit (lib.strings) floatToString;
    in
    {
      options.programs.niri = {
        autostart =
          let
            anyGreeters =
              config.services.displayManager
              |> lib.mapAttrsToList (_: v: (builtins.tryEval (v.enable or false)).value)
              |> builtins.any (x: x);
          in
          mkOpt types.bool (!anyGreeters) "Whether to automatically start niri, replacing getty on tty1";

        settings = mkOpt types.attrs { } "Niri settings";
      };

      imports = with self.nixosModules; [
        gtk
        rofi
        mako
      ];

      config =
        let
          wrapped =
            (inputs.wrappers.wrapperModules.niri.apply {
              inherit pkgs;
              inherit (cfg) settings;
            }).wrapper;
        in
        {
          programs.niri = {
            enable = true;
            package = wrapped;
            settings = mkDefault {
              outputs =
                config.prefs.monitors
                |> mapAttrs (
                  k: v: {
                    ${if (!v.enable) then "off" else null} = null;
                    mode = "${toString v.width}x${toString v.height}@${floatToString v.refreshRate}";
                    backdrop-color = v.color;
                    position = {
                      inherit (v) x y;
                      _keys = true;
                    };
                    ${if v.vrr then "variable-refresh-rate" else null} = null;
                    inherit (v) scale transform;
                  }
                );

              spawn-at-startup =
                (
                  let
                    inherit (config.prefs.theme) wallpaper;
                  in
                  optional (wallpaper != null) [
                    "${getExe pkgs.swaybg}"
                    "-i"
                    "${toPath wallpaper}"
                  ]
                )
                ++ [
                  "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
                  "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon"
                ]
                ++ (
                  let
                    cmd =
                      v:
                      if isString v then
                        [
                          "${getExe pkgs.bash}"
                          "-c"
                          v
                        ]
                      else
                        getExe v;
                  in
                  config.prefs.autostart |> map cmd
                );

              window-rules = [
                {
                  matches = [ { is-floating = true; } ];
                  geometry-corner-radius = [
                    15
                    15
                    15
                    15
                  ];
                  clip-to-geometry = true;
                  shadow = {
                    on = null;
                    spread = 5;
                    color = "#000000AA";
                  };
                }
                {
                  matches = [
                    { title = "MainPicker"; }
                    { title = ".*Properties.*"; }
                  ];

                  open-floating = true;
                }
                {
                  matches = [
                    { app-id = "zen(-twilight)?"; }
                    { app-id = "helium"; }
                  ];
                  open-on-workspace = "browser";
                }
                {
                  matches = [
                    { app-id = "discord"; }
                  ];
                  open-on-workspace = "chat";
                }
                {
                  matches = [
                    { app-id = "org.vinegarhq.Sober"; }
                  ];
                  open-on-workspace = "code";
                }
              ];

              # Overview
              overview.workspace-shadow.off = null;
              gestures.hot-corners.off = null;
              layer-rules = [
                {
                  matches = [
                    { namespace = "^wallpaper$"; }
                    { namespace = "quickshell"; }
                  ];
                  place-within-backdrop = true;
                }
              ];

              # FIXME: Uncommment when wrappers#86 is merged
              # workspaces = genAttrs [
              #   "browser"
              #   "chat"
              #   "code"
              #   "scratchpad"
              # ] (name: null);

              environment.DISPLAY = ":0";

              input = {
                mouse = {
                  accel-speed = 0.0;
                  accel-profile = "flat";
                };

                workspace-auto-back-and-forth = null;
                focus-follows-mouse = null;
              };

              layout = {
                gaps = 5;
                struts = {
                  left = -5;
                  right = -5;
                  top = -5;
                  bottom = -5;
                };

                default-column-width.proportion = 1.0;

                focus-ring.off = null;
                border.off = null;

                background-color = "transparent";
              };

              hotkey-overlay.skip-at-startup = null;
              prefer-no-csd = null;

              cursor = {
                xcursor-theme = "Adwaita";
                xcursor-size = 24;
              };

              binds =
                let
                  packages = self.packages.${pkgs.stdenv.hostPlatform.system};
                  notify-info = packages.notify-info |> getExe |> toString;
                  cycle-sinks = packages.cycle-sinks |> getExe |> toString;
                  playerctl = pkgs.playerctl |> getExe |> toString;
                  volume = packages.volume |> getExe |> toString;
                in
                {
                  "Mod+Q".close-window = null;
                  "Mod+F".fullscreen-window = null;
                  "Mod+Shift+F".toggle-windowed-fullscreen = null;
                  "Mod+V".toggle-window-floating = null;
                  "Mod+Shift+C".center-column = null;

                  "Mod+WheelScrollUp".focus-column-left = null;
                  "Mod+WheelScrollDown".focus-column-right = null;

                  "Mod+Up".focus-workspace-up = null;
                  "Mod+Down".focus-workspace-down = null;
                  "Mod+Left".focus-column-left = null;
                  "Mod+Right".focus-column-right = null;
                  "Mod+Shift+Up".move-column-to-workspace-up = null;
                  "Mod+Shift+Down".move-column-to-workspace-down = null;
                  "Mod+Shift+Left".move-column-left = null;
                  "Mod+Shift+Right".move-column-right = null;

                  "Mod+H".focus-column-left = null;
                  "Mod+K".focus-workspace-up = null;
                  "Mod+J".focus-workspace-down = null;
                  "Mod+L".focus-column-right = null;
                  "Mod+Shift+K".move-column-to-workspace-up = null;
                  "Mod+Shift+J".move-column-to-workspace-down = null;
                  "Mod+Shift+H".move-column-left = null;
                  "Mod+Shift+L".move-column-right = null;

                  "Mod+1".focus-workspace = 1;
                  "Mod+2".focus-workspace = 2;
                  "Mod+3".focus-workspace = 3;
                  "Mod+4".focus-workspace = 4;
                  "Mod+5".focus-workspace = 5;
                  "Mod+6".focus-workspace = 6;
                  "Mod+7".focus-workspace = 7;
                  "Mod+8".focus-workspace = 8;
                  "Mod+9".focus-workspace = 9;
                  "Mod+S".focus-workspace = "scratchpad";
                  "Mod+Grave".focus-workspace = 100;
                  "Mod+Shift+1".move-column-to-workspace = 1;
                  "Mod+Shift+2".move-column-to-workspace = 2;
                  "Mod+Shift+3".move-column-to-workspace = 3;
                  "Mod+Shift+4".move-column-to-workspace = 4;
                  "Mod+Shift+5".move-column-to-workspace = 5;
                  "Mod+Shift+6".move-column-to-workspace = 6;
                  "Mod+Shift+7".move-column-to-workspace = 7;
                  "Mod+Shift+8".move-column-to-workspace = 8;
                  "Mod+Shift+9".move-column-to-workspace = 9;
                  "Mod+Shift+S".move-column-to-workspace = "scratchpad";
                  "Mod+Shift+Grave".move-column-to-workspace = 100;

                  "Mod+A".toggle-overview = null;

                  "Mod+Return".spawn = [
                    "wezterm"
                    "start"
                  ];
                  "Mod+Shift+Return".spawn = [
                    "wezterm"
                    "connect"
                    "unix"
                  ];
                  "Mod+Space".spawn = [
                    "rofi"
                    "-show"
                    "drun"
                  ];
                  "Mod+Comma".spawn = [
                    "rofi"
                    "-show"
                    "emoji"
                    "-modi"
                    "emoji"
                    "-kb-secondary-copy"
                    ""
                    "-kb-custom-1"
                    "Ctrl+c"
                    "-display-emoji"
                    "Emoji"
                  ];
                  "Mod+M".spawn = "youtube-music";
                  "Mod+B".spawn = [
                    "wezterm"
                    "start"
                    "bluetui"
                  ];

                  "Alt+R".screenshot = null;
                  "Print".screenshot-screen = null;
                  "Alt+Print".screenshot-window = null;

                  "Mod+Escape".spawn = notify-info;
                  "Alt+7".spawn = [
                    playerctl
                    "previous"
                  ];
                  "Alt+8".spawn = [
                    playerctl
                    "play-pause"
                  ];
                  "Alt+9".spawn = [
                    playerctl
                    "next"
                  ];
                  "XF86AudioPrev".spawn = [
                    playerctl
                    "previous"
                  ];
                  "XF86AudioPlay".spawn = [
                    playerctl
                    "play-pause"
                  ];
                  "XF86AudioNext".spawn = [
                    playerctl
                    "next"
                  ];
                  "Alt+0".spawn = [
                    volume
                    "mute"
                  ];
                  "Alt+Minus".spawn = [
                    volume
                    "decrease"
                    "5"
                  ];
                  "Alt+Equal".spawn = [
                    volume
                    "increase"
                    "5"
                  ];
                  "XF86AudioMute".spawn = [
                    volume
                    "mute"
                  ];
                  "XF86AudioLowerVolume".spawn = [
                    volume
                    "decrease"
                    "5"
                  ];
                  "XF86AudioRaiseVolume".spawn = [
                    volume
                    "increase"
                    "5"
                  ];
                  "Mod+O".spawn = cycle-sinks;

                  "Mod+Shift+P".power-off-monitors = null;
                  "Mod+Slash".show-hotkey-overlay = null;
                  "Ctrl+Alt+Delete".quit = null;
                };

              extraConfig = # kdl
                ''
                  screenshot-path null

                  workspace "browser"
                  workspace "chat"
                  workspace "code"
                  workspace "scratchpad"

                  animations {
                    window-resize {
                      custom-shader r"
                        ${builtins.readFile ./resize-shader.glsl}
                      "
                    }
                  }
                '';
            };
          };

          environment.systemPackages = with pkgs; [
            adwaita-icon-theme
            xwayland-satellite
            # TODO: Add this back later when writing quickshell config
            # inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];

          systemd.user.tmpfiles.rules = with config.prefs.user; [
            "d ${home}/.local/share/icons 0755 ${name} users - -"
            "L ${home}/.local/share/icons/default - - - - ${pkgs.adwaita-icon-theme}/share/icons/Adwaita"
          ];

          systemd.services = mkIf cfg.autostart {
            "getty@tty1".enable = false;
            "autovt@tty1".enable = false;

            niri-session = {
              description = "Niri Wayland compositor on tty1";
              after = [ "systemd-user-sessions.service" ];
              wants = [ "systemd-user-sessions.service" ];
              conflicts = [ "getty@tty1.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                ExecStart = "/run/current-system/sw/bin/niri-session";
                Restart = "always";
                TTYPath = "/dev/tty1";
                TTYReset = "yes";
                TTYVHangup = "yes";
                TTYVTDisallocate = "yes";
                StandardInput = "tty";
                StandardOutput = "journal";
                StandardError = "journal";
                User = config.prefs.user.name;
                PAMName = "login";
              };
            };
          };
        };
    };
}
