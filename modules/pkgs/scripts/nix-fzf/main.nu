#!/usr/bin/env nu

# TODO: Use a better markdown renderer, mdcat sucks ass

def ansi-wrap [color: string, text: string] {
  $"(ansi $color)($text)(ansi reset)"
}

def section [
  --char: string = "◆",
  text: string
]: nothing -> string {
  ansi-wrap $"blue_bold" $"($char) ($text)"
}

def sections [] {
  $in
    | flatten
    | where ($it | is-not-empty)
    | str join "\n"
}

def description []: string -> string {
  try {
    $in | mdcat --ansi --no-pager -
  } catch {
    $in
  }
  | str replace -a "  " " "
  | indent
}

def indent []: string -> string {
  $in
    | lines
    | each {|x| "  " + $x }
    | str join "\n"
}

def format-code-block [content: string, language: string = "nix"] {
  try { 
    $content | bat --color always --plain --language $language -
  } catch { 
    $content 
  }
}

def "format value" [] {
  let value = $in | default ""
  let type = ($in | describe)

  if $type == "bool" {
    format-code-block ($value | into string)
  } else if $type == "int" or $type == "float" {
    format-code-block ($value | into string)
  } else if $type == "string" {
    format-code-block $'"($value)"'
  } else if $type == "list" {
    let items = ($value | each {|x| $"- ($x)" } | str join "\n")
    format-code-block $items
  } else if $type == "record" {
    format-code-block ($value | to yaml) "yaml"
  } else {
    format-code-block ($value | to yaml)
  }
}

def "format option" [name: string, index: record]: nothing -> string {
  let opt = $index | get $name

  [
    # Header
    [
      (section --char ">" $name)
      " "
    ]

    # Description
    (if ($opt.description | is-not-empty) {
      [
        (section "Description")
        ($opt.description | description)
        " "
      ]
    })

    # Type
    (if ($opt.type | is-not-empty) {
      [
        (section "Type")
        (ansi-wrap "yellow" $opt.type | indent)
        " "
      ]
    })

    # Declarations
    (if ($opt.declarations | is-not-empty) {
      [
        (section "Declarations")
        (ansi-wrap "magenta" ($opt.declarations | str join "\n") | indent)
        " "
      ]
    })

    # Default Value
    (if ($opt.default | is-not-empty) {
      [
        (section "Default Value")
        ($opt.default | format value | indent)
        " "
      ]
    })
  ] | sections
}

def "format package" [name: string, index: record]: nothing -> string {
  let pkg = $index | get $name

  let flags = [
    (if ($pkg.broken == true) { (ansi-wrap "red" "broken") })
    (if ($pkg.insecure == true) { (ansi-wrap "yellow" "insecure") })
    (if ($pkg.unfree == true) { (ansi-wrap "magenta" "unfree") })
  ] | where ($it | is-not-empty)

  [
    # Header
    [
      (section --char ">" $name)
      " "
    ]

    # Description
    (if ($pkg.description != null) {
      let desc = $pkg.description
        | lines
        | each {|x| "  " + $x}
        | str join "\n"

      [
        (section "Description")
        $desc
        " "
      ]
    })

    # Flags
    (if ($flags | length) > 0 {
      let flags = "  " + ($flags | str join ", ")

      [
        (section "Flags")
        $flags
        " "
      ]
    })
  ] | sections
}

def "format lib" [name: string, index: list]: nothing -> string {
  let name = $name | str trim --char '\'
  let lib = $index
    | where {|item|
      ($item.meta.path | str join ".") == $name
    }

  let content = $lib.content
  let meta = $lib.meta

  [
    # Header
    [
      (section --char ">" $name)
      " "
    ]

    # Description
    (if ($content.content.0 | is-not-empty) {
      [
        (section "Description")
        ($content.content.0 | description)
        " "
      ]
    })
  ] | sections
}

def format [display: string, index_dir: path] {
  let parsed = $display | str trim --char "'" | parse "<{category}> {name}"

  let category = $parsed.category | first
  let name = $parsed.name | first

  match $category {
    "opt" => {
      let options = (open ($index_dir | path join "options.json"))
      format option $name $options
    },
    "pkg" => {
      let pkgs = (open ($index_dir | path join "pkgs.json"))
      format package $name $pkgs
    },
    "lib" => {
      let lib = (open ($index_dir | path join "lib.json"))
      format lib $name $lib
    },
    _ => (ansi-wrap "red" $"Unknown category: ($category)")
  }
}

export def nix-fzf [index_dir: string] {
  let pkgs = (open ($index_dir | path join "pkgs.json"))
  let lib = (open ($index_dir | path join "lib.json"))
  let options = (open ($index_dir | path join "options.json"))

  let opts_list = ($options | columns | each {|n| "<opt> " + $n })
  let pkgs_list = ($pkgs | columns | each {|n| "<pkg> " + $n })
  let lib_list = ($lib | each {|item| "<lib> " + (if ($item.meta.path | length) > 0 { ($item.meta.path | str join ".") } else { "unknown" }) })
  
  let merged = [$opts_list $pkgs_list $lib_list]
   | flatten
   | sort
   | str join "\n"

  const self = path self
  $env.SHELL = $nu.current-exe
  let selection = (
    $merged
    | fzf
      --ansi
      --preview $"source ($self); format r#'{}'# ($index_dir)"
      --preview-window 'right:70%'
      --bind 'tab:up,shift-tab:down,start:first,change:first'
  )

  if ($selection | is-empty) {
    return
  }

  format $selection $index_dir
}

export alias main = nix-fzf
