{
  flake.nixosModules.base =
    { lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.themesEnabled = mkOpt types.bool false "Whether or not themes are enabled";
      options.prefs = {
        theme.wallpaper = mkOpt (types.nullOr types.path) null "Path to wallpaper image";

        theme.colors =
          let
            color = mkOpt types.str "";
          in
          {
            background = color "Background";
            error = color "Error";
            error_container = color "Error container";
            inverse_on_surface = color "Inverse on surface";
            inverse_primary = color "Inverse primary";
            inverse_surface = color "Inverse surface";
            on_background = color "On background";
            on_error = color "On error";
            on_error_container = color "On error container";
            on_primary = color "On primary";
            on_primary_container = color "On primary container";
            on_primary_fixed = color "On primary fixed";
            on_primary_fixed_variant = color "On primary fixed variant";
            on_secondary = color "On secondary";
            on_secondary_container = color "On secondary container";
            on_secondary_fixed = color "On secondary fixed";
            on_secondary_fixed_variant = color "On secondary fixed variant";
            on_surface = color "On surface";
            on_surface_variant = color "On surface variant";
            on_tertiary = color "On tertiary";
            on_tertiary_container = color "On tertiary container";
            on_tertiary_fixed = color "On tertiary fixed";
            on_tertiary_fixed_variant = color "On tertiary fixed variant";
            outline = color "Outline";
            outline_variant = color "Outline variant";
            primary = color "Primary";
            primary_container = color "Primary container";
            primary_fixed = color "Primary fixed";
            primary_fixed_dim = color "Primary fixed dim";
            scrim = color "Scrim";
            secondary = color "Secondary";
            secondary_container = color "Secondary container";
            secondary_fixed = color "Secondary fixed";
            secondary_fixed_dim = color "Secondary fixed dim";
            shadow = color "Shadow";
            surface = color "Surface";
            surface_bright = color "Surface bright";
            surface_container = color "Surface container";
            surface_container_high = color "Surface container high";
            surface_container_highest = color "Surface container highest";
            surface_container_low = color "Surface container low";
            surface_container_lowest = color "Surface container lowest";
            surface_dim = color "Surface dim";
            surface_tint = color "Surface tint";
            surface_variant = color "Surface variant";
            tertiary = color "Tertiary";
            tertiary_container = color "Tertiary container";
            tertiary_fixed = color "Tertiary fixed";
            tertiary_fixed_dim = color "Tertiary fixed dim";

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
          };
      };

    };

  flake.nixosModules.theme =
    {
      config,
      pkgs,
      ...
    }:
    {
      config =
        let
          matugenTemplate = pkgs.writeTextFile {
            name = "matugen-template.nix";
            text = # nix
              ''
                {
                  background = "{{ colors.background.default.hex }}";
                  error = "{{ colors.error.default.hex }}";
                  error_container = "{{ colors.error_container.default.hex }}";
                  inverse_on_surface = "{{ colors.inverse_on_surface.default.hex }}";
                  inverse_primary = "{{ colors.inverse_primary.default.hex }}";
                  inverse_surface = "{{ colors.inverse_surface.default.hex }}";
                  on_background = "{{ colors.on_background.default.hex }}";
                  on_error = "{{ colors.on_error.default.hex }}";
                  on_error_container = "{{ colors.on_error_container.default.hex }}";
                  on_primary = "{{ colors.on_primary.default.hex }}";
                  on_primary_container = "{{ colors.on_primary_container.default.hex }}";
                  on_primary_fixed = "{{ colors.on_primary_fixed.default.hex }}";
                  on_primary_fixed_variant = "{{ colors.on_primary_fixed_variant.default.hex }}";
                  on_secondary = "{{ colors.on_secondary.default.hex }}";
                  on_secondary_container = "{{ colors.on_secondary_container.default.hex }}";
                  on_secondary_fixed = "{{ colors.on_secondary_fixed.default.hex }}";
                  on_secondary_fixed_variant = "{{ colors.on_secondary_fixed_variant.default.hex }}";
                  on_surface = "{{ colors.on_surface.default.hex }}";
                  on_surface_variant = "{{ colors.on_surface_variant.default.hex }}";
                  on_tertiary = "{{ colors.on_tertiary.default.hex }}";
                  on_tertiary_container = "{{ colors.on_tertiary_container.default.hex }}";
                  on_tertiary_fixed = "{{ colors.on_tertiary_fixed.default.hex }}";
                  on_tertiary_fixed_variant = "{{ colors.on_tertiary_fixed_variant.default.hex }}";
                  outline = "{{ colors.outline.default.hex }}";
                  outline_variant = "{{ colors.outline_variant.default.hex }}";
                  primary = "{{ colors.primary.default.hex }}";
                  primary_container = "{{ colors.primary_container.default.hex }}";
                  primary_fixed = "{{ colors.primary_fixed.default.hex }}";
                  primary_fixed_dim = "{{ colors.primary_fixed_dim.default.hex }}";
                  scrim = "{{ colors.scrim.default.hex }}";
                  secondary = "{{ colors.secondary.default.hex }}";
                  secondary_container = "{{ colors.secondary_container.default.hex }}";
                  secondary_fixed = "{{ colors.secondary_fixed.default.hex }}";
                  secondary_fixed_dim = "{{ colors.secondary_fixed_dim.default.hex }}";
                  shadow = "{{ colors.shadow.default.hex }}";
                  surface = "{{ colors.surface.default.hex }}";
                  surface_bright = "{{ colors.surface_bright.default.hex }}";
                  surface_container = "{{ colors.surface_container.default.hex }}";
                  surface_container_high = "{{ colors.surface_container_high.default.hex }}";
                  surface_container_highest = "{{ colors.surface_container_highest.default.hex }}";
                  surface_container_low = "{{ colors.surface_container_low.default.hex }}";
                  surface_container_lowest = "{{ colors.surface_container_lowest.default.hex }}";
                  surface_dim = "{{ colors.surface_dim.default.hex }}";
                  surface_tint = "{{ colors.surface_tint.default.hex }}";
                  surface_variant = "{{ colors.surface_variant.default.hex }}";
                  tertiary = "{{ colors.tertiary.default.hex }}";
                  tertiary_container = "{{ colors.tertiary_container.default.hex }}";
                  tertiary_fixed = "{{ colors.tertiary_fixed.default.hex }}";
                  tertiary_fixed_dim = "{{ colors.tertiary_fixed_dim.default.hex }}";

                  rosewater = "{{ colors.rosewater.default.hex }}";
                  flamingo = "{{ colors.flamingo.default.hex }}";
                  pink = "{{ colors.pink.default.hex }}";
                  mauve = "{{ colors.mauve.default.hex }}";
                  red = "{{ colors.red.default.hex }}";
                  maroon = "{{ colors.maroon.default.hex }}";
                  peach = "{{ colors.peach.default.hex }}";
                  yellow = "{{ colors.yellow.default.hex }}";
                  green = "{{ colors.green.default.hex }}";
                  teal = "{{ colors.teal.default.hex }}";
                  sky = "{{ colors.sky.default.hex }}";
                  sapphire = "{{ colors.sapphire.default.hex }}";
                  blue = "{{ colors.blue.default.hex }}";
                  lavender = "{{ colors.lavender.default.hex }}";
                }
              '';
          };
          templateOut = "/tmp/theme.nix";
          matugenConfig = (pkgs.formats.toml { }).generate "config.toml" {
            config = {
              version_check = false;
              caching = false;

              expr_prefix = "{{";
              expr_postfix = "}}";
              block_prefix = "<*";
              block_postfix = "*>";

              custom_colors = {
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
              };
            };

            templates.theme = {
              input_path = matugenTemplate;
              output_path = templateOut;
            };
          };
          wallpaper = builtins.path {
            path = config.prefs.theme.wallpaper;
            name = "wallpaper";
          };
          colors =
            (pkgs.runCommand "matugen-theme"
              {
                matugenConfig = matugenConfig;
                wallpaper = wallpaper;
              }
              ''
                ${pkgs.matugen}/bin/matugen --config $matugenConfig image $wallpaper
                mv ${templateOut} $out
              ''
            )
            |> import;
        in
        {
          themesEnabled = true;
          prefs.theme.colors = colors;
        };
    };
}
