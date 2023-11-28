def main [] {
  podman container list --format=json 
  | from json 
  | where Labels."io.containers.autoupdate"? != null
  | each {|container| 
    let image = $container.Image
    let service = $container.Labels."PODMAN_SYSTEMD_UNIT"?
    let update_policy = $container.Labels."io.containers.autoupdate"
    if $service != null and $update_policy == "registry" {
      let last_created = (last-history-created $image)

      podman pull $image

      if (last-history-created $image) != $last_created {
        systemctl restart $service
      }
    }
  }
}

def last-history-created [image] {
  podman image history $image --format json
  | from json
  | first
  | get created
}
