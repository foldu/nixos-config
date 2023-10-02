#!/usr/bin/env nu

export def import [path: path] {
  if $path == "." {
    print "Can't import CWD"
    exit 1
  }

  let type = ($path | path type)
  if $type != "dir" {
    print "Can only import directories"
    exit 1
  }

  let config = (config-parse)

  let origin = (git-get-origin-url $path)
  let target_path = (repo-path-from-origin $config $origin)

  if ($target_path | path exists) {
    print $"Already imported or duplicate of ($target_path)"
    exit 1
  }

  create-parent-if-not-exists $target_path

  mv $path $target_path
  print $"Imported ($path) to ($target_path)"
}

def repo-path-from-origin [config, origin: string] {
  let repo_info = try {
    repo-info-from-url $origin
  } catch {
    repo-info-from-ssh $origin
  }
  repo-target-path $config $repo_info
}

def repo-target-path [config, repo_info] {
  let flatten = try {
    $config.hosts | get $repo_info.domain | get flatten
  } catch {
    false
  }

  [
    $config.config.src_dir
    $repo_info.domain
    (if $flatten { "" } else { $repo_info.owner })
    $repo_info.repo
  ] | path join
}

def git-get-origin-url [path: path] {
  with-env { PWD: $path } { ^git remote get-url origin | str trim }
}

def repo-info-from-ssh [remote: string] {
  let parsed = ($remote | parse "{user}@{hostname}:{owner}/{repo}.git" | first)
  {
    domain: $parsed.hostname
    owner: $parsed.owner
    repo: $parsed.repo
  }
}

def repo-info-from-url [url: string] {
  let parsed = ($url | url parse)
  let meta = ($parsed.path | parse -r "^/(?<owner>[^/]+)/(?<repo>[^/]+)" | first)
  {
    domain: $parsed.host
    owner: $meta.owner
    repo: $meta.repo
  }
}

def create-parent-if-not-exists [path: path] {
  let parent = ($path | path dirname)
  if not ($parent | path exists) {
    mkdir $parent
  }
}

export def clone [origin: string] {
  let config = (config-parse)

  let target_path = (repo-path-from-origin $config $origin)

  create-parent-if-not-exists $target_path

  if ($target_path | path exists) {
    print $"Already cloned into ($target_path)"
  } else {
    ^git clone $origin $target_path
  }
}

def xdg-config-dir [] {
  try {
    $env.XDG_CONFIG_DIR
  } catch {
    $"($env.HOME)/.config"
  }
}

def expanduser [s: string] {
  $s | str replace -r '^~' $env.HOME
}

def config-parse [] {
  let config_dir = (xdg-config-dir)
  open $"($config_dir)/src-manage/config.json"
  | update config.src_dir {|config| expanduser $config.config.src_dir}
}
