Pod::Spec.new do |spec|
  spec.name          = "Web3Auth"
  spec.version       = "2.0.0"
  spec.platform      = :ios, "12.0"
  spec.summary       = "Torus Web3Auth SDK for iOS applications"
  spec.homepage      = "https://github.com/torusresearch/Web3Auth-swift-sdk"
  spec.license       = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.swift_version = "5.0"
  spec.author        = { "Torus Labs" => "hello@tor.us" }
  spec.module_name   = "Web3Auth"
  spec.source        = { :git => "https://github.com/torusresearch/Web3Auth-swift-sdk.git", :tag => spec.version }
  spec.source_files  = "Sources/Web3Auth/*.{swift}", "Sources/Web3Auth/**/*.{swift}"
  spec.exclude_files = [ 'docs/**' ]
end
