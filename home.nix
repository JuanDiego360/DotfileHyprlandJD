{ config, pkgs, ... }:

let
  # 1. Define the path to your programs directory
  programsDir = ./config/programs;

  # 2. Get the content of the directory
  files = builtins.readDir programsDir;

  # 3. Filter for directories only (ignoring regular files like .DS_Store or READMEs)
  directories = builtins.filter 
    (name: files.${name} == "directory") 
    (builtins.attrNames files);

  # 4. Map the directory names to import paths
  programImports = map (name: programsDir + "/${name}") directories;
in
{
  imports = [
    # sessions
    ./config/sessions/hyprland/default.nix
  ] ++ programImports; 

  home.username = "ilyamiro";
  home.homeDirectory = "/home/ilyamiro";
  home.stateVersion = "25.11"; 
  
  home.packages = with pkgs; [
      adwaita-icon-theme
      adw-gtk3 
      libsForQt5.qt5ct      
      qt6Packages.qt6ct
  ];

  # set cursor 
  home.pointerCursor = 
  let 
    getFrom = url: hash: name: {
        gtk.enable = true;
        x11.enable = true;
        name = name;
        size = 24;
        package = 
          pkgs.runCommand "moveUp" {} ''
            mkdir -p $out/share/icons
            ln -s ${pkgs.fetchzip {
              url = url;
              hash = hash;
            }}/dist $out/share/icons/${name}
          '';
      };
  in
    getFrom 
      "https://github.com/yeyushengfan258/ArcMidnight-Cursors/archive/refs/heads/main.zip"
      "sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE=" 
      "ArcMidnight-Cursors";

  # Force the dark color scheme and explicitly set GTK3 theme in dconf
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };
  
  home.sessionVariables = {
    # Left intentionally blank to prevent GTK variable overrides
  };

  services.easyeffects.enable = true;  

  gtk = {
    enable = true;
    
    # IMPORT DYNAMIC MATUGEN COLORS 
    gtk3.extraCss = ''@import url("file:///home/ilyamiro/.cache/matugen/colors-gtk.css");'';
    gtk4.extraCss = ''@import url("file:///home/ilyamiro/.cache/matugen/colors-gtk.css");'';
    
    # Target GTK3 specifically
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-theme-name = "adw-gtk3-dark";
    };
    
    # Keep GTK4 native but ensure it requests the dark preference
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
  
  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
  };
  
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true; 
  
  home.file = {
    ".local/share/fonts/" = {
      source = config/fonts; 
      recursive = true;
    };
  };
}
