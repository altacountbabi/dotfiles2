#!/usr/bin/env nu

export def rofi-fd [
  location: path = "~"
] {
  let path = fd . $location
    | lines
    | each {|path|
      let ext = ($path | path parse | get extension | default "")
      let icon = match $ext {
        "txt" | "md" | "rst" => "text-x-generic"
        "png" | "jpg" | "jpeg" | "webp" | "bmp" => "image-x-generic"
        "mp4" | "mkv" | "webm" | "mov" | "gif" => "video-x-generic"
        "pdf" => "application-pdf"
        "zip" | "tar" | "gz" | "xz" | "zstd" => "package-x-generic"
        _ => (if ($path | path type) == "dir" {
          "folder"
        } else {
          "text-x-generic"
        })
      }

      $"($path)\u{0}icon\u{1f}($icon)"
    }
    | to text
    | rofi -dmenu -i -p ">"

  if ($path | is-not-empty) {
    xdg-open $path
  }
}

export alias main = rofi-fd
