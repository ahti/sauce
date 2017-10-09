Pod::Spec.new do |s|

    s.name         = "Sauce"
    s.version      = "0.0.1"
    s.summary      = "Build concise, reusable and composable Collection View data sources."

    s.description  = <<-DESC
        Sauce provides utilities to build reusable and composable data sources for
        your Collection Views. It's inspired by the WWDC 2014 Session "Advanced
        User Interfaces Using Collection View."
                   DESC

    s.homepage     = "https://github.com/ahti/Sauce"

    s.license      = { :type => "MIT", :file => "LICENSE" }

    s.author       = { "Lukas Stabe" => "lukas@stabe.de" }

    s.ios.deployment_target = "9.0"
    # s.tvos.deployment_target = "9.0"

    s.source       = { :git => "https://github.com/ahti/Sauce.git", :tag => "#{s.version}" }

    s.source_files = "Sources/**/*.swift"

    s.test_spec 'Tests' do |test|
        test.source_files  = "Tests/**/*.swift"
        test.exclude_files = "Tests/LinuxMain.swift"
        test.framework     = "XCTest"
    end

end
