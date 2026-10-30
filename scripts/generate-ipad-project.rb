require 'xcodeproj'
require 'fileutils'
root = File.expand_path('..', __dir__)
Dir.chdir(root) do
  project = Xcodeproj::Project.new('iPad/Grade2MathPractice.xcodeproj')
  target = project.new_target(:application, 'Grade2MathPracticeIPad', :ios, '17.0')
  shared = project.main_group.new_group('Shared')
  tablet = project.main_group.new_group('iPad')
  files = Dir['Sources/PracticeCore/*.swift'] + %w[Sources/Grade2MathPractice/PracticeStore.swift Sources/Grade2MathPractice/GlassTheme.swift Sources/Grade2MathPractice/ContentView.swift]
  target.add_file_references(files.map { |path| shared.new_file('../' + path) })
  target.add_file_references(Dir['iPad/Sources/*.swift'].map { |path| tablet.new_file(path.sub('iPad/', '')) })
  resources = project.main_group.new_group('Resources')
  target.resources_build_phase.add_file_reference(resources.new_file('../Sources/Grade2MathPractice/Resources/questions.json'))
  target.resources_build_phase.add_file_reference(resources.new_file('Assets.xcassets'))
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION' => '6.0', 'PRODUCT_NAME' => 'Grade2MathPracticeIPad',
      'PRODUCT_BUNDLE_IDENTIFIER' => 'dev.yangyao.Grade2MathPractice.iPad',
      'GENERATE_INFOPLIST_FILE' => 'YES', 'INFOPLIST_KEY_CFBundleDisplayName' => '口算练习',
      'TARGETED_DEVICE_FAMILY' => '2', 'SUPPORTS_MACCATALYST' => 'NO',
      'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon', 'CODE_SIGN_STYLE' => 'Automatic',
      'INFOPLIST_KEY_UIApplicationSceneManifest_Generation' => 'YES',
      'INFOPLIST_KEY_UILaunchScreen_Generation' => 'YES',
      'INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents' => 'YES',
      'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad' => 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
    })
  end
  project.save
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(target)
  scheme.set_launch_target(target)
  scheme.save_as(project.path, 'Grade2MathPracticeIPad', true)
end
