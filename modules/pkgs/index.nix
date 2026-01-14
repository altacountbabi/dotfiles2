{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.index =
        let
          index =
            pkgs
            |> lib.mapAttrsToList (
              k: v:
              let
                try = builtins.tryEval v;
                broken = !try.success || (try.success && (try.value.meta.broken or false));
              in
              {
                value = k;
                description =
                  if try.success then
                    let
                      desc = try.value.meta.description or "No description";
                      prefixSpace = if desc != "No description" then " " else "";
                      prefix = lib.optionalString broken "(Broken)${prefixSpace}";
                    in
                    prefix + desc
                  else
                    "(Broken)";
                style = if broken then "red" else null;
              }
            )
            |> lib.strings.toJSON;
        in
        pkgs.writeText "index.json" index;
      packages.indexCached = throw "Not implemented yet";
    };
}
