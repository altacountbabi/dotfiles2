{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.themesEnabled = mkOpt types.bool false "Whether or not themes are enabled";
      options.prefs = {
        theme.wallpaper = mkOpt (types.nullOr types.path) null "Path to wallpaper image";

        theme.polarity = mkOpt (types.enum [
          "dark"
          "light"
        ]) "dark" "Polarity of the theme";

        theme.colors =
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

  flake.nixosModules.theme =
    { ... }:
    {
      config =
        let
          colors = {
            rosewater = "#f5e0dc";
            flamingo = "#f2cdcd";
            pink = "#f5c2e7";
            mauve = "#cba6f7";
            red = "#f38ba8";
            maroon = "#eba0ac";
            peach = "#fab387";
            yellow = "#f9e2af";
            green = "#a6e3a1";
            teal = "#94e2d5";
            sky = "#89dceb";
            sapphire = "#74c7ec";
            blue = "#89b4fa";
            lavender = "#b4befe";
            text = "#b6d2d2";
            subtext1 = "#9ebab9";
            subtext0 = "#87a2a1";
            overlay2 = "#708b8a";
            overlay1 = "#5a7474";
            overlay0 = "#455f5e";
            surface2 = "#314a49";
            surface1 = "#1d3535";
            surface0 = "#092322";
            base = "#001110";
            mantle = "#010606";
            crust = "#000404";
          };
        in
        {
          themesEnabled = true;
          prefs.theme.colors = colors;
        };
    };
}
