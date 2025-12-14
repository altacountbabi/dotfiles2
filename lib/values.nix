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

  enabled = merge { enable = true; };
  disabled = merge { enable = false; };

  genPorts =
    start: services:
    builtins.listToAttrs (
      prev.imap0 (i: service: {
        name = service;
        value = start + i;
      }) services
    );
}
