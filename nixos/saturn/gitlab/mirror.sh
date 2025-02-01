#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "$1"
  exit 1
}

test -z "$STATE_DIR" && die "Missing STATE_DIR env variable"
test -z "$SSH_KEY_FILE" && die "Missing path to SSH_KEY_FILE"

repo_dir="$STATE_DIR/repositories"
mirror_dir="$STATE_DIR/mirror"
mkdir -p "$repo_dir" || die "Couldn't create directory for repositories $repo_dir"

if test -d "$mirror_dir"; then
  (cd "$mirror_dir" && git pull)
else
  git clone https://lab.home.5kw.li/foldu/git-mirror "$mirror_dir"
fi

cd "$repo_dir"
while IFS=" " read -r repo_url repo_name; do
  if test -d "$repo_name"; then
    (cd "$repo_name" && git remote update)
  else
    git clone --mirror "$repo_url" "$repo_name"
    (cd "$repo_name" && git config --add --local core.sshCommand "ssh -i $SSH_KEY_FILE" && git remote add lab "gitlab@lab.home.5kw.li:foldu/$repo_name.git")
    curl --request POST \
      --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      --header 'Content-Type: application/json' \
      --data-raw "$(
        # FIXME: missing escaping for repo_name
        cat <<EOF
{
  "name": "${repo_name}",
  "visibility": "public"
}
EOF
      )" \
      https://lab.home.5kw.li/api/v4/projects
  fi
  (cd "$repo_name" && git push --all lab)
  sleep 5
done <"$mirror_dir/mirrors"
