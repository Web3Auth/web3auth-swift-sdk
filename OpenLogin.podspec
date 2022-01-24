Pod::Spec.new do |spec|
  spec.name          = "OpenLogin"
  spec.version       = "1.0.0"
  spec.platform      = :ios, "12.0"
  spec.summary       = "Torus OpenLogin SDK for iOS applications"
  spec.homepage      = "https://github.com/torusresearch/openlogin-swift-sdk"
  spec.license       = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.swift_version = "5.0"
  spec.author        = { "Torus Labs" => "hello@tor.us" }
  spec.module_name   = "OpenLogin"
  spec.source        = { :git => "https://github.com/torusresearch/openlogin-swift-sdk.git", :tag => spec.version }
  spec.source_files  = "Sources/OpenLogin/*.{swift}", "Sources/OpenLogin/**/*.{swift}"
  spec.exclude_files = [ 'docs/**' ]
end
