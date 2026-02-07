{ self, ... }:

{
  flake.nixosModules =
    let
      profiles =
        lib:
        let
          inherit (lib) mkDefault;
        in
        {
          minimal = {
            programs.nushell.enable = mkDefault true;
            programs.helix.enable = mkDefault true;
            programs.nix-fzf.enable = mkDefault true;
            prefs.themes.base16-default-dark = mkDefault true;
          };
          server = {
            prefs.profiles.minimal = mkDefault true;
            services.openssh.enable = mkDefault true;

            programs.git.enable = mkDefault true;
            programs.jujutsu.enable = mkDefault true;
          };
          desktop = {
            prefs.profiles.minimal = mkDefault true;

            boot.plymouth.enable = mkDefault true;

            services.printing.enable = mkDefault true;
            hardware.bluetooth.enable = mkDefault true;

            programs.niri.enable = mkDefault true;
            services.keyd.enable = mkDefault true;

            programs.nautilus.enable = mkDefault true;
            programs.wezterm.enable = mkDefault true;
            programs.helium.enable = mkDefault true;
            programs.loupe.enable = mkDefault true;
            programs.mpv.enable = mkDefault true;
          };
          extraDesktopApps = {
            programs.discord.enable = mkDefault true;
            programs.steam.enable = mkDefault true;
            programs.sober.enable = mkDefault true;
            programs.loupe.enable = mkDefault true;
            programs.zen.enable = mkDefault true;
            programs.mpv.enable = mkDefault true;
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
