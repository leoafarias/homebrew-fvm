class Fvm < Formula
    desc "Simple cli to manage Flutter SDK versions per project"
    homepage "https://github.com/leoafarias/fvm"
    url "https://github.com/leoafarias/fvm/archive/2.2.5.tar.gz"
    sha256 "6b91db9d184e54521082e67af21ef897753848c41c5375a888b5cd4f94055249"
    license "MIT"
  
    depends_on "dart-lang/dart/dart" => :build
  
    def install
      # Tell the pub server where these installations are coming from.
      ENV["PUB_ENVIRONMENT"] = "homebrew:fvm"

      system dart/"pub", "get"
      # Build a native-code executable on 64-bit systems only. 32-bit Dart
      # doesn't support this.
      if Hardware::CPU.is_64_bit?
        _install_native_executable
      else
        _install_script_snapshot
      end
      chmod 0555, "#{bin}/fvm"
    end

    test do
      system "false"
    end
      
    private

    def _dart
      @_dart ||= Formula["dart-lang/dart/dart"].libexec/"bin"
    end
  
    def _version
      @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
    end
    
    
    def _install_native_executable
      system dart/"dart2native", "-Dversion=#{version}", "bin/main.dart",
              "-o", "fvm"
      bin.install "fvm"
    end

    def _install_script_snapshot
      system dart/"dart",
              "-Dversion=#{version}",
              "--snapshot=main.dart.app.snapshot",
              "--snapshot-kind=app-jit",
              "bin/main.dart", "version"
      lib.install "main.dart.app.snapshot"

      # Copy the version of the Dart VM we used into our lib directory so that if
      # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
      # which was compiled with an older version.
      cp dart/"dart", lib

      (bin/"fvm").write <<~SH
        #!/bin/sh
        exec "#{lib}/dart" "#{lib}/main.dart.app.snapshot" "$@"
      SH
    end
end
  
