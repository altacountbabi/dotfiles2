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
}
