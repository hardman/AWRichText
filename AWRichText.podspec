Pod::Spec.new do |s|
  s.name         = "AWRichText"
  s.version      = "1.0.0"
  s.summary      = "基于CoreText，面向对象，极简，易用，高效，并不仅仅局限于图文混排的富文本排版神器。"
  s.description  = <<-DESC
  解决NSAttributedString的如下问题：
  1. 太难用了，属性那么多，而且使用字典构造，每次用都要查一下文档。更不要说大规模使用了。
  2. 不支持GIF动图
  3. 不支持局部点击
  4. 不支持UIView与文字进行混排
                   DESC
  s.homepage     = "https://github.com/hardman/AWRichText"
  s.screenshots  = "https://raw.githubusercontent.com/hardman/OutLinkImages/master/AWRichText/AWRichText-demo.gif"
  s.license      = "MIT"
  s.author             = "wanghongyu"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/hardman/AWRichText", :tag => "#{s.version}" }
  s.source_files  = "RichText", "RichText/**/*.{h,m}"
  s.public_header_files = "RichText/**/*.h"
end
