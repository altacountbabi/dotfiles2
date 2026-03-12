{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.btop";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      with types;
      let
        kvFormat = (pkgs.formats.keyValue { }).type.nestedTypes.elemType;
      in
      {
        enable = mkOpt bool false "Enable btop";
        package = mkOpt package pkgs.btop "Btop package";
        settings = mkOpt (attrsOf (either kvFormat (listOf kvFormat))) { } "Btop settings";
        themes = mkOpt (attrsOf (attrsOf str)) { } "Btop themes";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        wrapped =
          (self.wrapperModules.btop.apply {
            inherit pkgs;
            filesToExclude = [ "share/applications/*.desktop" ];

            inherit (cfg) settings themes;
          }).wrapper;
      in
      {
        config = lib.mkIf cfg.enable {
          environment.systemPackages = [ wrapped ];

          programs.btop = lib.mkDefault {
            settings = {
              shown_boxes = [
                "cpu"
                "mem"
                "proc"
              ];
              vim_keys = true;
              color_theme = "nix";

              # Memory
              show_disks = false;

              # Processes
              proc_tree = true;
              proc_gradient = false;
              proc_filter_kernel = true;
              proc_aggregate = true;
            };
            themes.nix = with config.prefs.theme.colors; {
              main_bg = base;
              main_fg = text;
              title = text;
              hi_fg = accent;
              selected_bg = surface1;
              selected_fg = accent;
              inactive_fg = overlay1;
              graph_text = rosewater;
              meter_bg = surface1;
              proc_misc = rosewater;

              cpu_box = accent;
              mem_box = accent;
              net_box = accent;
              proc_box = accent;

              div_line = overlay0;

              temp_start = green;
              temp_mid = yellow;
              temp_end = red;

              cpu_start = teal;
              cpu_mid = sapphire;
              cpu_end = lavender;

              free_start = mauve;
              free_mid = lavender;
              free_end = blue;

              cached_start = sapphire;
              cached_mid = blue;
              cached_end = lavender;

              available_start = peach;
              available_mid = maroon;
              available_end = red;

              used_start = green;
              used_mid = teal;
              used_end = sky;

              download_start = peach;
              download_mid = maroon;
              download_end = red;

              upload_start = green;
              upload_mid = teal;
              upload_end = sky;

              process_start = accent;
              process_mid = accent;
              process_end = accent;
            };
          };
        };
      };
  };

  # TODO: Clean up and upstream
  flake.wrapperModules.btop = inputs.wrappers.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    let
      kvFormat = config.pkgs.formats.keyValue {
        mkKeyValue =
          k: v:
          let
            inherit (lib)
              isDerivation
              isFloat
              isInt
              isList
              isString
              concatStringsSep
              ;
            inherit (lib.generators) toPretty;
            inherit (lib.strings) floatToString;

            mkValueString =
              v:
              let
                err = t: v: abort ("generators.mkValueStringDefault: " + "${t} not supported: ${toPretty { } v}");
              in
              if isInt v then
                toString v
              else if isFloat v then
                floatToString v
              else if isDerivation v then
                toString v
              else if isString v then
                ''"${v}"''
              else if true == v then
                "true"
              else if false == v then
                "false"
              else if null == v then
                "null"
              else if isList v then
                let
                  list = concatStringsSep " " (map toString v);
                in
                ''"${list}"''
              else
                err "this value is" (toString v);
          in
          "${k}=${mkValueString v}";
      };
    in
    {
      _class = "wrapper";
      options = {
        settings = lib.mkOption {
          type =
            let
              atom = kvFormat.type.nestedTypes.elemType;
            in
            with lib.types;
            attrsOf (either atom (listOf atom));
          default = { };
          description = "Btop settings";
        };
        themes = lib.mkOption {
          type = with lib.types; attrsOf (attrsOf str);
          default = { };
          description = "Btop themes";
          example = ''
            themes.nix = {
              main_bg = "#000000";
              # ...
            };
          '';
        };

        "btop.conf" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.path = kvFormat.generate "btop.conf" config.settings;
          description = "Configuration for btop.";
        };
      };

      config = {
        flags = {
          "--config" = toString config."btop.conf".path;
          "--themes-dir" = lib.pipe config.themes [
            (lib.mapAttrs (
              _: v:
              lib.concatMapAttrs (name: value: {
                "theme[${name}]" = value;
              }) v
            ))
            (lib.mapAttrsToList (
              k: v: rec {
                name = "${k}.theme";
                path = kvFormat.generate name v;
              }
            ))
            (config.pkgs.linkFarm "btop-themes")
            toString
          ];
        };

        package = config.pkgs.btop;

        meta = {
          maintainers = [
            {
              name = "adeci";
              github = "adeci";
              githubId = 80290157;
            }
          ];
          platforms = lib.platforms.linux;
        };
      };
    }
  );
}
