Pod::Spec.new do |s|
  s.name         = "TZImagePickerControllerSwift"
  s.version      = "1.0.4.5"
  s.summary      = "A clone of UIImagePickerController, support picking multiple photos、original photo and video"
  s.homepage     = "https://github.com/tanhuang/TZImagePickerControllerSwift"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "tanhuang" => "tanhuangios@foxmail.com" }
  s.platform     = :ios
  s.swift_version = "4.0"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/tanhuang/TZImagePickerControllerSwift.git", :tag => s.version }
  s.requires_arc = true
  s.resources    = "TZImagePickerControllerSwift/TZImagePickerController/*.{png,xib,nib,bundle}"
  s.source_files = "TZImagePickerControllerSwift/TZImagePickerController/*.swift"
end