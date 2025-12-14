{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "theme";

    opts =
      {
        config,
        mkOpt,
        types,
        ...
      }:
      {
        wallpaper = mkOpt (types.nullOr types.path) null "Path to wallpaper image";

        polarity = mkOpt (types.enum [
          "dark"
          "light"
        ]) "dark" "Polarity of the theme";

        colors =
          let
            color = mkOpt types.str "";
          in
          {
            rosewater = color "Rosewater";
            flamingo = color "Flamingo";
            pink = color "Pink";
            mauve = color "Mauve";
            red = color "Red";
            maroon = color "Maroon";
            peach = color "Peach";
            yellow = color "Yellow";
            green = color "Green";
            teal = color "Teal";
            sky = color "Sky";
            sapphire = color "Sapphire";
            blue = color "Blue";
            lavender = color "Lavender";

            text = color "Text";
            subtext1 = color "Subtext1";
            subtext0 = color "Subtext0";

            overlay2 = color "Overlay2";
            overlay1 = color "Overlay1";
            overlay0 = color "Overlay0";

            surface2 = color "Surface2";
            surface1 = color "Surface1";
            surface0 = color "Surface0";

            base = color "Base";
            mantle = color "Mantle";
            crust = color "Crust";

            accent = mkOpt types.str config.prefs.theme.colors.mauve "Accent";
          };
      };
  };
}
