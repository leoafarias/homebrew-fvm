require "yaml"

class Fvm < Formula
  desc "Simple cli to manage Flutter SDK versions per project"
  homepage "https://github.com/leoafarias/fvm"
  url "https://github.com/leoafarias/fvm/archive/3.0.0.tar.gz"
  sha256 "fffb16f1a8ec109a62cd128836f4a4ac79263b165e5fd770cf5503c96c5d7473"
  license "MIT"

  depends_on "dart-lang/dart/dart" => :build

  def install
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:fvm"

    system _dart/"dart", "pub", "get"
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
    system _dart/"dart", "compile", "exe", "-Dversion=#{_version}",
           "bin/main.dart", "-o", "fvm"
    bin.install "fvm"
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "main.dart.app.snapshot",
           "bin/main.dart"
    lib.install "main.dart.app.snapshot"

    
    cp _dart/"dart", lib

    (bin/"fvm").write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/main.dart.app.snapshot" "$@"
    SH
  end
end
  
