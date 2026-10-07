#!/usr/bin/env bash
# gitlab-mirror — create, inspect and repair GitLab push mirrors (GitLab →
# GitHub / Codeberg / any git host) through the remote-mirrors API, so you never
# have to click through Settings → Repository → Mirroring repositories.
#
#   gitlab-mirror --list             # mirrors of the current checkout
#   gitlab-mirror                    # set one up for this repo
#   gitlab-mirror --all -y           # every project in the namespace
#   gitlab-mirror --sync             # nudge an update without waiting
#
# Tokens are never put on a command line (curl is fed a config on stdin).
#   GITLAB_TOKEN   GitLab PAT with `api` scope; if unset it is read from glab
#                  (keyring or config), so `glab auth login' is enough      (read)
#   GITHUB_TOKEN   fine-grained PAT, Repository contents: read+write     (to create)
#                  scope it to the one destination repo; add Workflows: read+write
#                  if the repo ever contains .github/workflows
set -euo pipefail

gitlab_host=${GITLAB_HOST:-lab.home.5kw.li}
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
github_token_file=
gitlab_token_file=
projects=()

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}
note() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: gitlab-mirror [options] [PROJECT...]

Configure a GitLab push mirror to another git host. With no PROJECT arguments it
uses the project of the current checkout's `origin` remote.

Options:
  -t, --to OWNER/REPO     destination repo (default: <github owner>/<repo name>)
  -o, --owner OWNER       destination owner/org (default: the GitLab namespace)
  -g, --github HOST       destination host (default: github.com)
  -l, --list              only report mirror state
  -n, --dry-run           report what would change, change nothing (reads only)
  -a, --all               every project in the same namespace
  -r, --remove            delete the mirror pointing at the destination
  -s, --sync              update now (toggles `enabled`; GitLab otherwise waits
                          up to 5 minutes, or 1 with --protected-only)
  -p, --protected-only    only mirror protected branches
  -k, --keep-divergent    keep divergent refs instead of overwriting downstream
      --github-token-file FILE    read GITHUB_TOKEN from FILE
      --gitlab-token-file FILE    read GITLAB_TOKEN from FILE
  -y, --yes               don't ask for confirmation
  -h, --help              this text

Environment:
  GITLAB_TOKEN            GitLab PAT with `api` scope; falls back to the token
                          stored by glab (keyring or config file)
  GITHUB_TOKEN            GitHub fine-grained PAT (required to create a mirror)
  GITLAB_HOST             default lab.home.5kw.li

Examples:
  gitlab-mirror --list                     # what is set up already
  gitlab-mirror --to foldu/nixos-config -p # protected branches only
  gitlab-mirror --all -y -p                # sweep the namespace
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
    --github-token-file)
      github_token_file=${2:?--github-token-file needs a path}
      shift 2
      ;;
    --gitlab-token-file)
      gitlab_token_file=${2:?--gitlab-token-file needs a path}
      shift 2
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

# ---------------------------------------------------------------- credentials
if [ -n "$gitlab_token_file" ]; then
  [ -r "$gitlab_token_file" ] || die "cannot read --gitlab-token-file '$gitlab_token_file'"
  GITLAB_TOKEN=$(<"$gitlab_token_file")
fi

# glab 1.114 stores the token in the OS keyring by default (older versions wrote
# it to config.yml), so ask glab instead of parsing the file. It validates the
# token while doing so, which means exit status 1 for an expired one — the token
# is printed regardless, so the status is ignored.
glab_status_token() {
  command -v glab >/dev/null 2>&1 || return 1
  local out
  out=$(glab auth status --show-token --hostname "$1" 2>&1) || true
  printf '%s\n' "$out" | awk '
    /Token found/ { print $NF; exit }
    match($0, /glpat-[A-Za-z0-9_-]+/) { print substr($0, RSTART, RLENGTH); exit }
  '
}

# last resort: the plaintext config older glab versions wrote
glab_config_token() {
  local cfg=${GLAB_CONFIG_DIR:-"$HOME/.config/glab-cli"}/config.yml
  [ -r "$cfg" ] || return 1
  awk -v host="$1:" '
    $1 == host { found = 1; next }
    found && $1 == "token:" { print $2; exit }
    found && $0 !~ /^[[:space:]]/ { exit }
  ' "$cfg"
}

if [ -z "${GITLAB_TOKEN:-}" ]; then
  GITLAB_TOKEN=$(glab_status_token "$gitlab_host" || true)
fi
if [ -z "${GITLAB_TOKEN:-}" ]; then
  GITLAB_TOKEN=$(glab_config_token "$gitlab_host" || true)
fi
[ -n "${GITLAB_TOKEN:-}" ] ||
  die "no GitLab token: export GITLAB_TOKEN (PAT with 'api' scope from https://${gitlab_host}/-/user_settings/personal_access_tokens), pass --gitlab-token-file, or run 'glab auth login --hostname ${gitlab_host}'."

if [ -n "$github_token_file" ]; then
  [ -r "$github_token_file" ] || die "cannot read --github-token-file '$github_token_file'"
  GITHUB_TOKEN=$(<"$github_token_file")
fi

if [ "$dry_run" = false ] && [ "$list_only" = false ] && [ "$remove" = false ]; then
  [ -n "${GITHUB_TOKEN:-}" ] ||
    die "GITHUB_TOKEN is unset (fine-grained PAT, Repository contents: read+write). See --github-token-file."
fi

# ------------------------------------------------------------------- transport
base="https://${gitlab_host}/api/v4"

# Every call feeds curl a config on stdin so neither token ever appears in argv.
api() {
  local method=$1 path=$2 extra cfg
  shift 2
  cfg=$(printf 'url = "%s/%s"\nrequest = "%s"\nheader = "PRIVATE-TOKEN: %s"\nsilent\nshow-error\nfail-with-body\n' \
    "$base" "$path" "$method" "$GITLAB_TOKEN")
  for extra in "$@"; do
    cfg+=$(printf '\n%s' "$extra")
  done
  # stderr joins the body so `request' can turn a failure into advice
  printf '%s\n' "$cfg" | curl --config - 2>&1
}

# Wrap requests so an expired/wrong token reads as advice, not a JSON blob.
request() {
  local out
  if ! out=$(api "$@"); then
    case $out in
      *invalid_token* | *"401 Unauthorized"*)
        die "GitLab rejected the token (expired, or missing 'api' scope). Run 'glab auth login --hostname ${gitlab_host}' or issue a fresh PAT."
        ;;
      *) die "GitLab API call failed: ${out:-no response}" ;;
    esac
  fi
  printf '%s' "$out"
}

# ------------------------------------------------------------------ git remotes
# Sets rhost/rpath from any remote URL shape git allows.
parse_remote() {
  local u=$1
  case $u in
    *://*)
      u=${u#*://}
      u=${u#*@}
      rhost=${u%%/*}
      u=${u#*/}
      rpath=${u%.git}
      ;;
    *@*:*)
      u=${u#*@}
      rhost=${u%%:*}
      rpath=${u#*:}
      rpath=${rpath%.git}
      ;;
    *) die "cannot parse git remote URL '$1'" ;;
  esac
  rhost=${rhost%%:*}
}

project_of_checkout() {
  local url
  url=$(git config --get remote.origin.url 2>/dev/null) ||
    die "no 'origin' remote here; pass a PROJECT argument instead"
  parse_remote "$url"
  if [ "$rhost" != "$gitlab_host" ]; then
    warn "origin points at '$rhost', not '$gitlab_host' (using the path anyway)"
  fi
  printf '%s' "$rpath"
}

list_namespace_projects() {
  local ns=$1 page=1 json count
  while :; do
    json=$(request GET "projects?membership=true&per_page=100&page=${page}")
    jq -r --arg ns "$ns" '.[] | select(.namespace.full_path == $ns) | select(.archived | not) | .path_with_namespace' <<<"$json"
    count=$(jq 'length' <<<"$json")
    [ "$count" -lt 100 ] && break
    page=$((page + 1))
  done
}

# ------------------------------------------------------------------- reporting
print_mirrors() {
  local json=$1
  if [ "$(jq 'length' <<<"$json")" -eq 0 ]; then
    printf '    (no mirrors configured)\n'
    return
  fi
  jq -r '.[] | "    id=\(.id) enabled=\(.enabled) status=\(.update_status) protected_only=\(.only_protected_branches) keep_divergent=\(.keep_divergent_refs)\n      url=\(.url)\n      last_success=\(.last_successful_update_at // "-")\n      last_error=\(.last_error // "-")"' <<<"$json"
}

mirror_id_for() { # json, target → id (empty when absent)
  jq -r --arg suffix "@${gh_host}/${2}.git" \
    '.[] | select(.url | endswith($suffix)) | .id' <<<"$1" | head -1
}

confirm() {
  [ "$assume_yes" = true ] && return 0
  printf '%s [y/N] ' "$1"
  read -r reply
  [[ $reply == [yY]* ]]
}

# ------------------------------------------------------------------------ main
if [ "${#projects[@]}" -eq 0 ]; then
  projects=("$(project_of_checkout)")
fi

if [ "$all" = true ]; then
  ns=${projects[0]%%/*}
  note "namespace: $ns"
  mapfile -t projects < <(list_namespace_projects "$ns")
  [ "${#projects[@]}" -gt 0 ] || die "no projects found in namespace '$ns'"
  note "projects: ${#projects[@]}"
fi

for project in "${projects[@]}"; do
  enc=${project//\//%2F}
  repo=${project##*/}
  owner=${gh_owner:-${project%%/*}}
  target=${dest:-${owner}/${repo}}
  note ""
  note "${project} → ${gh_host}/${target}"

  mirrors=$(request GET "projects/${enc}/remote_mirrors")
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
      request DELETE "projects/${enc}/remote_mirrors/${id}" >/dev/null
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
      request PUT "projects/${enc}/remote_mirrors/${id}" 'data = "enabled=false"' >/dev/null
      request PUT "projects/${enc}/remote_mirrors/${id}" 'data = "enabled=true"' >/dev/null
      note "    update scheduled (id=$id)"
    fi
    continue
  fi

  data=(
    'data = "enabled=true"'
    "data = \"only_protected_branches=${only_protected}\""
    "data = \"keep_divergent_refs=${keep_divergent}\""
  )

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
      request PUT "projects/${enc}/remote_mirrors/${id}" "${data[@]}" >/dev/null
      note "    updated mirror id=$id"
    fi
  elif [ "$dry_run" = true ]; then
    note "    would create a push mirror to https://${gh_host}/${target}.git"
  elif confirm "create a push mirror for ${project} → ${gh_host}/${target}?"; then
    request POST "projects/${enc}/remote_mirrors" \
      "data-urlencode = \"url=https://${owner}:${GITHUB_TOKEN}@${gh_host}/${target}.git\"" \
      "${data[@]}" >/dev/null
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
