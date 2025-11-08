{
  flake.nixosModules.sddm =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      qt.enable = true;
      services.displayManager.sddm = {
        package = pkgs.kdePackages.sddm;
        enable = true;
        wayland.enable = true;
        settings = {
          Wayland.CompositorCommand =
            let
              westonTransformNames = {
                "normal" = "normal";
                "90" = "rotate-90";
                "180" = "rotate-180";
                "270" = "rotate-270";
                "flipped" = "flipped";
                "flipped-90" = "flipped-rotate-90";
                "flipped-180" = "flipped-rotate-180";
                "flipped-270" = "flipped-rotate-270";
              };
              monitors = config.prefs.monitors |> lib.filterAttrs (_: x: x.enable);

              westonConfig = lib.generators.toINI { listsAsDuplicateKeys = true; } {
                output = {
                  name = builtins.attrNames monitors;
                  mode =
                    builtins.attrValues monitors
                    |> map (
                      x: "${toString x.width}x${toString x.height}@${x.refreshRate |> lib.strings.floatToString}"
                    );
                  scale = builtins.attrValues monitors |> map (x: x.scale);
                  transform =
                    builtins.attrValues monitors |> map (x: westonTransformNames.${toString x.transform} or "normal");
                };

                keyboard = {
                  keymap_layout = "us";
                  keymap_model = "pc104";
                  keymap_options = "terminate:ctrl_alt_bksp";
                };

                libinput = {
                  enable-tap = true;
                  left-handed = false;
                  accel-profile = "flat";
                };

                # shell = {
                #   cursor-theme = "Adwaita";
                #   cursor-size = 24;
                # };
              };
            in
            "${pkgs.weston}/bin/weston --shell=kiosk -c ${builtins.toFile "weston.ini" westonConfig}";
        };
      };
    };
}
