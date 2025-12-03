final: prev:

{
  mkOpt =
    type: default: description:
    prev.mkOption {
      inherit type default description;
    };
  mkOpt' =
    type: description:
    prev.mkOption {
      inherit type description;
    };

  mkConst =
    value:
    prev.mkOption {
      default = value;
      readOnly = true;
    };
}
