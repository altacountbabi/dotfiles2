with import <nixpkgs> { };
let
  inherit (lib)
    concatStringsSep
    escape
    flatten
    foldl
    hasInfix
    head
    isAttrs
    isDerivation
    isFloat
    isFunction
    isInt
    isList
    isString
    length
    mapAttrsToList
    recursiveUpdate
    replaceStrings
    reverseList
    splitString
    tail
    toList
    ;

  inherit (lib.strings) floatToString;
  inherit (lib.generators) toINI;

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
in
{
  credential."https://github.com".helper = [
    null
    "gh"
  ];
}
|> toGitINI
