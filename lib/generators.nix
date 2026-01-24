{ prev, ... }:

rec {
  hideDesktop =
    {
      pkgs,
      package,
    }:
    (pkgs.symlinkJoin {
      name = "${package.pname or package.name}-hidden";
      paths = [ package ];
      postBuild = ''
        rm -rf $out/share/applications/*.desktop
      '';
    });

  toHyprconf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      inherit (prev)
        all
        concatMapStringsSep
        concatStrings
        concatStringsSep
        filterAttrs
        foldl
        generators
        hasPrefix
        isAttrs
        isList
        mapAttrsToList
        replicate
        attrNames
        ;

      initialIndent = concatStrings (replicate indentLevel "  ");

      toHyprconf' =
        indent: attrs:
        let
          isImportantField =
            n: _: foldl (acc: prev: if hasPrefix prev n then true else acc) false importantPrefixes;
          importantFields = filterAttrs isImportantField attrs;
          withoutImportantFields = fields: removeAttrs fields (attrNames importantFields);

          allSections = filterAttrs (_: v: isAttrs v || isList v) attrs;
          sections = withoutImportantFields allSections;

          mkSection =
            n: attrs:
            if isList attrs then
              let
                separator = if all isAttrs attrs then "\n" else "";
              in
              (concatMapStringsSep separator (a: mkSection n a) attrs)
            else if isAttrs attrs then
              ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              ''
            else
              toHyprconf' indent { ${n} = attrs; };

          mkFields = generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = filterAttrs (_: v: !(isAttrs v || isList v)) attrs;
          fields = withoutImportantFields allFields;
        in
        mkFields importantFields
        + concatStringsSep "\n" (mapAttrsToList mkSection sections)
        + mkFields fields;
    in
    toHyprconf' initialIndent attrs;

  mkNushellInline = expr: prev.setType "nushell-inline" { inherit expr; };

  isNushellInline = prev.isType "nushell-inline";

  toNushell =
    {
      indent ? "",
      multiline ? true,
      asBindings ? false,
    }@args:
    v:
    let
      innerIndent = "${indent}    ";
      introSpace =
        if multiline then
          ''

            ${innerIndent}''
        else
          " ";
      outroSpace =
        if multiline then
          ''

            ${indent}''
        else
          " ";
      innerArgs = args // {
        indent = if asBindings then indent else innerIndent;
        asBindings = false;
      };
      concatItems = prev.concatStringsSep introSpace;

      generatedBindings =
        assert prev.assertMsg (badVarNames == [ ])
          "Bad Nushell variable names: ${prev.generators.toPretty { } badVarNames}";
        prev.concatStrings (
          prev.mapAttrsToList (key: value: ''
            ${indent}let ${key} = ${toNushell innerArgs value}
          '') v
        );

      isBadVarName =
        name:
        # Extracted from https://github.com/nushell/nushell/blob/ebc7b80c23f777f70c5053cca428226b3fe00d30/crates/nu-parser/src/parser.rs#L33
        # Variables with numeric or even empty names are allowed. The only requisite is not containing any of the following characters
        let
          invalidVariableCharacters = ".[({+-*^/=!<>&|";
        in
        prev.match "^[$]?[^${prev.escapeRegex invalidVariableCharacters}]+$" name == null;
      badVarNames = prev.filter isBadVarName (builtins.attrNames v);
    in
    if asBindings then
      generatedBindings
    else if v == null then
      "null"
    else if prev.isInt v || prev.isFloat v || prev.isString v || prev.isBool v then
      prev.strings.toJSON v
    else if prev.isList v then
      (
        if v == [ ] then
          "[]"
        else
          "[${introSpace}${concatItems (map (value: "${toNushell innerArgs value}") v)}${outroSpace}]"
      )
    else if prev.isAttrs v then
      (
        if isNushellInline v then
          "(${v.expr})"
        else if v == { } then
          "{}"
        else if prev.isDerivation v then
          toString v
        else
          "{${introSpace}${
            concatItems (
              prev.mapAttrsToList (key: value: "${prev.strings.toJSON key}: ${toNushell innerArgs value}") v
            )
          }${outroSpace}}"
      )
    else
      throw "nushell.toNushell: type ${prev.typeOf v} is unsupported";
}
