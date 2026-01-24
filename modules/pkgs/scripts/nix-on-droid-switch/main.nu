#!/usr/bin/env nu

export def switch [
  --host: string,
  --flake: path,

  ...rest
] {
  let host = if ($host | is-empty) {
    open /etc/hostname | str trim
  } else {
    $host
  }
  let flake = if ($flake | is-empty) {
    # Reuse the `NH_FLAKE` env var, there's no point in making a new one
    $env.NH_FLAKE
  } else {
    $flake
  }

  log "Building nix-on-droid configuration"
  let out = "/tmp" | path join (random chars -l 10)
  (
    nom build
      $"($flake)#nixOnDroidConfigurations.($host).activationPackage"
      --impure # nix-on-droid requires this
      -o $out
      ...$rest
  )

  log "Activating configuration"
  let path = $out | path join "activate"

  if not ($path | path exists) {
    log --level error $"Activation script not found at ($path)"
  }

  run-external $path
}

export alias main = switch
