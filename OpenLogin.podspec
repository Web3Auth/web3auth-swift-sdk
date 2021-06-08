Pod::Spec.new do |spec|
  spec.name          = "OpenLogin"
  spec.version       = "0.1.0"
  spec.platform      = :ios, "11.0"
  spec.summary       = "Torus OpenLogin SDK for iOS applications"
  spec.homepage      = "https://github.com/torusresearch/openlogin-swift-sdk"
  spec.license       = { :type => 'BSD', :file => 'LICENSE.md' }
  spec.swift_version = "5.0"
  spec.author        = { "Torus Labs" => "hello@tor.us" }
  spec.module_name   = "OpenLogin"
  spec.source        = { :git => "https://github.com/torusresearch/openlogin-swift-sdk.git", :tag => spec.version }
  spec.source_files  = "Sources/OpenLogin/*.{swift}", "Sources/OpenLogin/**/*.{swift}"
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end