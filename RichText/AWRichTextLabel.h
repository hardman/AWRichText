/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <UIKit/UIKit.h>

@class AWRichText;
@interface AWRichTextLabel: UILabel

+(instancetype) labelWithRichText:(AWRichText *)richText rtFrame:(CGRect)rtFrame;
+(instancetype) labelWithRichText:(AWRichText *)richText;

-(instancetype) initWithRichText:(AWRichText *)richText rtFrame:(CGRect)rtFrame;
-(instancetype) initWithRichText:(AWRichText *)richText;

@property (nonatomic, strong) AWRichText *richText;

@property (nonatomic, unsafe_unretained) CGRect rtFrame;

@property (nonatomic, unsafe_unretained) CGFloat rtMaxWidth;

@end
