Pod::Spec.new do |s|
  s.name             = 'DKPhotoGallery'
  s.version          = '0.0.19'
  s.summary          = 'A Photo Gallery / Browser / Viewer for iOS written in Swift'
  s.homepage         = 'https://github.com/zhangao0086/DKPhotoGallery'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bannings' => 'zhangao0086@gmail.com' }
  s.platform         = :ios, '9.0'
  s.source           = { :path => '.' }
  s.frameworks       = 'Foundation', 'UIKit', 'Photos', 'AVFoundation', 'AVKit'
  s.requires_arc     = true
  s.swift_versions   = ['4.2', '5']
  s.dependency 'SDWebImage'
  s.dependency 'SwiftyGif'

  s.subspec 'Core' do |ss|
    ss.dependency 'DKPhotoGallery/Model'
    ss.dependency 'DKPhotoGallery/Preview'
    ss.source_files = [
      'DKPhotoGallery/DKPhotoGallery.swift',
      'DKPhotoGallery/DKPhotoGalleryContentVC.swift',
      'DKPhotoGallery/DKPhotoGalleryScrollView.swift',
      'DKPhotoGallery/DKPhotoPreviewFactory.swift',
      'DKPhotoGallery/DKPhotoIncrementalIndicator.swift',
      'DKPhotoGallery/Transition/*.swift'
    ]
  end

  s.subspec 'Model' do |ss|
    ss.source_files = 'DKPhotoGallery/DKPhotoGalleryItem.swift'
  end

  s.subspec 'Preview' do |ss|
    ss.dependency 'DKPhotoGallery/Model'
    ss.dependency 'DKPhotoGallery/Resource'
    ss.source_files = 'DKPhotoGallery/Preview/**/*.swift'
  end

  s.subspec 'Resource' do |ss|
    ss.resource_bundles = { 'DKPhotoGallery' => 'DKPhotoGallery/Resource/Resources/*' }
    ss.source_files = 'DKPhotoGallery/Resource/*.swift'
  end
end
