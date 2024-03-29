require "yaml"

class FvmAT300Beta1 < Formula
  desc "Simple cli to manage Flutter SDK versions per project"
  homepage "https://github.com/leoafarias/fvm"
  url "https://github.com/leoafarias/fvm/archive/3.0.0-beta.1.tar.gz"
  sha256 "0dc67f026010440bb7f9f5f3f80e85311b4e7858d2a88fc12319e9f869cd07b7"
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
           "bin/fvm.dart", "-o", "fvm"
    bin.install "fvm"
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "main.dart.app.snapshot",
           "bin/fvm.dart"
    lib.install "main.dart.app.snapshot"

    
    cp _dart/"dart", lib

    (bin/"fvm").write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/main.dart.app.snapshot" "$@"
    SH
  end
end
  
