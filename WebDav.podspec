Pod::Spec.new do |s|
  s.name        = 'WebDav'
  s.version     = '0.0.1'
  s.summary     = 'WebDAV communication library for Swift'
  s.homepage    = 'https://code.sohuno.com/ifox-mac/webdav.git'
  s.license     = { type: 'MIT' }
  s.authors     = { 'David Mohundro' => 'david@mohundro.com' }

  s.requires_arc = true
  s.pod_target_xcconfig = {
    'APPLICATION_EXTENSION_API_ONLY' => 'YES'
  }

  s.swift_version = '5.0'
  s.osx.deployment_target = '10.13'
  s.ios.deployment_target = '11.0'
  s.watchos.deployment_target = '4.0'
  s.tvos.deployment_target = '11.0'

  s.source = {
    :git => 'https://code.sohuno.com/ifox-mac/webdav.git',
    :branch => 'main'
  }
  s.source_files = 'Sources/WebDAV/*.swift'
  s.dependency 'SWXMLHash'
end