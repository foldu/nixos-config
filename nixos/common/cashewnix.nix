{ ... }:
{
  services.cashewnix = {
    enable = true;
    settings = {
      binary_caches = [ ];
      public_keys = [
        "mars.home.5kw.li:3zxQsXhs0sEQ9LiMxI9F7ovo9FK1OeYnAKbfKOOULqQ="
        "jupiter.home.5kw.li:7ZvacpgTXe7qCa7awMfrJjnsbh8GcM358Yu+i6S0lLU="
      ];
      local_binary_caches = {
        discovery_refresh_time = "1m";
      };
      priority_config = {
        "0".timeout = "500ms";
      };
    };
    openFirewall = true;
  };
}
