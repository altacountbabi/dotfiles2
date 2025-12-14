{
  lib,
  stdenv,
  callPackage,
  closureInfo,
  xorriso,
  libossp_uuid,
  zstd,

  isoName ? "nixos.iso",
  contents,
  storeContents ? [ ],
  squashfsContents ? [ ],
  squashfsCompression ? "xz -Xdict-size 100%",
  compressImage ? false,
  volumeID ? "",
  efiBootImage,
  toplevel ? null,
}:

let
  needSquashfs = squashfsContents != [ ];
  makeSquashfsDrv = callPackage ./_make-squashfs.nix {
    storeContents = squashfsContents;
    comp = squashfsCompression;
  };
in
stdenv.mkDerivation {
  name = isoName;
  __structuredAttrs = true;

  unsafeDiscardReferences.out = true;
  buildCommandPath = ./make-iso.sh;

  nativeBuildInputs = [
    xorriso
    zstd
    libossp_uuid
    toplevel
  ]
  ++ lib.optionals needSquashfs makeSquashfsDrv.nativeBuildInputs;

  inherit
    isoName
    compressImage
    volumeID
    efiBootImage
    ;

  sources = map (x: x.source) contents;
  targets = map (x: x.target) contents;
  objects = map (x: x.object) storeContents;
  symlinks = map (x: x.symlink) storeContents;

  squashfsCommand = lib.optionalString needSquashfs makeSquashfsDrv.buildCommand;
  closureInfo = closureInfo { rootPaths = map (x: x.object) storeContents; };
}
