{ self, ... }:

{
  flake.nixosModules =
    let
      profiles = lib: {
        minimal = {
          programs.nushell.enable = true;
          programs.helix.enable = true;
          prefs.themes.green = lib.mkDefault true;
        };
        server = {
          prefs.profiles.minimal = true;
          services.openssh.enable = true;

          programs.git.enable = true;
          programs.jujutsu.enable = true;
        };
        desktop = {
          prefs.profiles.minimal = true;

          boot.plymouth.enable = true;

          services.printing.enable = true;
          hardware.bluetooth.enable = true;

          programs.niri.enable = true;
          services.keyd.enable = true;

          programs.nautilus.enable = true;
          programs.wezterm.enable = true;
          programs.helium.enable = true;
          programs.loupe.enable = true;
          programs.mpv.enable = true;
        };
        extraDesktopApps = {
          programs.discord.enable = true;
          programs.steam.enable = true;
          programs.sober.enable = true;
          programs.loupe.enable = true;
          programs.zen.enable = true;
          programs.mpv.enable = true;
        };
      };
    in
    self.mkModule {
      path = "profiles";

      opts =
        {
          lib,
          mkOpt,
          types,
          ...
        }:
        lib.genAttrs (lib.attrNames (profiles lib)) (x: mkOpt types.bool false "Enable ${x} profile");

      cfg =
        { lib, cfg, ... }:
        profiles lib
        |> lib.mapAttrs (k: _: lib.mkIf cfg.${k} (profiles lib).${k})
        |> lib.attrValues
        |> lib.mkMerge;
    };
}
