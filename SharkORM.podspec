Pod::Spec.new do |s|

    s.name              = 'SharkORM'
    s.version           = '2.3.43'
    s.summary           = 'SQLite based ORM for iOS, tvOS & macOS'
    s.homepage          = 'http://sharkorm.com/'

    s.license      =  { :type => "MIT", :file => "LICENSE" }
    s.author             = { "SharkSync.io, (Adrian Herridge, Neil Bostrom)" => "devs@sharksync.io" }
    s.social_media_url   = "https://twitter.com/sharkorm"
    s.ios.deployment_target = "9.0"
    #s.osx.deployment_target = "10.8"
    #s.tvos.deployment_target = "10.0"
s.source            = { :http => 'https://github.com/sharksync/SharkORMCore/releases/download/v2.3.43/SharkORM_Framework_v2.3.43.zip' }

    s.ios.deployment_target = '9.0'
    s.ios.vendored_frameworks = 'SharkORM.framework'

end
