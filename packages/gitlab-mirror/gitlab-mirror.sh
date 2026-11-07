#!/usr/bin/env bash
# gitlab-mirror — create, inspect and repair GitLab push mirrors (GitLab →
# GitHub / Codeberg / any git host) through the remote-mirrors API, so you never
# have to click through Settings → Repository → Mirroring repositories.
#
# Both credentials come from the CLI that already stores them, so there is no
# token to export, read from a file, or scrape out of a config:
#
#   GitLab  glab auth login --hostname lab.home.5kw.li   (PAT with `api` scope)
#   GitHub  gh auth login                                (gh auth token)
#
#   gitlab-mirror --list             # mirrors of the current checkout
#   gitlab-mirror                    # set one up for this repo
#   gitlab-mirror --all -y           # every project in the namespace
#   gitlab-mirror --sync             # nudge an update without waiting
#
# Want a fine-grained PAT instead of gh's token? `GH_TOKEN=... gitlab-mirror`;
# gh reads GH_TOKEN/GITHUB_TOKEN itself. Reads never touch the GitHub side.
set -euo pipefail

gitlab_host=${GITLAB_HOST:-}
gh_host=github.com
gh_owner=
dest=
only_protected=false
keep_divergent=false
dry_run=false
list_only=false
remove=false
sync=false
all=false
assume_yes=false
projects=()

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}
note() { printf '%s\n' "$*"; }

usage() {
  cat <<'EOF'
Usage: gitlab-mirror [options] [PROJECT...]

Configure a GitLab push mirror to another git host. With no PROJECT arguments it
uses the project of the current checkout. A PROJECT is a group/repo path or a
clone URL (https://host/group/repo.git, git@host:group/repo.git); a URL also
names the GitLab host, so it works from anywhere.

Authentication is glab's and gh's problem, not yours: `glab auth login` for the
GitLab API, `gh auth login` for the destination repo (gh auth token, or GH_TOKEN).

Options:
  -t, --to OWNER/REPO     destination repo (default: <github owner>/<repo name>)
  -o, --owner OWNER       destination owner/org (default: the GitLab namespace)
  -g, --github HOST       destination host (default: github.com)
  -G, --gitlab HOST       GitLab host (default: the checkout's remote, or
                          $GITLAB_HOST)
  -l, --list              only report mirror state
  -n, --dry-run           report what would change, change nothing (reads only)
  -a, --all               every project in the same namespace
  -r, --remove            delete the mirror pointing at the destination
  -s, --sync              update now (toggles `enabled`; GitLab otherwise waits
                          up to 5 minutes, or 1 with --protected-only)
  -p, --protected-only    only mirror protected branches
  -k, --keep-divergent    keep divergent refs instead of overwriting downstream
  -y, --yes               don't ask for confirmation
  -h, --help              this text

Examples:
  gitlab-mirror --list                     # what is set up already
  gitlab-mirror --to foldu/nixos-config -p # protected branches only
  gitlab-mirror --all -y -p                # sweep the namespace
  gitlab-mirror https://lab.example.org/foldu/nixos-config.git  # from anywhere
EOF
}

while [ "$#" -gt 0 ]; do
  case $1 in
    -t | --to)
      dest=${2:?--to needs OWNER/REPO}
      shift 2
      ;;
    -o | --owner)
      gh_owner=${2:?--owner needs a value}
      shift 2
      ;;
    -g | --github)
      gh_host=${2:?--github needs a value}
      shift 2
      ;;
    -G | --gitlab)
      gitlab_host=${2:?--gitlab needs a value}
      shift 2
      ;;
    -l | --list)
      list_only=true
      shift
      ;;
    -n | --dry-run)
      dry_run=true
      shift
      ;;
    -a | --all)
      all=true
      shift
      ;;
    -r | --remove)
      remove=true
      shift
      ;;
    -s | --sync)
      sync=true
      shift
      ;;
    -p | --protected-only)
      only_protected=true
      shift
      ;;
    -k | --keep-divergent)
      keep_divergent=true
      shift
      ;;
    -y | --yes)
      assume_yes=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown option '$1' (try --help)" ;;
    *)
      projects+=("$1")
      shift
      ;;
  esac
done

# ------------------------------------------------------------------- transport
# glab already sends its stored token, so all that is left is the host: name it
# only when the caller overrode it, otherwise glab reads it from the checkout.
glab_api() {
  if [ -n "$gitlab_host" ]; then
    glab api --hostname "$gitlab_host" "$@"
  else
    glab api "$@"
  fi
}

# glab's stderr carries update banners and warnings as well as failures, so it is
# kept out of the JSON we parse and only shown when a request actually fails.
errlog=$(mktemp)
trap 'rm -f "$errlog"' EXIT

# Wrap requests so an expired/missing credential reads as advice, not a JSON blob.
request() {
  local out err
  : >"$errlog"
  if out=$(glab_api "$@" 2>"$errlog"); then
    printf '%s' "$out"
    return 0
  fi
  err=$(<"$errlog")
  case $out$err in
    *401* | *invalid_token* | *Unauthorized*)
      die "GitLab rejected the credential: run 'glab auth login${gitlab_host:+ --hostname $gitlab_host}', or pass --gitlab HOST."
      ;;
    *) die "GitLab API call failed: ${err:-${out:-no response}}" ;;
  esac
}

# ------------------------------------------------------------------- discovery
project_of_checkout() {
  local out
  out=$(glab repo view -F json --jq .path_with_namespace 2>/dev/null) || out=
  [ -n "$out" ] ||
    die "cannot tell which project this is: pass a PROJECT (group/repo or a clone URL), or run from a glab-configured checkout."
  printf '%s' "$out"
}

# A PROJECT may be a clone URL as well as a plain path: the URL carries the host
# too, which is the one thing a path cannot. Sets arg_host/arg_path. Credentials
# in the URL are dropped here and never echoed — glab does the authenticating.
split_project_arg() {
  local u=$1
  arg_host=
  case $u in
    *://*)
      u=${u#*://}
      u=${u#*@}
      arg_host=${u%%/*}
      arg_path=${u#*/}
      arg_path=${arg_path%.git}
      ;;
    *@*:*) # scp-like: git@host:group/repo.git
      u=${u#*@}
      arg_host=${u%%:*}
      arg_path=${u#*:}
      arg_path=${arg_path%.git}
      ;;
    *) arg_path=$u ;;
  esac
}

list_namespace_projects() {
  glab_api --paginate --output ndjson 'projects?membership=true&per_page=100' |
    jq -r --arg ns "$1" 'select(.namespace.full_path == $ns and (.archived | not)) | .path_with_namespace'
}

# ------------------------------------------------------------------- reporting
print_mirrors() {
  local json=$1
  if [ "$(jq 'length' <<<"$json")" -eq 0 ]; then
    printf '    (no mirrors configured)\n'
    return
  fi
  jq -r '.[] |
    ((.url // "") | sub(":[^:@/]+@"; ":***@")) as $url |
    "    id=\(.id) enabled=\(.enabled) status=\(.update_status) protected_only=\(.only_protected_branches) keep_divergent=\(.keep_divergent_refs)\n      url=\($url)\n      last_success=\(.last_successful_update_at // "-")\n      last_error=\(.last_error // "-")"' <<<"$json"
}

mirror_id_for() { # json, target → id (empty when absent)
  jq -r --arg suffix "@${gh_host}/${2}.git" \
    '.[] | select((.url // "") | endswith($suffix)) | .id' <<<"$1" | head -1
}

confirm() {
  [ "$assume_yes" = true ] && return 0
  printf '%s [y/N] ' "$1"
  read -r reply
  [[ $reply == [yY]* ]]
}

# The destination credential is gh's, fetched only when a mirror is created. It
# goes into the mirror URL, which GitLab stores (and returns) either way; the
# token rides in glab's argv for the length of one request, so keep the machine
# single-user or set GH_TOKEN to a throwaway fine-grained PAT.
create_mirror() { # project-enc, owner, target
  local out token
  token=$(gh auth token --hostname "$gh_host" 2>/dev/null) ||
    die "no $gh_host credential: run 'gh auth login --hostname $gh_host', or set GH_TOKEN for a scoped PAT."
  if ! out=$(glab_api --silent -X POST "projects/$1/remote_mirrors" \
    -f "url=https://${2}:${token}@${gh_host}/${3}.git" \
    -F enabled=true \
    -F "only_protected_branches=${only_protected}" \
    -F "keep_divergent_refs=${keep_divergent}" 2>&1); then
    die "creating the mirror failed: ${out//"$token"/***}"
  fi
}

# ------------------------------------------------------------------------ main
if [ "${#projects[@]}" -eq 0 ]; then
  projects=("$(project_of_checkout)")
else
  # Normalise PROJECT arguments, keeping the host a clone URL brought along.
  given=("${projects[@]}")
  projects=()
  for arg in "${given[@]}"; do
    split_project_arg "$arg"
    if [ -n "$arg_host" ]; then
      [ "$arg_host" != "$gh_host" ] ||
        die "$arg is the destination, not the GitLab project: pass the GitLab URL or path."
      if [ -n "$gitlab_host" ] && [ "$gitlab_host" != "$arg_host" ]; then
        die "all projects must be on one GitLab host ($gitlab_host, $arg_host)."
      fi
      gitlab_host=$arg_host
    fi
    projects+=("$arg_path")
  done
fi

if [ "$all" = true ]; then
  ns=${projects[0]%/*}
  note "namespace: $ns"
  mapfile -t projects < <(list_namespace_projects "$ns")
  [ "${#projects[@]}" -gt 0 ] || die "no projects found in namespace '$ns'"
  note "projects: ${#projects[@]}"
fi

for project in "${projects[@]}"; do
  enc=${project//\//%2F}
  owner=${gh_owner:-${project%%/*}}
  target=${dest:-${owner}/${project##*/}}
  note ""
  note "${project} → ${gh_host}/${target}"

  mirrors=$(request -X GET "projects/${enc}/remote_mirrors")
  print_mirrors "$mirrors"
  [ "$list_only" = true ] && continue

  id=$(mirror_id_for "$mirrors" "$target")

  if [ "$remove" = true ]; then
    if [ -z "$id" ]; then
      note "    nothing to remove"
      continue
    fi
    if [ "$dry_run" = true ]; then
      note "    would delete mirror id=$id"
    elif confirm "delete mirror id=$id of ${project}?"; then
      request -X DELETE "projects/${enc}/remote_mirrors/${id}" --silent
      note "    deleted mirror id=$id"
    else
      note "    skipped"
    fi
    continue
  fi

  if [ "$sync" = true ]; then
    if [ -z "$id" ]; then
      note "    no mirror to sync"
      continue
    fi
    if [ "$dry_run" = true ]; then
      note "    would toggle enabled on mirror id=$id to force an update"
    else
      request -X PUT "projects/${enc}/remote_mirrors/${id}" -F enabled=false --silent
      request -X PUT "projects/${enc}/remote_mirrors/${id}" -F enabled=true --silent
      note "    update scheduled (id=$id)"
    fi
    continue
  fi

  if [ -n "$id" ]; then
    desired=$(jq -r --argjson id "$id" '.[] | select(.id == $id) | "\(.enabled) \(.only_protected_branches) \(.keep_divergent_refs)"' <<<"$mirrors")
    wanted="true ${only_protected} ${keep_divergent}"
    if [ "$desired" = "$wanted" ]; then
      note "    already configured as requested"
      continue
    fi
    if [ "$dry_run" = true ]; then
      note "    would update mirror id=$id (enabled/only_protected/keep_divergent: $desired → $wanted)"
    else
      request -X PUT "projects/${enc}/remote_mirrors/${id}" \
        -F enabled=true \
        -F "only_protected_branches=${only_protected}" \
        -F "keep_divergent_refs=${keep_divergent}" --silent
      note "    updated mirror id=$id"
    fi
  elif [ "$dry_run" = true ]; then
    note "    would create a push mirror to https://${gh_host}/${target}.git"
  elif confirm "create a push mirror for ${project} → ${gh_host}/${target}?"; then
    create_mirror "$enc" "$owner" "$target"
    note "    created"
  else
    note "    skipped"
  fi
done

if [ "$list_only" = false ] && [ "$dry_run" = false ]; then
  note ""
  note "GitLab mirrors asynchronously (≤5 min, ≤1 min with --protected-only)."
  note "Run --sync to nudge it now, or --list to check last_error."
fi
