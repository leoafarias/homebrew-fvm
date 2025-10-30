# frozen_string_literal: true

require 'yaml'
require 'net/http'
require 'uri'

class Fvm < Formula
  desc 'Simple cli to manage Flutter SDK versions per project'
  homepage 'https://github.com/leoafarias/fvm'
  url 'https://github.com/leoafarias/fvm/archive/4.0.0.tar.gz'
  sha256 '18cf7634d36031e44bc46f482c8d5514c3341d1412ed82dc61ff97dbf829d1ab'
  license 'MIT'
  DART_SDK_VERSION = '3.9.4'
  DART_SDK_URL_TEMPLATE = "https://storage.googleapis.com/dart-archive/channels/stable/release/#{DART_SDK_VERSION}/sdk/dartsdk-%s-release.zip"

  platform = if OS.mac? && Hardware::CPU.intel?
               'macos-x64'
             elsif OS.mac? && Hardware::CPU.arm?
               'macos-arm64'
             elsif OS.linux? && Hardware::CPU.intel?
               'linux-x64'
             elsif OS.linux? && Hardware::CPU.arm?
               'linux-arm64'
             end
  platform_dart_sdk_url = DART_SDK_URL_TEMPLATE % platform
  dart_sdk_sha256 = URI("#{platform_dart_sdk_url}.sha256sum").then do |uri|
    Net::HTTP.new(uri.host, uri.port).then do |https|
      https.use_ssl = true
      Net::HTTP::Get.new(uri)
                    .then { |request| https.request(request) }
                    .read_body
    end
  end.split.first

  resource 'dart-sdk' do
    url platform_dart_sdk_url
    sha256 dart_sdk_sha256
  end

  def install
    # Resource installation for Dart SDK
    resource('dart-sdk').stage do
      libexec.install Dir['*'] # Assumes Dart SDK zip layout matches what's expected
    end

    ENV['PUB_ENVIRONMENT'] = 'homebrew:fvm'

    # Adjust paths to use the vendored Dart SDK
    dart = libexec/'bin/dart'

    system dart, 'pub', 'get'

    if Hardware::CPU.is_64_bit?
      _install_native_executable(dart)
    else
      _install_script_snapshot(dart)
    end
    chmod 0555, "#{bin}/fvm"
  end

  test do
    system 'false'
  end

  private

  def _version
    @_version ||= YAML.safe_load(File.read('pubspec.yaml'))['version']
  end

  def _install_native_executable(dart)
    system dart, 'compile', 'exe', "-Dversion=#{_version}",
           'bin/main.dart', '-o', 'fvm'
    bin.install 'fvm'
  end

  def _install_script_snapshot(dart)
    system dart, 'compile', 'jit-snapshot',
           "-Dversion=#{_version}",
           '-o', 'main.dart.app.snapshot',
           'bin/main.dart'
    lib.install 'main.dart.app.snapshot'

    cp dart, lib

    (bin/'fvm').write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/main.dart.app.snapshot" "$@"
    SH
  end
end
