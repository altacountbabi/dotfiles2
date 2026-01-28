{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.youtube-music";

    opts =
      { mkOpt, types, ... }:
      {
        enable = mkOpt types.bool false "Enable youtube music";
        autostart = mkOpt types.bool false "Whether to automatically start youtube music at startup";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          programs.firefox-pwa = {
            enable = true;
            websites.youtube-music = {
              name = "Youtube Music";
              icon = "${pkgs.pear-desktop}/share/icons/hicolor/1024x1024/apps/pear-desktop.png";
              url = "https://music.youtube.com";
              settings = {
                "browser.startup.page" = 1;
                "browser.shell.checkDefaultBrowser" = false;

                "browser.sessionstore.resume_session_once" = false;
                "browser.sessionstore.restore_on_demand" = false;
                "browser.sessionstore.restore_tabs_lazily" = false;
                "browser.sessionstore.resume_from_crash" = false;
                "browser.sessionstore.max_tabs_undo" = 0;
                "browser.sessionstore.max_windows_undo" = 0;

                "browser.tabs.warnOnClose" = false;
                "browser.tabs.warnOnCloseOtherTabs" = false;
                "browser.tabs.warnOnOpen" = false;
                "browser.fullscreen.autohide" = true;

                "browser.privatebrowsing.autostart" = false;

                "places.history.enabled" = false;
                "browser.bookmarks.restore_default_bookmarks" = false;

                "general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS" = 12;
                "general.smoothScroll.msdPhysics.enabled" = true;
                "general.smoothScroll.msdPhysics.motionBeginSpringConstant" = 600;
                "general.smoothScroll.msdPhysics.regularSpringConstant" = 650;
                "general.smoothScroll.msdPhysics.slowdownMinDeltaMS" = 25;
                "general.smoothScroll.msdPhysics.slowdownMinDeltaRatio" = "1.3";
                "general.smoothScroll.msdPhysics.slowdownSpringConstant" = 250;
              };
              extensions = with pkgs.nur.repos.rycee.firefox-addons; [
                ublock-origin
                # TODO: Add better lyrics extension
              ];
            };
          };

          prefs.autostart = lib.mkIf cfg.autostart [
            "youtube-music"
          ];
        };
      };
  };
}
