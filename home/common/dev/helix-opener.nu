#!/usr/bin/env nu
def main [path: string] {
  # TODO: make this a complete opener
  let pane_id = (get-pane-direction right)

  $":open ($path)\r\n" | ^wezterm cli send-text --pane-id $pane_id --no-paste
  wezterm cli activate-pane-direction --pane-id $pane_id right
}

def get-pane-direction [direction: string] {
  let out = (^wezterm cli get-pane-direction $direction)
  if $out == "" {
    null
  } else {
    $out | into int
  }
}

def list-panes [] {
  ^wezterm cli list --format json | from json
}


def split-pane [direction: string, percent: int, program: string?] {
  ^wezterm cli split-pane $"--($direction)" --percent $percent $program | into int
}
