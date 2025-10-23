{ self, ... }:

{
  flake.nixosModules.fonts =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        fonts.fontconfig.defaultFonts = lib.mkDefault {
          emoji = [ "Twemoji Color" ];
          serif = [ "Bitstream Vera" ];
          sansSerif = [ "Bitstream Vera" ];
          monospace = [ "FiraCode Nerd Font" ];
        };

        fonts.packages = with pkgs; [
          inter
          noto-fonts
          corefonts
          dejavu_fonts
          nerd-fonts.fira-code

          material-symbols
          twemoji-color-font

          self.packages.${pkgs.system}.segoe-ui
        ];
      };
    };
}
