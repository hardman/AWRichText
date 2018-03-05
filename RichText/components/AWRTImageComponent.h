/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTAttachmentComponent.h"

@class AWRTImageComponent;
typedef AWRTImageComponent *(^AWRTImageComponentChain)(id);
typedef void (^AWRTImagComponentAsyncArchiveBlock)(AWRTImageComponent *imageComp);

@interface AWRTImageComponent : AWRTAttachmentComponent

//对图片进行等比缩放
@property (nonatomic, unsafe_unretained) CGFloat imageScale;

//异步构造
@property (nonatomic, strong) AWRTImagComponentAsyncArchiveBlock asyncArchiveBlock;

#pragma mark chain funcs
-(AWRTImageComponentChain)AWAsyncArchiveBlock;
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

@end
