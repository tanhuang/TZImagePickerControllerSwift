Pod::Spec.new do |s|
  s.name         = "TZImagePickerControllerSwift"
  s.version      = "1.0.0"
  s.summary      = "A clone of UIImagePickerController, support picking multiple photos、original photo and video"
  s.homepage     = "https://github.com/tanhuang/TZImagePickerControllerSwift"
  s.license      = "MIT"
  s.author       = { "tanhuang" => "tanhuangios@foxmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/tanhuang/TZImagePickerControllerSwift.git", :tag => "1.0.0" }
  s.requires_arc = true
  s.resources    = "TZImagePickerControllerSwift/TZImagePickerControllerSwift/*.{png,xib,nib,bundle}"
  s.source_files = "TZImagePickerControllerSwift/TZImagePickerControllerSwift/*.{h,m}"
end