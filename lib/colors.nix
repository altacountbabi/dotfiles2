{ prev, ... }:

let
  pow =
    base: exponent:
    let
      inherit (prev) mod;
    in
    if exponent > 1 then
      let
        x = pow base (exponent / 2);
        odd_exp = mod exponent 2 == 1;
      in
      x * x * (if odd_exp then base else 1)
    else if exponent == 1 then
      base
    else if exponent == 0 && base == 0 then
      throw "undefined"
    else if exponent == 0 then
      1
    else
      throw "undefined";

  hexToDecMap = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };

  base16To10 = exponent: scalar: scalar * pow 16 exponent;

  hexCharToDec =
    hex:
    let
      inherit (prev) toLower;
      lowerHex = toLower hex;
    in
    if builtins.stringLength hex != 1 then
      throw "Function only accepts a single character."
    else if hexToDecMap ? ${lowerHex} then
      hexToDecMap."${lowerHex}"
    else
      throw "Character ${hex} is not a hexadecimal value.";

  hexToDec =
    hex:
    let
      inherit (prev)
        stringToCharacters
        reverseList
        imap0
        foldl
        ;
      decimals = builtins.map hexCharToDec (stringToCharacters hex);
      decimalsAscending = reverseList decimals;
      decimalsPowered = imap0 base16To10 decimalsAscending;
    in
    foldl builtins.add 0 decimalsPowered;

  hexToRGB =
    hex:
    let
      hexToRGB =
        hex:
        let
          rgbStartIndex = [
            0
            2
            4
          ];
          hexList = builtins.map (x: builtins.substring x 2 hex) rgbStartIndex;
          hexLength = builtins.stringLength hex;
        in
        if hexLength != 6 then
          throw ''
            Unsupported hex string length of ${builtins.toString hexLength}.
            Length must be exactly 6.
          ''
        else
          builtins.map hexToDec hexList;
      list = hexToRGB hex;
    in
    {
      r = builtins.elemAt list 0;
      g = builtins.elemAt list 1;
      b = builtins.elemAt list 2;
    };

  mixChannel =
    a: b: t:
    (a * (1.0 - t) + b * t) |> builtins.floor;

  toHex2 =
    n:
    let
      h = prev.toHexString n;
    in
    if builtins.stringLength h == 1 then "0${h}" else h;

in
{
  # The args are ordered like this to be used for piping: `<base> |> mix <other> <amount>`
  mix =
    other': amount: base':
    let
      base = hexToRGB (builtins.substring 1 6 base');
      other = hexToRGB (builtins.substring 1 6 other');

      red = toHex2 (mixChannel base.r other.r amount);
      green = toHex2 (mixChannel base.g other.g amount);
      blue = toHex2 (mixChannel base.b other.b amount);
    in
    "#${red}${green}${blue}";

  # Strip `#` from the beginning of a hex color
  stripHex = x: prev.substring 1 ((prev.stringLength x) - 1) x;
}
