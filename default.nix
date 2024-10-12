let
 pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/e7d6f2fd25ccfde2eed9fb2510e9ecde341d30a9.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      BiocManager
      data_table
      dplyr
      jsonlite
      git2r
      stringr;
  };
  
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      nix
      glibcLocales;
  };
  
in

pkgs.mkShell {
  LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";

  buildInputs = [ rpkgs system_packages ];
  
}