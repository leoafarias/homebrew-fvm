require "yaml"

class Fvm < Formula
  desc "Simple cli to manage Flutter SDK versions per project"
  homepage "https://github.com/leoafarias/fvm"
  url "https://github.com/leoafarias/fvm/archive/3.0.0.tar.gz"
  sha256 "fffb16f1a8ec109a62cd128836f4a4ac79263b165e5fd770cf5503c96c5d7473"
  license "MIT"

  # Determine architecture and set the Dart SDK resource accordingly
  dart_sdk_url, dart_sdk_sha = if Hardware::CPU.intel?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/3.2.6/sdk/dartsdk-macos-x64-release.zip",
     "97661f20230686381f4fc5b05a63c6b5d5abc9570bf93ad4e5fc09309cd98517"]
  elsif Hardware::CPU.arm?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/3.2.6/sdk/dartsdk-macos-arm64-release.zip",
     "2e04c91039f9cc05b2e93ce788aa1ce08bc4df5b50c84d6b4e21ba2b2538adb6"]
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
