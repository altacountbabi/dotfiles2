{ inputs, self, ... }:

{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        niri.package = mkOpt types.package pkgs.niri "The package to use for niri";
      };
    };

  flake.nixosModules.niri =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mapAttrsToList
        getExe
        ;
      inherit (lib.strings) floatToString optionalString concatStringsSep;
    in
    {
      imports = with self.nixosModules; [
        rofi
        mako
      ];

      config =
        let
          niriConfig = pkgs.writeTextFile {
            name = "niri-config";
            text =
              let
                monitors =
                  config.prefs.monitors
                  |> mapAttrsToList (
                    name: data:
                    let
                      options = [
                        (optionalString (!data.enable) "off")
                        "mode \"${data.width |> toString}x${data.height |> toString}@${data.refreshRate |> floatToString}\""
                        "scale ${data.scale |> floatToString}"
                        "transform \"${data.transform |> toString}\""
                        "position x=${data.x |> toString} y=${data.y |> toString}"
                        (optionalString data.vrr "variable-refresh-rate")
                        "backdrop-color \"#000000\""
                      ];
                    in
                    # kdl
                    ''
                      output "${name}" {
                      ${options |> builtins.filter (x: x != "") |> map (x: "  ${x}") |> concatStringsSep "\n"}
                      }
                    ''
                  )
                  |> concatStringsSep "\n";

                packages = self.packages.${pkgs.system};
                notify-info = packages.notify-info |> getExe;
                playerctl = pkgs.playerctl |> getExe;
                volume = packages.volume |> getExe;
                cycle-sinks = packages.cycle-sinks |> getExe;
              in
              # kdl
              ''
                ${monitors}

                // Startup apps
                spawn-at-startup "${pkgs.swaybg |> getExe}" "-i" "${config.root}/plant.jpg"
                spawn-at-startup "${pkgs.xwayland-satellite |> getExe}"
                spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
                spawn-at-startup "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon"

                // Window rules
                window-rule {
                  match is-floating=true

                  geometry-corner-radius 15 15 15 15
                  clip-to-geometry true
                  shadow {
                    on
                    spread 5
                    color "#000000AA"
                  }
                }

                window-rule {
                  match title="MainPicker"
                  match title=".*Properties.*"

                  open-floating true
                }

                window-rule {
                  match app-id="zen(-twilight)?"
                  match app-id="helium"

                  open-on-workspace "browser"
                }

                window-rule {
                  match app-id="discord"
                  open-on-workspace "chat"
                }

                window-rule {
                  match app-id="org.vinegarhq.Sober"
                  open-on-workspace "code"
                }

                // Overview
                layer-rule {
                  match namespace="^wallpaper$"
                  place-within-backdrop true
                }

                layer-rule {
                  match namespace="quickshell"
                  place-within-backdrop true
                }

                overview {
                  workspace-shadow {
                    off
                  }
                }

                gestures {
                  hot-corners { off; }
                }

                // Workspaces
                workspace "browser"
                workspace "chat"
                workspace "code"
                workspace "scratchpad"

                // Environment variables
                environment {
                  DISPLAY ":0"
                }

                // Input
                input {
                  mouse {
                    accel-speed 0.0
                    accel-profile "flat"
                  }

                  workspace-auto-back-and-forth
                  focus-follows-mouse
                }

                // Layout
                layout {
                  gaps 5
                  struts {
                    left -5
                    right -5
                    top -5
                    bottom -5
                  }

                  default-column-width { proportion 1.0; }

                  focus-ring { off; }
                  border { off; }

                  background-color "transparent"
                }

                animations {
                  window-resize {
                    custom-shader r"
                      vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
                        vec3 coords_next_geo = niri_curr_geo_to_next_geo * coords_curr_geo;

                        vec3 coords_stretch = niri_geo_to_tex_next * coords_curr_geo;
                        vec3 coords_crop = niri_geo_to_tex_next * coords_next_geo;

                        bool can_crop_by_x = niri_curr_geo_to_next_geo[0][0] <= 1.0;
                        bool can_crop_by_y = niri_curr_geo_to_next_geo[1][1] <= 1.0;

                        vec3 coords = coords_stretch;
                        if (can_crop_by_x)
                          coords.x = coords_crop.x;
                        if (can_crop_by_y)
                          coords.y = coords_crop.y;

                        vec4 color = texture2D(niri_tex_next, coords.st);

                        if (can_crop_by_x && (coords_curr_geo.x < 0.0 || 1.0 < coords_curr_geo.x))
                          color = vec4(0.0);
                        if (can_crop_by_y && (coords_curr_geo.y < 0.0 || 1.0 < coords_curr_geo.y))
                          color = vec4(0.0);

                        return color;
                      }
                    "
                  }
                }

                binds {
                  // Window management
                  Mod+Q { close-window; }
                  Mod+F { fullscreen-window; }
                  Mod+Shift+F { toggle-windowed-fullscreen; }
                  Mod+V { toggle-window-floating; }
                  Mod+Shift+C { center-column; }

                  Mod+WheelScrollUp { focus-column-left; }
                  Mod+WheelScrollDown { focus-column-right; }

                  Mod+Up { focus-workspace-up; }
                  Mod+Down { focus-workspace-down; }
                  Mod+Left { focus-column-left; }
                  Mod+Right { focus-column-right; }
                  Mod+Shift+Up { move-column-to-workspace-up; }
                  Mod+Shift+Down { move-column-to-workspace-down; }
                  Mod+Shift+Left { move-column-left; }
                  Mod+Shift+Right { move-column-right; }

                  Mod+H { focus-column-left; }
                  Mod+K { focus-workspace-up; }
                  Mod+J { focus-workspace-down; }
                  Mod+L { focus-column-right; }
                  Mod+Shift+K { move-column-to-workspace-up; }
                  Mod+Shift+J { move-column-to-workspace-down; }
                  Mod+Shift+H { move-column-left; }
                  Mod+Shift+L { move-column-right; }

                  // Workspace switching
                  Mod+1 { focus-workspace 1; }
                  Mod+2 { focus-workspace 2; }
                  Mod+3 { focus-workspace 3; }
                  Mod+4 { focus-workspace 4; }
                  Mod+5 { focus-workspace 5; }
                  Mod+6 { focus-workspace 6; }
                  Mod+7 { focus-workspace 7; }
                  Mod+8 { focus-workspace 8; }
                  Mod+9 { focus-workspace 9; }
                  Mod+S { focus-workspace "scratchpad"; }
                  Mod+Grave { focus-workspace 100; }
                  Mod+Shift+1 { move-column-to-workspace 1; }
                  Mod+Shift+2 { move-column-to-workspace 2; }
                  Mod+Shift+3 { move-column-to-workspace 3; }
                  Mod+Shift+4 { move-column-to-workspace 4; }
                  Mod+Shift+5 { move-column-to-workspace 5; }
                  Mod+Shift+6 { move-column-to-workspace 6; }
                  Mod+Shift+7 { move-column-to-workspace 7; }
                  Mod+Shift+8 { move-column-to-workspace 8; }
                  Mod+Shift+9 { move-column-to-workspace 9; }
                  Mod+Shift+S { move-column-to-workspace "scratchpad"; }
                  Mod+Shift+Grave { move-column-to-workspace 100; }

                  Mod+A { toggle-overview; }

                  // Apps
                  Mod+Return { spawn "wezterm" "start"; }
                  Mod+Shift+Return { spawn "wezterm" "connect" "unix"; }
                  Mod+Space { spawn "rofi" "-show" "drun"; }
                  Mod+Comma { spawn "rofi" \
                    "-show" "emoji" \
                    "-modi" "emoji" \
                    "-kb-secondary-copy" "" \
                    "-kb-custom-1" "Ctrl+c" \
                    "-display-emoji" "Emoji"
                  }
                  Mod+M { spawn "youtube-music"; }
                  Mod+B { spawn "wezterm" "start" "bluetui"; }

                  // Screenshots
                  Alt+R { screenshot; }
                  Print { screenshot-screen; }
                  Alt+Print { screenshot-window; }

                  // Scripts
                  Mod+Escape { spawn "${notify-info}"; }

                  // Audio
                  Alt+7 { spawn "${playerctl}" "previous"; }
                  Alt+8 { spawn "${playerctl}" "play-pause"; }
                  Alt+9 { spawn "${playerctl}" "next"; }
                  XF86AudioPrev { spawn "${playerctl}" "previous"; }
                  XF86AudioPlay { spawn "${playerctl}" "play-pause"; }
                  XF86AudioNext { spawn "${playerctl}" "next"; }
                  Alt+0 allow-when-locked=true { spawn "${volume}" "mute"; }
                  Alt+Minus allow-when-locked=true { spawn "${volume}" "decrease" "5"; }
                  Alt+Equal allow-when-locked=true { spawn "${volume}" "increase" "5"; }
                  XF86AudioMute allow-when-locked=true { spawn "${volume}" "mute"; }
                  XF86AudioLowerVolume allow-when-locked=true { spawn "${volume}" "decrease" "5"; }
                  XF86AudioRaiseVolume allow-when-locked=true { spawn "${volume}" "increase" "5"; }
                  Mod+O { spawn "${cycle-sinks}"; }

                  // Other
                  Mod+Shift+P { power-off-monitors; }
                  Mod+Slash { show-hotkey-overlay; }
                  Ctrl+Alt+Delete { quit; }
                }

                // Misc
                hotkey-overlay { skip-at-startup; }
                screenshot-path null
                prefer-no-csd

                cursor {
                  xcursor-theme "Adwaita"
                  xcursor-size 24
                }
              '';
          };
        in
        {
          programs.niri = {
            enable = true;
            package = config.prefs.niri.package;
          };

          environment.sessionVariables.NIRI_CONFIG =
            let
              validate =
                ''
                  "${config.programs.niri.package}/bin/niri" validate -c "$config"
                  touch $out
                ''
                |> pkgs.runCommandLocal "validate-niri-config" { config = niriConfig; }
                |> builtins.readFile;
            in
            assert validate != null;
            niriConfig;

          environment.systemPackages = with pkgs; [
            adwaita-icon-theme
            inputs.quickshell.packages.${system}.default
          ];

          prefs.nushell.extraConfig = mkIf config.prefs.getty.autologin [
            # nushell
            ''
              if ((tty | complete | get stdout) == "/dev/tty1\n") {
                niri-session o+e>| ignore
              }
            ''
          ];

          # TODO: Add auto-login for other shells too, or better yet, just use a systemd unit
        };
    };
}
