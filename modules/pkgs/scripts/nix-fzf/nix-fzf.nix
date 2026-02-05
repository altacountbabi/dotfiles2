{ self, inputs, ... }:

let
  mkOptions =
    {
      opts ?
        (inputs.nixpkgs.lib.nixosSystem {
          inherit (pkgs.stdenv.hostPlatform) system;
          modules = [
            { system.stateVersion = "26.05"; }
          ];
        }).options,
      pkgs,
      lib,
      ...
    }:
    let
      isOption = x: lib.isAttrs x && x ? _type && x._type == "option";

      typeSerializers = {
        null = x: null;
        bool = x: x;
        int = x: x;
        float = x: x;
        string = x: x;
        path = x: toString x;
        list = x: map serializeValue x;
        attrs =
          x: if lib.isDerivation x then x.name or "<derivation>" else lib.mapAttrs (_: serializeValue) x;
      };

      typePredicates = {
        null = x: x == null;
        bool = lib.isBool;
        int = lib.isInt;
        float = lib.isFloat;
        string = lib.isString;
        path = lib.isPath;
        list = lib.isList;
        attrs = lib.isAttrs;
      };

      getType =
        x: lib.findFirst (typeName: typePredicates.${typeName} x) null (lib.attrNames typePredicates);

      serializeValue =
        x:
        let
          typeName = getType x;
        in
        if typeName == null then null else typeSerializers.${typeName} x;

      isSerializableSafe =
        x:
        let
          result = builtins.tryEval (serializeValue x != null);
        in
        result.success && result.value;

      getDefault =
        opt:
        if opt ? defaultText then
          opt.defaultText
        else
          let
            result = builtins.tryEval (
              if opt ? default && isSerializableSafe opt.default then serializeValue opt.default else null
            );
          in
          if result.success then result.value else null;

      getOptionDetails =
        opt:
        let
          result = builtins.tryEval (
            lib.filterAttrs (k: v: v != null) {
              description = opt.description or null;
              type = opt.type.description or opt.type.name or null;
              default = getDefault opt;
              declarations = opt.declarations or null;
              loc = opt.loc or null;
              readOnly = opt.readOnly or false;
            }
          );
        in
        if result.success then result.value else { };

      skipNames = [
        "assertions"
        "warnings"
      ];
      shouldSkip =
        name: lib.hasPrefix "_module" name || lib.hasPrefix "_" name || lib.elem name skipNames;

      collectOptions =
        prefix: set:
        lib.foldl' (
          acc: name:
          let
            value = set.${name};
            fullName = if prefix == "" then name else "${prefix}.${name}";
          in
          if shouldSkip fullName then
            acc
          else if isOption value then
            let
              details = getOptionDetails value;
              isInternal = value.internal or false;
            in
            if isInternal then acc else acc // { ${fullName} = details; }
          else if lib.isAttrs value && !lib.isDerivation value then
            acc // collectOptions fullName value
          else
            acc
        ) { } (lib.attrNames set);
    in
    collectOptions "" opts;
in
{
  flake.nixosModules = self.mkModule {
    path = ".programs.nix-fzf";

    opts =
      { mkOpt, types, ... }:
      {
        enable = mkOpt types.bool false "Enable nix-fzf";
      };

    cfg =
      {
        options,
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        index' = self.packages.${pkgs.stdenv.hostPlatform.system}.indexCached;
        index = pkgs.linkFarm "index" [
          {
            name = "pkgs.json";
            path = "${index'}/pkgs.json";
          }
          {
            name = "lib.json";
            path = "${index'}/lib.json";
          }
          {
            name = "pkgsCompletions.json";
            path = "${index'}/pkgsCompletions.json";
          }
          {
            name = "options.json";
            path = (pkgs.formats.json { }).generate "options.json" (mkOptions {
              opts = options;
              inherit pkgs lib;
            });
          }
        ];

        wrapped = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.nix-fzf;
          args = [ (toString index) ];
        };
      in
      {
        config = lib.mkIf cfg.enable {
          environment.systemPackages = [
            wrapped
          ];
        };
      };
  };

  perSystem =
    { pkgs, lib, ... }:
    let
      packages =
        pkgs
        |> lib.mapAttrsToList (
          k: v:
          let
            try = builtins.tryEval v;
            broken = !try.success || (try.success && (try.value.meta.broken or false));
            insecure = try.success && (try.value.meta.insecure or false);
            unfree = try.success && (try.value.meta.license.free or false == false);

            description = if try.success then (try.value.meta.description or null) else null;
            version = if try.success then (try.value.meta.version or null) else null;
          in
          {
            name = k;
            value = {
              value = k;
              inherit
                version
                description
                broken
                insecure
                unfree
                ;
            };
          }
        )
        |> lib.listToAttrs;

      noogleDataPkg = inputs.noogle.packages.${pkgs.stdenv.hostPlatform.system}.data-json;

      pkgsCompletions =
        packages
        |> lib.attrValues
        |> map (pkg: {
          inherit (pkg) value;
          description =
            if pkg.broken then
              "(Broken)"
            else
              let
                prefix = lib.optionalString pkg.broken "(Broken)${
                  lib.optionalString (pkg.description != null) "  "
                }";
                desc = if (pkg.description or null) != null then pkg.description else "No description";
              in
              prefix + desc;

          style =
            if pkg.broken then
              "red"
            else if pkg.insecure then
              "yellow"
            else
              null;

        })
        |> lib.sort (a: b: a.value < b.value);
    in
    {
      packages.index =
        let
          json = (pkgs.formats.json { }).generate;
        in
        [
          (json "pkgs.json" packages)
          (json "options.json" (mkOptions {
            inherit pkgs lib;
          }))
          (json "pkgsCompletions.json" pkgsCompletions)
          (noogleDataPkg.overrideAttrs {
            name = "lib.json";
          })
        ]
        |> pkgs.linkFarmFromDrvs "index";

      packages.indexCached =
        builtins.readDir inputs.nix-index
        |> lib.attrNames
        |> map (x: {
          name = x;
          path = "${inputs.nix-index}/${x}";
        })
        |> pkgs.linkFarm "cached-index";

      packages.nix-fzf = self.lib.nushellScript {
        inherit pkgs;
        name = "nix-fzf";
        packages = with pkgs; [
          mcat
          bat
          fzf
        ];
        text = builtins.readFile ./main.nu;
      };
    };
}
