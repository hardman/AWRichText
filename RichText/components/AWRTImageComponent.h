//
//  AWRTImageComponent.h
//  AWMvc
//
//  Created by wanghongyu on 3/3/17.
//  Copyright © 2017年 wanghongyu. All rights reserved.
//

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

@end
