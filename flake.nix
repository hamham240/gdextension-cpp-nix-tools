{
  description = "Nix tooling for gdextension in C++";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system: 
      let
        pkgs = import nixpkgs { inherit system; };

        godotCppSrc = pkgs.fetchFromGitHub {
          owner  = "godotengine";
          repo   = "godot-cpp";
          tag   = "godot-4.4.1-stable";
          sha256 = "sha256-DW8OWbiA409qAyOkzxEYiPPRa5cH2TutIR7OuC3ZRgc=";
        };

        godotCppSrcPatched = pkgs.stdenv.mkDerivation {
          pname = "godot-cpp-patched";
          version = "4.4.1";
          src = godotCppSrc;
          patches = [ ./godot-cpp.patch ];
          phases = [ "unpackPhase" "patchPhase" "installPhase" ];
          installPhase = ''
            mkdir -p $out
            cp -r . $out
          '';
        };
      in 
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ scons ];
          shellHook = ''
            export GODOT_CPP_SRC=${godotCppSrcPatched}
            export PYTHONPATH=${godotCppSrc}:$PYTHONPATH
          '';
        };
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
