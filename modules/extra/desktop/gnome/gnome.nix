{ self, ... }:

{
  flake.nixosModules = self.mkModule "gnome" (
    let
      extensions = [
        "blur"
        "taskbar"
        "desktop-icons"
      ];
    in
    {
      path = "gnome";

      opts =
        {
          lib,
          mkOpt,
          types,
          ...
        }:
        {
          extensions = lib.genAttrs extensions (name: mkOpt types.bool true "Enable ${name} extension");
        };

      cfg =
        {
          config,
          pkgs,
          lib,
          cfg,
          ...
        }:
        {
          imports = [ self.nixosModules.gtk ];

          config = lib.mkMerge [
            {
              services.desktopManager.gnome.enable = true;

              programs.dconf = {
                enable = true;
                profiles.user.databases = [
                  {
                    settings = with lib.gvariant; {
                      "org/gnome/desktop/background" = lib.optionalAttrs (config.prefs.theme.wallpaper != null) {
                        picture-uri = config.prefs.theme.wallpaper;
                        picture-uri-dark = config.prefs.theme.wallpaper;
                      };
                      "org/gnome/desktop/interface" = {
                        color-scheme = "prefer-${config.prefs.theme.polarity}";
                        enable-hot-corners = false;
                        gtk-enable-primary-paste = false;
                      };
                      "org/gnome/desktop/peripherals/mouse" = {
                        accel-profile = "flat";
                      };
                      "org/gnome/desktop/session" = {
                        idle-delay = mkUint32 0;
                      };
                      "org/gnome/desktop/wm/keybindings" = {
                        show-desktop = mkArray [ "<Super>d" ];
                      };
                      "org/gnome/desktop/wm/preferences" = {
                        button-layout = "appmenu:minimize,maximize,close";
                      };
                      "org/gnome/SessionManager" = {
                        logout-prompt = false;
                      };

                      # Extensions
                      "org/gnome/shell" = {
                        enabled-extensions = mkArray (
                          (lib.optional cfg.extensions.blur "blur-my-shell@aunetx")
                          ++ (lib.optional cfg.extensions.taskbar "dash-to-panel@jderose9.github.com")
                          # Doesn't work for some reason, it used to work
                          # ++ (lib.optional cfg.extensions.desktop-icons "gtk4-ding@smedius.gitlab.com")
                        );
                      };
                      ${if cfg.extensions.desktop-icons then "org/gnome/shell/extensions/gtk4-ding" else null} = {
                        show-home = false;
                        show-trash = false;
                      };
                      ${if cfg.extensions.taskbar then "org/gnome/shell/extensions/dash-to-panel" else null} = {
                        animate-appicon-hover-animation-extent = builtins.toJSON {
                          RIPPLE = 4;
                          PLANK = 4;
                          SIMPLE = 1;
                        };
                        context-menu-entries = builtins.toJSON [
                          {
                            title = "Task Manager";
                            cmd = "${pkgs.resources |> lib.getExe}";
                          }
                          {
                            title = "Files";
                            cmd = "nautilus";
                          }
                          {
                            title = "Extensions";
                            cmd = "gnome-extensions-app";
                          }
                        ];
                        dot-position = "BOTTOM";
                        dot-style-focused = "METRO";
                        hide-overview-on-startup = true;
                        hotkeys-overlay-combo = "TEMPORARILY";
                        overview-click-to-exit = true;
                        panel-anchors = builtins.toJSON {
                          "RHT-0x00000000" = "MIDDLE";
                        };
                        panel-element-positions = builtins.toJSON {
                          "RHT-0x00000000" = [
                            {
                              element = "showAppsButton";
                              visible = true;
                              position = "stackedTL";
                            }
                            {
                              element = "activitiesButton";
                              visible = false;
                              position = "stackedTL";
                            }
                            {
                              element = "leftBox";
                              visible = true;
                              position = "stackedTL";
                            }
                            {
                              element = "taskbar";
                              visible = true;
                              position = "stackedTL";
                            }
                            {
                              element = "centerBox";
                              visible = true;
                              position = "stackedBR";
                            }
                            {
                              element = "rightBox";
                              visible = true;
                              position = "stackedBR";
                            }
                            {
                              element = "dateMenu";
                              visible = true;
                              position = "centerMonitor";
                            }
                            {
                              element = "systemMenu";
                              visible = true;
                              position = "stackedBR";
                            }
                            {
                              element = "desktopButton";
                              visible = false;
                              position = "stackedBR";
                            }
                          ];
                        };
                        panel-sizes = builtins.toJSON {
                          "RHT-0x00000000" = 39;
                        };
                        show-apps-icon-file = "";
                        trans-panel-opacity = 0.75;
                      };
                    };

                  }
                ];
              };

              environment.gnome.excludePackages = (
                with pkgs;
                [
                  atomix
                  cheese
                  epiphany
                  evince
                  geary
                  gedit
                  gnome-characters
                  gnome-music
                  gnome-photos
                  gnome-terminal
                  gnome-console
                  gnome-tour
                  gnome-maps
                  gnome-clocks
                  gnome-weather
                  gnome-contacts
                  gnome-system-monitor
                  gnome-connections
                  snapshot
                  showtime
                  hitori
                  iagno
                  tali
                  totem
                  yelp
                ]
              );

              environment.systemPackages = (
                with pkgs.gnomeExtensions;
                (lib.optional cfg.extensions.blur blur-my-shell)
                ++ (lib.optional cfg.extensions.taskbar dash-to-panel)
                ++ (lib.optionals cfg.extensions.desktop-icons [
                  gtk4-desktop-icons-ng-ding
                  pkgs.glib
                  pkgs.gjs
                ])
              );
            }
          ];
        };
    }
  );
}
