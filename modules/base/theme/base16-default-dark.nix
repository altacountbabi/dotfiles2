{
  flake.nixosModules.base16-default-dark-theme = {
    prefs.theme.colors = rec {
      rosewater = "#f8f8f8";
      flamingo = "#c55555";
      pink = "#c28cb8";
      mauve = "#aa759f";
      red = "#ac4242";
      maroon = "#712b2b";
      peach = "#f4bf75";
      yellow = "#feca88";
      green = "#90a959";
      teal = "#75b5aa";
      sky = "#93d3c3";
      sapphire = "#456877";
      blue = "#6a9fb5";
      lavender = "#82b8c8";

      text = "#d8d8d8";
      subtext1 = "#b8b8b8";
      subtext0 = "#828482";

      overlay2 = "#8e8e8e";
      overlay1 = "#6b6b6b";
      overlay0 = "#585858";

      surface2 = "#404040";
      surface1 = "#303030";
      surface0 = "#202020";

      base = "#181818";
      mantle = "#141414";
      crust = "#0f0f0f";

      accent = blue;
    };
  };
}
