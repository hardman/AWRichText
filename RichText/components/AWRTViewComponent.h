/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTAttachmentComponent.h"

@class AWRTViewComponent;
typedef AWRTViewComponent *(^AWRTViewComponentChain)(id);

@interface AWRTViewComponent : AWRTAttachmentComponent

///view请提前设置好尺寸
@property (nonatomic, strong) UIView *view;

#pragma mark - chain
-(AWRTViewComponentChain)AWView;

-(AWRTViewComponentChain)AWContent;
-(AWRTViewComponentChain)AWBounds;
-(AWRTViewComponentChain)AWAlignment;
-(AWRTViewComponentChain)AWBoundsDepend;
-(AWRTViewComponentChain)AWOffsets;
-(AWRTViewComponentChain)AWScaleType;

-(AWRTViewComponentChain)AWFont;
-(AWRTViewComponentChain)AWPaddingLeft;
-(AWRTViewComponentChain)AWPaddingRight;
-(AWRTViewComponentChain)AWDebugFrame;

-(AWRTViewComponentChain)AWAsyncArchiveBlock;
@end
