/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTComponent.h"

@class AWRTTextComponent;
typedef AWRTTextComponent *(^AWTextComponentChain)(id);

@interface AWRTTextComponent : AWRTComponent
///文字背景色
@property (nonatomic, strong) UIColor *backgroundColor;

///文字颜色
@property (nonatomic, strong) UIColor *color;

///文本
@property (nonatomic, copy) NSString *text;

///左右分隔符，如引号，书名号等，例如 [我是文本]
@property (nonatomic, copy) NSString *leftSeperateString;
@property (nonatomic, copy) NSString *rightSeperateString;

///分隔符颜色
@property (nonatomic, strong) UIColor *seperateStringColor;

///阴影
@property (nonatomic, unsafe_unretained) CGFloat shadowBlurRadius;
@property (nonatomic, strong) UIColor *shadowColor;
@property (nonatomic, unsafe_unretained) CGSize shadowOffset;

///描边
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, unsafe_unretained) CGFloat strokeWidth;

///下划线
@property (nonatomic, strong) UIColor *underlineColor;
@property (nonatomic, unsafe_unretained) NSUnderlineStyle underlineStyle;

///连字符：NSLigatureAttributeName
@property (nonatomic, unsafe_unretained) NSInteger ligature;

///字符间距：NSKernAttributeName
@property (nonatomic, unsafe_unretained) CGFloat kern;

///删除线：NSStrikethroughStyleAttributeName
@property (nonatomic, unsafe_unretained) NSInteger strikethroughStyle;
@property (nonatomic, strong) UIColor *strikethroughColor;

///链接：NSLinkAttributeName
@property (nonatomic, copy) NSString *linkUrl;

///基线偏移：NSBaselineOffsetAttributeName
@property (nonatomic, unsafe_unretained) CGFloat baselineOffset;

///未实现：
///NSParagraphStyleAttributeName(可在AWRichText中设置)
///NSVerticalGlyphFormAttributeName(横排／竖排)
///NSTextEffectAttributeName
///NSObliquenessAttributeName
///NSExpansionAttributeName
///NSWritingDirectionAttributeName(固定为左右方向)

#pragma mark chain
-(AWTextComponentChain) AWShadowBlurRadius;
-(AWTextComponentChain) AWShadowColor;
-(AWTextComponentChain) AWShadowOffset;
-(AWTextComponentChain) AWStrokeColor;
-(AWTextComponentChain) AWStrokeWidth;
-(AWTextComponentChain) AWColor;
-(AWTextComponentChain) AWBackgroundColor;
-(AWTextComponentChain) AWText;
-(AWTextComponentChain) AWLeftSeperateString;
-(AWTextComponentChain) AWRightSeperateString;
-(AWTextComponentChain) AWSeperateStringColor;
-(AWTextComponentChain) AWUnderlineColor;
-(AWTextComponentChain) AWUnderlineStyle;

-(AWTextComponentChain) AWLigature;
-(AWTextComponentChain) AWKern;
-(AWTextComponentChain) AWStrikethroughStyle;
-(AWTextComponentChain) AWStrikethroughColor;
-(AWTextComponentChain) AWLinkUrl;
-(AWTextComponentChain) AWBaselineOffset;

-(AWTextComponentChain) AWFont;
-(AWTextComponentChain) AWPaddingLeft;
-(AWTextComponentChain) AWPaddingRight;
-(AWTextComponentChain) AWDebugFrame;

@end
