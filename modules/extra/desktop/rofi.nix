{ inputs, ... }:

{
  flake.nixosModules.rofi =
    {
      config,
      pkgs,
      ...
    }:
    let
      wrapped =
        (inputs.wrappers.wrapperModules.rofi.apply {
          inherit pkgs;

          extraFlags = {
            "-display-drun" = "Run";
          };
          theme =
            let
              mkLiteral = value: {
                _type = "literal";
                inherit value;
              };
            in
            with config.prefs.theme.colors;
            {
              configuration = {
                font = "${config.fonts.fontconfig.defaultFonts.monospace |> builtins.head} 12";
                show-icons = true;
              };

              "*" = {
                border = 0;
                margin = 0;
                padding = 0;
                spacing = 0;

                width = 750;

                bg = mkLiteral base;
                bg-alt = mkLiteral surface0;
                fg = mkLiteral text;
                fg-alt = mkLiteral subtext0;

                background-color = mkLiteral "@bg";
                text-color = mkLiteral "@fg";
              };

              window = {
                transparency = "real";
                border-radius = mkLiteral "10px";
              };

              mainbox.children =
                [
                  "inputbar"
                  "listview"
                ]
                |> map mkLiteral;

              inputbar = {
                background-color = mkLiteral "@bg-alt";
                children =
                  [
                    "prompt"
                    "entry"
                  ]
                  |> map mkLiteral;
              };

              entry = {
                background-color = mkLiteral "inherit";
                padding = mkLiteral "12px 3px";
              };

              prompt = {
                background-color = mkLiteral "inherit";
                padding = mkLiteral "12px";
              };

              listview.lines = 8;

              element.children =
                [
                  "element-icon"
                  "element-text"
                ]
                |> map mkLiteral;

              "element-icon selected, element-text selected" = {
                background-color = mkLiteral surface1;
              };

              element-icon = {
                padding = mkLiteral "10px 10px";
                size = mkLiteral "1em";
              };

              element-text = {
                padding = mkLiteral "10px 0";
                text-color = mkLiteral "@fg-alt";
              };

              "element-text selected" = {
                text-color = mkLiteral "@fg";
              };
            };
        }).wrapper;
    in
    {
      environment.systemPackages = [
        wrapped
      ];
    };
}
