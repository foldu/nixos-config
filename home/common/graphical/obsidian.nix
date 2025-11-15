{ ... }:
{
  programs.obsidian = {
    enable = true;
    defaultSettings = {
      communityPlugins = [
        "obsidian-git"
        "obsidian-excalidraw"
      ];
    };
  };
}
