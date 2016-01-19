Pod::Spec.new do |s|
  s.name         = 'AMCoreAudio'
  s.version      = '2.0.10'
  s.summary      = 'AMCoreAudio is a Swift wrapper for Apple\'s CoreAudio framework'

  s.description  = <<-DESC
                   AMCoreAudio is a Swift wrapper for Apple's CoreAudio framework focusing on:

                   * Simplifying audio device enumeration
                   * Providing accessors for the most relevant audio device properties (i.e., device name, device manufacturer, device UID, volume, mute, sample rate, clock source, etc.)
                   * Subscribing to system and audio device specific notifications using delegation, etc.
                   DESC

  s.homepage     = 'https://github.com/rnine/AMCoreAudio'
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { 'Ruben Nine' => 'ruben@9labs.io' }
  s.social_media_url = 'http://twitter.com/sonicbee9'

  s.platform     = :osx, '10.9'
  s.osx.deployment_target = '10.9'

  s.source       = { :git => 'https://github.com/rnine/AMCoreAudio.git', :tag => s.version }
  s.source_files = 'AMCoreAudio/*.{swift,h,m}'

  s.requires_arc = true
end
