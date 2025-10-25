# Add shorthand for `mkOption`

final: prev:

let
  inherit (final) mkOption;
in
{
  mkOpt =
    type: default: description:
    mkOption {
      inherit type default description;
    };
  mkOpt' =
    type: description:
    mkOption {
      inherit type description;
    };
}
