//
//  ChatView.h
//  AWRichText
//
//  Created by kaso on 21/12/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AWRichText.h"

typedef enum : NSUInteger {
    ChatViewCellRTCompTypeText,//文本
    ChatViewCellRTCompTypeGif,//gif
    ChatViewCellRTCompTypeImage,//image
    ChatViewCellRTCompTypeUIView,//UIView
} ChatViewCellRTCompType;

typedef void(^OnTouchCompBlock)(AWRTComponent *comp, AWRTLabelTouchEvent touchEvent);

@interface ChatViewComponentModel : NSObject
///类型
@property (nonatomic, unsafe_unretained) ChatViewCellRTCompType type;

///字体
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *backgroundColor;

///阴影
@property (nonatomic, unsafe_unretained) CGFloat shadowBlurRadius;
@property (nonatomic, strong) UIColor *shadowColor;
@property (nonatomic, unsafe_unretained) CGSize shadowOffset;

///文本 or link
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *color;

///图片 or Gif or UIView
@property (nonatomic, unsafe_unretained) AWRTAttchmentBoundsDepend depend;

///图片 or Gif
@property (nonatomic, unsafe_unretained) CGRect bounds;
@property (nonatomic, strong) UIImage *image;

///UIView
@property (nonatomic, strong) UIView *view;

///点击
@property (nonatomic, strong) OnTouchCompBlock onTouchComp;

///任意gif
+(ChatViewComponentModel *)gifComponentModelWithFont:(UIFont *)font image:(UIImage *)image;
///任意view
+(ChatViewComponentModel *)viewComponentModelWithFont:(UIFont *)font view:(UIView *)view;
///任意图片
+(ChatViewComponentModel *)imageComponentModelWithFont:(UIFont *)font image:(UIImage *)image;
///任意文本
+(ChatViewComponentModel *)textComponentModelWithFont:(UIFont *)font text:(NSString *)text color:(UIColor *)color;
@end

@class ChatCellRichTextBuilder;
@interface ChatViewModel : NSObject

///包含的components
@property (nonatomic, strong) NSArray *compModels;

///richtext builder 用于创建richtext，并计算 cell高度
-(ChatCellRichTextBuilder *)richtextBuilder;

///最大宽度
@property (nonatomic, unsafe_unretained) CGFloat maxWid;

+(instancetype) modelWithCompModels:(NSArray *)array maxWid:(CGFloat) maxWid;

@end

@interface ChatCellRichTextBuilder : NSObject
-(AWRichText *) richtext;
-(CGFloat) cellHeight;
+(instancetype) builderWithModel:(ChatViewModel *) model maxWid:(CGFloat) maxWid;
@end

@interface ChatView : UIView
-(void) addModel:(ChatViewModel *)model;

@property (nonatomic, unsafe_unretained) BOOL alwaysShowDebugFrame;

+(void) testWithSuperView:(UIView *)view;
@end
