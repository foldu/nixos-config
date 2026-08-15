#! /bin/sh
# Emit accurate btrfs filesystem usage metrics for telegraf (exec input).
#
# Outputs influx line protocol, e.g.:
#   btrfs_usage,path=/ device_size=...,allocated=...,unallocated=...,used=...,free_estimated=...,free_statfs=...,data_ratio=1,metadata_ratio=2
#   btrfs_chunk,path=/,type=Data,profile=single size=...,used=...

# find btrfs filesystems: dedupe subvolume/bind mounts by source device
# (`btrfs filesystem usage` is per-filesystem, running it once per mount would
# emit duplicate series). Prefer the root mount "/" as the representative
# label, else the first mount for that device.
mounts=$(findmnt -rn -o SOURCE,TARGET -t btrfs 2>/dev/null | awk '
  {
    device = $1; sub(/\[.*/, "", device)
    target = $2
    if (target == "/") {
      rep[device] = "/"
      has_root[device] = 1
    } else if (!(device in rep)) {
      rep[device] = target
    }
  }
  END { for (device in rep) print rep[device] }
' | sort)

for path in $mounts; do
  # label the mount as-is; "/" stays "/", others lose the trailing slash
  label=$path
  if [ "$label" != "/" ]; then
    label=${label%/}
  fi

  # overall filesystem usage, sizes in bytes
  # (indented lines only, so the Data/Metadata/System chunk lines at column 0
  # don't clobber "used" via their "Used:" substrings)
  btrfs filesystem usage -b "$path" 2>/dev/null | awk -v path="$label" '
    function num(line,   s) { s = line; sub(/^[^0-9]*/, "", s); return s + 0 }
    /^    Device size:/        { device_size = num($0) }
    /^    Device allocated:/   { allocated = num($0) }
    /^    Device unallocated:/ { unallocated = num($0) }
    /^    Used:/               { used = num($0) }
    /^    Free \(estimated\):/ { free_estimated = num($0) }
    /^    Free \(statfs, df\):/{ free_statfs = num($0) }
    /^    Data ratio:/         { data_ratio = $3 }
    /^    Metadata ratio:/     { metadata_ratio = $3 }
    END {
      printf "btrfs_usage,path=%s device_size=%di,allocated=%di,unallocated=%di,used=%di,free_estimated=%di,free_statfs=%di,data_ratio=%s,metadata_ratio=%s\n",
        path, device_size, allocated, unallocated, used, free_estimated, free_statfs, data_ratio, metadata_ratio
    }'

  # per-chunk-type usage (Data/Metadata/System)
  btrfs filesystem usage -b "$path" 2>/dev/null | awk -v path="$label" '
    function num(line,   s) { s = line; sub(/^[^0-9]*/, "", s); return s + 0 }
    /^Data,/ || /^Metadata,/ || /^System,/ {
      # e.g. "Data,single: Size:1955769352192, Used:1879888424960 (96.12%)"
      split($1, a, ",")
      type = a[1]
      profile = a[2]
      sub(/:$/, "", profile)
      line = $0
      size = num(line)
      sub(/Size:[0-9]+, /, "", line)
      used = num(line)
      printf "btrfs_chunk,path=%s,type=%s,profile=%s size=%di,used=%di\n",
        path, type, profile, size, used
    }'
done
