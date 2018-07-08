Pod::Spec.new do |s|

    s.name              = 'SharkORM'
    s.version           = '2.3.55'
    s.summary           = 'SQLite based ORM for iOS, tvOS & macOS'
    s.homepage          = 'http://sharkorm.com/'
    s.license           =  { :type => "MIT", :file => "LICENSE" }
    s.author             = { "SharkSync.io, (Adrian Herridge, Neil Bostrom)" => "devs@sharksync.io" }
    s.social_media_url   = "https://twitter.com/sharkorm"
    s.ios.deployment_target = "9.0"
    #s.osx.deployment_target = "10.8"
    #s.tvos.deployment_target = "10.0"
    s.source            = { :git => "https://github.com/sharksync/SharkORMCore.git", :tag => "v2.3.55"}
    s.ios.deployment_target = '9.0'
    s.ios.vendored_frameworks = 'SharkORM.framework'
    s.source_files  = "SharkORM.framework/**/*.{h,m,c}"
    s.preserve_paths = 'SharkORM.framework'
    s.public_header_files = 'SharkORM.framework/**/*.h'
    s.vendored_frameworks = 'SharkORM.framework'
    s.frameworks = 'Foundation','SharkORM'
    s.xcconfig   = { 'FRAMEWORK_SEARCH_PATHS' => '$(SRCROOT)/SharkORM/' }

end
