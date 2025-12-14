#!/usr/bin/env nu

# TODO: Allow for remote -> local and maybe even remote (a) -> remote (b)

# Stream a tarball over ssh to copy multiple files far faster than scp
export def tscp [
  src: path,
  dest_host: string,
  dest_path: path
] {
  let is_dir = ($src | path type) == "dir"

  let mkdir_cmd = $"mkdir ($dest_path); "
  let tar_cmd = $"tar -C ($dest_path) -xf -"

  let host_cmd = $"(if $is_dir { $mkdir_cmd } else { "" })($tar_cmd)"

  tar -C $src -cf - . | pv | ssh $dest_host $host_cmd
}

export alias main = tscp

