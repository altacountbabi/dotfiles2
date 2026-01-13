export def log [
  --level: string = "info"
  text: string
] {
  let color = match $level {
    "error" => "red"
    "warning" => "yellow"
    "info" => "green"
    "trace" => "magenta"
  }

  print $"(ansi $color)>(ansi reset) ($text)"
}

export def default-to-nixpkgs [package: string]: nothing -> string {
  if ($package | str contains "#") {
    $package
  } else {
    $"nixpkgs#($package)"
  }
}

export def "nom getExe" [...args]: nothing -> path {
  nom build ...$args --no-link

  let tmp = (mktemp -t nix-eval-stdout.XXX)
  (
    nix eval --raw
      --apply '(import (builtins.getFlake "nixpkgs") {}).lib.getExe' --impure
      ...$args
      o> $tmp
      e>| ignore
  )

  let res = open $tmp | str trim
  rm $tmp

  $res
}
