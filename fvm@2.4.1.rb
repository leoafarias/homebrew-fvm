require "yaml"

class FvmAT241 < Formula
  desc "Simple cli to manage Flutter SDK versions per project"
  homepage "https://github.com/leoafarias/fvm"
  url "https://github.com/leoafarias/fvm/archive/2.4.1.tar.gz"
  sha256 "578ddc4cc63656938afbfa971e08325d22af1ce4487cb264753dd829e419646b"
  license "MIT"

  # Determine architecture and set the Dart SDK resource accordingly
  dart_sdk_url, dart_sdk_sha = if OS.mac? && Hardware::CPU.intel?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.7/sdk/dartsdk-macos-x64-release.zip",
     "ba258fff40822cb410c4f1f7916b63f0837903a6bae8f4bd83341053b10ecbe3"]
  elsif OS.mac? && Hardware::CPU.arm?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.7/sdk/dartsdk-macos-arm64-release.zip",
     "a4be379202cf731c7e33de20b4abc4ca1e2e726bc5973222b3a7ae5a0cabfce1"]
  elsif OS.linux? && Hardware::CPU.intel?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.7/sdk/dartsdk-linux-x64-release.zip",
     "ba8bc85883e38709351f78c527cbf72e22cd234b3678a1ec6a2e781f7984e624"]
  elsif OS.linux? && Hardware::CPU.arm?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.7/sdk/dartsdk-linux-arm64-release.zip",
     "ee0acf66e184629b69943e9f29459e586095895c6aae6677ab027d99c00934b6"]
  end

  resource "dart-sdk" do
    url dart_sdk_url
    sha256 dart_sdk_sha
  end

  def install
    # Resource installation for Dart SDK
    resource("dart-sdk").stage do
      libexec.install Dir["*"] # Assumes Dart SDK zip layout matches what's expected
    end

    ENV["PUB_ENVIRONMENT"] = "homebrew:fvm"
    
    # Adjust paths to use the vendored Dart SDK
    dart = libexec/"bin/dart"
    
    system dart, "pub", "get"
    
    if Hardware::CPU.is_64_bit?
      _install_native_executable(dart)
    else
      _install_script_snapshot(dart)
    end
    chmod 0555, "#{bin}/fvm"
  end

  test do
    system "false"
  end

  private

  def _version
    @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
  end

  def _install_native_executable(dart)
    system dart, "compile", "exe", "-Dversion=#{_version}",
           "bin/main.dart", "-o", "fvm"
    bin.install "fvm"
  end

  def _install_script_snapshot(dart)
    system dart, "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "main.dart.app.snapshot",
           "bin/main.dart"
    lib.install "main.dart.app.snapshot"
    
    cp dart, lib

    (bin/"fvm").write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/main.dart.app.snapshot" "$@"
    SH
  end
end
