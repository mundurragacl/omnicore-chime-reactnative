require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json'))) rescue { 'version' => '0.6.3' }

Pod::Spec.new do |s|
  s.name           = 'ExpoAWSChime'
  s.version        = package['version'] || '0.6.3'
  s.summary        = 'Expo module for AWS Chime SDK'
  s.description    = 'Native iOS module wrapping the Amazon Chime SDK for Expo'
  s.author         = package['author'] || ''
  s.homepage       = package['homepage'] || 'https://github.com/expo/expo'
  s.license        = package['license'] || 'MIT'
  s.platforms      = { :ios => '15.1' }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  s.dependency 'AmazonChimeSDK', '0.27.2'
  s.dependency 'AmazonChimeSDKMedia', '0.25.2'

  s.source_files = '**/*.swift'
  s.swift_version = '5.9'
end
