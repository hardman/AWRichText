//
//  AWRTViewComponent.h
//  AWRichText
//
//  Created by kaso on 6/12/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

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
@end
