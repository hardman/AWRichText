/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTAttachmentComponent.h"

@class AWRTImageComponent;
typedef AWRTImageComponent *(^AWRTImageComponentChain)(id);

@interface AWRTImageComponent : AWRTAttachmentComponent

//对图片进行等比缩放
@property (nonatomic, unsafe_unretained) CGFloat imageScale;

#pragma mark chain funcs
-(AWRTImageComponentChain)AWImagePath;
-(AWRTImageComponentChain)AWImage;
-(AWRTImageComponentChain)AWImageScale;

-(AWRTImageComponentChain)AWContent;
-(AWRTImageComponentChain)AWBounds;
-(AWRTImageComponentChain)AWAlignment;
-(AWRTImageComponentChain)AWBoundsDepend;
-(AWRTImageComponentChain)AWOffsets;

-(AWRTImageComponentChain)AWFont;
-(AWRTImageComponentChain)AWPaddingLeft;
-(AWRTImageComponentChain)AWPaddingRight;
-(AWRTImageComponentChain)AWDebugFrame;

-(AWRTImageComponentChain) AWAsyncArchiveBlock;

@end
