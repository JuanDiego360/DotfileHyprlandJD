{ config, ... }:

{
  xdg.configFile."kitty".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/config/programs/kitty";
}
