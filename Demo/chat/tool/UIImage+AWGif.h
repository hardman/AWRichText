//
//  AWGif.h
//  AWRichText
//
//  Created by kaso on 21/12/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

#import <UIKit/UIKit.h>

///gif代码取自SDWebImage
@interface UIImage(AWGif)

+ (UIImage *)animatedGIFNamed:(NSString *)name;
+ (UIImage *)animatedGIFWithData:(NSData *)data;

@end
