# Patch INI generator to interpret `null` as nothing instead of a string literal "null"

{ final, ... }:

let
  inherit (final)
    concatMapStringsSep
    concatStringsSep
    recursiveUpdate
    addErrorContext
    replaceStrings
    mapAttrsToList
    isDerivation
    functionArgs
    splitString
    reverseList
    isFunction
    isString
    hasInfix
    isFloat
    isAttrs
    flatten
    toList
    length
    isPath
    isList
    filter
    escape
    isInt
    foldl
    tail
    last
    init
    head
    split
    ;

  inherit (final.strings) escapeNixIdentifier floatToString;
  inherit (final.generators) toINI;
in
rec {
  toPretty =
    {
      allowPrettyValues ? false,
      multiline ? true,
      indent ? "",
    }:
    let
      go =
        indent: v:
        let
          introSpace = if multiline then "\n${indent}  " else " ";
          outroSpace = if multiline then "\n${indent}" else " ";
        in
        if isInt v then
          toString v
        # toString loses precision on floats, so we use toJSON instead. This isn't perfect
        # as the resulting string may not parse back as a float (e.g. 42, 1e-06), but for
        # pretty-printing purposes this is acceptable.
        else if isFloat v then
          builtins.toJSON v
        else if isString v then
          let
            lines = filter (v: !isList v) (split "\n" v);
            escapeSingleline = escape [
              "\\"
              "\""
              "\${"
            ];
            escapeMultiline = replaceStrings [ "\${" "''" ] [ "''\${" "'''" ];
            singlelineResult = "\"" + concatStringsSep "\\n" (map escapeSingleline lines) + "\"";
            multilineResult =
              let
                escapedLines = map escapeMultiline lines;
                # The last line gets a special treatment: if it's empty, '' is on its own line at the "outer"
                # indentation level. Otherwise, '' is appended to the last line.
                lastLine = last escapedLines;
              in
              "''"
              + introSpace
              + concatStringsSep introSpace (init escapedLines)
              + (if lastLine == "" then outroSpace else introSpace + lastLine)
              + "''";
          in
          if multiline && length lines > 1 then multilineResult else singlelineResult
        else if true == v then
          "true"
        else if false == v then
          "false"
        else if null == v then
          "null"
        else if isPath v then
          toString v
        else if isList v then
          if v == [ ] then
            "[ ]"
          else
            "[" + introSpace + concatMapStringsSep introSpace (go (indent + "  ")) v + outroSpace + "]"
        else if isFunction v then
          let
            fna = functionArgs v;
            showFnas = concatStringsSep ", " (
              mapAttrsToList (name: hasDefVal: if hasDefVal then name + "?" else name) fna
            );
          in
          if fna == { } then "<function>" else "<function, args: {${showFnas}}>"
        else if isAttrs v then
          # apply pretty values if allowed
          if allowPrettyValues && v ? __pretty && v ? val then
            v.__pretty v.val
          else if v == { } then
            "{ }"
          else if v ? type && v.type == "derivation" then
            "<derivation ${v.name or "???"}>"
          else
            "{"
            + introSpace
            + concatStringsSep introSpace (
              mapAttrsToList (
                name: value:
                "${escapeNixIdentifier name} = ${
                  addErrorContext "while evaluating an attribute `${name}`" (go (indent + "  ") value)
                };"
              ) v
            )
            + outroSpace
            + "}"
        else
          abort "generators.toPretty: should never happen (v = ${v})";
    in
    go indent;

  mkValueStringDefault =
    { }:
    v:
    let
      err = t: v: abort ("generators.mkValueStringDefault: " + "${t} not supported: ${toPretty { } v}");
    in
    if isInt v then
      toString v
    # convert derivations to store paths
    else if isDerivation v then
      toString v
    # we default to not quoting strings
    else if isString v then
      v
    # isString returns "1", which is not a good default
    else if true == v then
      "true"
    # here it returns to "", which is even less of a good default
    else if false == v then
      "false"
    else if null == v then
      ""
    # if you have lists you probably want to replace this
    else if isList v then
      err "lists" v
    # same as for lists, might want to replace
    else if isAttrs v then
      err "attrsets" v
    # functions can’t be printed of course
    else if isFunction v then
      err "functions" v
    # Floats currently can't be converted to precise strings,
    # condition warning on nix version once this isn't a problem anymore
    # See https://github.com/NixOS/nix/pull/3480
    else if isFloat v then
      floatToString v
    else
      err "this value is" (toString v);

  mkKeyValueDefault =
    {
      mkValueString ? mkValueStringDefault { },
    }:
    sep: k: v:
    "${escape [ sep ] k}${sep}${mkValueString v}";

  toGitINI =
    attrs:
    let
      mkSectionName =
        name:
        let
          containsQuote = hasInfix ''"'' name;
          sections = splitString "." name;
          section = head sections;
          subsections = tail sections;
          subsection = concatStringsSep "." subsections;
        in
        if containsQuote || subsections == [ ] then name else ''${section} "${subsection}"'';

      mkValueString =
        v:
        let
          escapedV = ''"${replaceStrings [ "\n" "	" ''"'' "\\" ] [ "\\n" "\\t" ''\"'' "\\\\" ] v}"'';
        in
        mkValueStringDefault { } (if isString v then escapedV else v);

      # generation for multiple ini values
      mkKeyValue =
        k: v:
        let
          mkKeyValue = mkKeyValueDefault { inherit mkValueString; } " = " k;
        in
        concatStringsSep "\n" (map (kv: "\t" + mkKeyValue kv) (toList v));

      # converts { a.b.c = 5; } to { "a.b".c = 5; } for toINI
      gitFlattenAttrs =
        let
          recurse =
            path: value:
            if isAttrs value && !isDerivation value then
              mapAttrsToList (name: value: recurse ([ name ] ++ path) value) value
            else if length path > 1 then
              {
                ${concatStringsSep "." (reverseList (tail path))}.${head path} = value;
              }
            else
              {
                ${head path} = value;
              };
        in
        attrs: foldl recursiveUpdate { } (flatten (recurse [ ] attrs));

      toINI_ = toINI { inherit mkKeyValue mkSectionName; };
    in
    toINI_ (gitFlattenAttrs attrs);
}
