#!/usr/bin/env nu

def main [
  config_path: path
  overlay_config_path: path,
] {
  let overlay = open -r $overlay_config_path | from json
  let config = try { open -r $config_path } catch { "" } | from json | default {}

  mkdir ($config_path | path dirname)

  $config
    | merge deep $overlay
    | to json --indent 2
    | save -f $config_path
}
