#!/usr/bin/env nu

def main [
  --dry-run
  --host: string

  config: path
] {
  if not (is-admin) {
    print $"(ansi { fg: red, attr: b })Error: installer must be ran as root.(ansi reset)"
    exit
  }

  let host = if ($host | is-empty) {
    log "Loading flake hosts"

    let flake = nix flake show $config --json --no-write-lock-file | from json;
    let hosts: list<string> = $flake | get nixosConfigurations | columns | where not (($it | str downcase) =~ "iso")

    $hosts | input list --fuzzy "Host"
  } else {
    $host
  }

  let start = (date now);

  if $dry_run {
    log $"Partitioning disk (ansi blue)\(Skipped\)(ansi reset)"
    disko --dry-run --flake $"($config)#($host)"
  } else {
    log $"Partitioning disk"
    disko --flake $"($config)#($host)" --mode destroy,format,mount --yes-wipe-all-disks
  }

  let tmpdir_parent = if $dry_run {
    "/mnt"
  } else {
    "/tmp"
  }
  let tmpdir = mktemp -d -p $tmpdir_parent
  $env.TMPDIR = $tmpdir

  log "Building toplevel config"

  let outLink = $tmpdir | path join "system"
  (
    nix build
      --out-link $outLink
      --store /mnt
      $"($config)#nixosConfigurations.($host).config.system.build.toplevel"
  )

  let system = readlink -f $outLink

  if $dry_run {
    log $"Updating system profile (ansi blue)\(Skipped\)(ansi reset)"
  } else {
    log "Updating system profile"
    (
      nix-env
        --store /mnt
        -p /mnt/nix/var/nix/profiles/system --set $system
    )
    mkdir /mnt/etc
    chmod -R 0755 /mnt/etc
    touch /mnt/etc/NIXOS
  }

  if $dry_run {
    log $"Installing boot loader (ansi blue)\(Skipped\)(ansi reset)"
  } else {
    log "Installing boot loader"
    ln -sfn /proc/mounts /mnt/etc/mtab

    let command = "
      set -e
      hash -r
      mount --rbind --mkdir / /mnt
      mount --make-rslave /mnt
      /run/current-system/bin/switch-to-configuration boot
      umount -R /mnt && (rmdir /mnt 2>/dev/null || true)
    "
    NIXOS_INSTALL_BOOTLOADER=1 nixos-enter --root /mnt -c $command
  }

  if $dry_run {
    log $"Copying config to installation (ansi blue)\(Skipped\)(ansi reset)"
  } else {
    log "Copying config to installation"

    let home = nix eval $"($config)#nixosConfigurations.($host).config.prefs.user.home" | str trim -c '"'

    mkdir $"/mnt($home)"
    chmod -R 0755 $"/mnt($home)"

    # Copy config
    cp -rp --preserve [mode, ownership, timestamps] $config $"/mnt($home)/conf"

    # Fetch .git directory here because flakes strip VCS metadata
    jj git clone gh:altacountbabi/dotfiles2 /tmp/conf
    # Abandon working copy as it would have no author attached
    jj -R /tmp/conf abandon @

    mv /tmp/conf/.git $"/mnt($home)/conf"
    mv /tmp/conf/.jj $"/mnt($home)/conf"

    chown -R 1000:100 $"/mnt($home)"

    git config --global --add safe.directory $"/mnt($home)/conf"
    git -C $"/mnt($home)/conf" add -A
  }

  if not $dry_run {
    umount -R /mnt
  }

  log $"Installation finished, default password is \"123\"\nTook ((date now) - $start)"

  if not $dry_run {
    let reboot = match (input "Reboot? (Y/n) " | str downcase) {
      "y" | "" => true,
      "n" => false,
    }

    if $reboot {
      systemctl reboot
    }
  }
}
