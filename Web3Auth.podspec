Pod::Spec.new do |spec|
  spec.name          = "Web3Auth"
  spec.version       = "3.4.0"
  spec.platform      = :ios, "12.0"
  spec.summary       = "Torus Web3Auth SDK for iOS applications"
  spec.homepage      = "https://github.com/web3auth/web3auth-swift-sdk"
  spec.license       = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.swift_version = "5.0"
  spec.author        = { "Torus Labs" => "hello@tor.us" }
  spec.module_name   = "Web3Auth"
  spec.source        = { :git => "https://github.com/web3auth/web3auth-swift-sdk.git", :tag => spec.version }
  spec.source_files  = "Sources/Web3Auth/*.{swift}", "Sources/Web3Auth/**/*.{swift}"
  spec.exclude_files = [ 'docs/**' ]
end
