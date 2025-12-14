#!/usr/bin/env nu

# A post-modern text editor.
# Blaž Hrastnik <blaz@mxxn.io>
def v [
  --tutor # Loads the tutorial
  --health: string@languages # Checks for potential errors in editor setup `<string>` can be a language or one of 'clipboard', 'languages' or 'all'. 'all' is the default if not specified.
  --grammar (-g): string # {fetch|build} Fetches or builds tree-sitter grammars listed in languages.toml,
  --config (-c): path # Specifies a file to use for configuration. (default file: ~/.cache/helix/helix.log)
  --log: path # Specifies a file to use for logging

  --version (-V) # Prints version information

  --vsplit # Splits all given files vertically into different windows
  --hsplit # Splits all given files horizontally into different windows

  --working-dir (-w): path # Specify an initial working directory

  --v # Sets verbosity level to 1
  --vv # Sets verbosity level to 2
  --vvv # Sets verbosity level to 3

  ...files: path
] {
  if $tutor {
    ^hx --tutor
    return
  }

  if ($health | is-not-empty) {
    ^hx --health $health
    return
  }

  if ($grammar == "fetch") {
    ^hx --grammar fetch
    return
  }
  if ($grammar == "build") {
    ^hx --grammar build
    return
  }

  if $version {
    ^hx --version
    return
  }

  mut flags = $files;

  if ($config | is-not-empty) {
    $flags = $flags | prepend ["--config" $config]
  }

  if ($log | is-not-empty) {
    $flags = $flags | prepend ["--log" $log]
  }

  if $vsplit {
    $flags = $flags | prepend "--vsplit"
  }
  if $hsplit {
    $flags = $flags | prepend "--hsplit"
  }

  if $vvv {
    $flags = $flags | prepend "-vvv"
  }
  if $vv {
    $flags = $flags | prepend "-vv"
  }
  if $v {
    $flags = $flags | prepend "-v"
  }

  if ($working_dir | is-not-empty) {
    $flags = $flags | prepend ["--working-dir" $working_dir]
  }

  if ($files | is-empty) {
    ^hx ...$flags .
  } else {
    ^hx ...$flags
  }
}

def languages [] {
  let languages: list<string> = ^hx --health
    | lines
    | skip until {|x| $x | str starts-with "Language  " }
    | skip 1
    | parse "{name} {_}"
    | where name != ""
    | values
    | flatten
    | prepend ["all", "languages", "clipboard"];

  {
    options: {
      case_sensitive: true,
      completion_algorithm: fuzzy,
      sort: false,
    },
    completions: $languages
  }
}
