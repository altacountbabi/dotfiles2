# TODO: Improve this module, all it really does is set up some default fonts

{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    cfg =
      { pkgs, lib, ... }:
      {
        fonts.fontconfig.defaultFonts = lib.mkDefault {
          emoji = [ "Twemoji Color" ];
          serif = [ "Noto Sans" ];
          sansSerif = [ "Noto Sans Serif" ];
          monospace = [ "FiraCode Nerd Font" ];
        };

        fonts.packages = with pkgs; [
          inter
          corefonts
          dejavu_fonts

          noto-fonts
          noto-fonts-cjk-sans
          material-symbols

          nerd-fonts.fira-code

          self.packages.${stdenv.hostPlatform.system}.segoe-ui
        ];
      };
  };
}
