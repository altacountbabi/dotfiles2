{
  flake.nixosModules.green-theme = {
    prefs.theme = {
      wallpaper = builtins.path { path = ./wallpaper.jpg; };
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

        accent = "#89d6b9";
      };
    };
  };
}
