/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <UIKit/UIKit.h>

///gif代码参考SDWebImage
@interface UIImage(AWGif)

+ (UIImage *)animatedGIFNamed:(NSString *)name;
+ (UIImage *)animatedGIFWithData:(NSData *)data;

@end
