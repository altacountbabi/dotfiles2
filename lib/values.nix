# Basic constants

{ final, prev, ... }:

let
  inherit (final) mkMerge;
in
rec {
  # When the block has a `_type` attribute in the NixOS
  # module system, anything not immediately relevant is
  # silently ignored. We can make use of that by adding
  # a `__functor` attribute, which lets us call the set.
  merge = mkMerge [ ] // {
    __functor =
      self: next:
      self
      // {
        # Technically, `contents` is implementation defined
        # but nothing ever happens, so we can rely on this.
        contents = self.contents ++ [ next ];
      };
  };

  deepMergeAttrs =
    let
      f =
        let
          go =
            path: values:
            if prev.length values == 1 then
              prev.head values
            else
              let
                rhs = prev.elemAt values 0;
                lhs = prev.elemAt values 1;
              in
              if prev.isAttrs lhs && prev.isAttrs rhs then
                prev.zipAttrsWith (n: vs: go (path ++ [ n ]) vs) values
              else if prev.isList lhs && prev.isList rhs then
                lhs ++ rhs
              else
                rhs;
        in
        lhs: rhs: go [ ] [ rhs lhs ];
    in
    prev.foldl' f { };

  enabled = merge { enable = true; };
  disabled = merge { enable = false; };

  genPorts =
    start: services:
    services
    |> prev.imap0 (
      i: service: {
        name = service;
        value = start + i;
      }
    )
    |> prev.listToAttrs;

  rofiLit = value: {
    _type = "literal";
    inherit value;
  };
}
