/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTComponent.h"

#import <CoreText/CoreText.h>

typedef enum : NSUInteger {
    AWRTAttchmentBoundsDependContent,
    AWRTAttchmentBoundsDependFont,
    AWRTAttchmentBoundsDependSet,
} AWRTAttchmentBoundsDepend;

typedef enum : NSUInteger {
    AWRTAttachmentAlignCenter,
    AWRTAttachmentAlignBottom,
    AWRTAttachmentAlignTop,
} AWRTAttachmentAlign;

typedef enum : NSUInteger {
    AWRTAttachmentViewScaleTypeByWidth,
    AWRTAttachmentViewScaleTypeByHeight,
    AWRTAttachmentViewScaleTypeAuto,
} AWRTAttachmentViewScaleType;

///链式操作
@class AWRTAttachmentComponent;
typedef AWRTAttachmentComponent *(^AWRTAttachmentComponentChain)(id);

/// component最终生成的附件，会传递给AWRichText作为绘制图像的依据（尺寸和内容）
@interface AWRTAttachment : NSObject<NSCoding, NSCopying>
/// UIImage或UIView
@property (nonatomic, strong) id content;

/// 缩放模式
@property (nonatomic, unsafe_unretained) AWRTAttachmentViewScaleType scaleType;

/// 尺寸
@property (nonatomic, unsafe_unretained) CGRect bounds;

/// 对齐方式
@property (nonatomic, unsafe_unretained) AWRTAttachmentAlign alignment;

/// 字体信息
@property (nonatomic, unsafe_unretained) CGFloat fontAscent;
@property (nonatomic, unsafe_unretained) CGFloat fontDescent;

/// 是否绘制框线
@property (nonatomic, unsafe_unretained) BOOL debugFrame;

/// core text attachment 载体
@property (nonatomic, unsafe_unretained) CTRunDelegateRef ctRunDelegateRef;

/// 计算出的字体信息
@property (nonatomic, readonly, unsafe_unretained) CGFloat attachmentAscent;
@property (nonatomic, readonly, unsafe_unretained) CGFloat attachmentDescent;

@end

@interface AWRTAttachmentComponent : AWRTComponent

@property (nonatomic, strong) id content;

/// 可用于AWRTViewComponent，AWImageComponent暂时未用此属性
/// 用于AWRTViewComponent时，表示如果View的frame同coreText计算出来的位置大小不同时，View的缩放方式。
/// 一般说来：boundsDepend为AWRTAttchmentBoundsDependFont和AWRTAttchmentBoundsDependSet时才会出现此种情况。
/// AWRTAttachmentViewScaleTypeByWidth 表示按照宽度比例等比缩放
/// AWRTAttachmentViewScaleTypeByWidth 表示按照高度比例等比缩放
/// AWRTAttachmentViewScaleTypeByAuto 表示不缩放，只修改frame
@property (nonatomic, unsafe_unretained) AWRTAttachmentViewScaleType scaleType;

/// 缩放比例
@property (nonatomic, unsafe_unretained) CGFloat contentSizeScale;

/// 生成的attachment，此对象会被传递给AWRichText做绘制时的上下文
@property (nonatomic, readonly, strong) AWRTAttachment *attachment;

/// alignment 同周围文字的对齐方式
@property (nonatomic, unsafe_unretained) AWRTAttachmentAlign alignment;

/// bounds计算方法
/// AWRTAttchmentBoundsDependContent 表示根据View或Image自身的尺寸绘制尺寸
/// AWRTAttchmentBoundsDependFont 表示根据字体高度计算绘制的尺寸
/// AWRTAttchmentBoundsDependSet 表示绘制的尺寸使用当前设置的bounds属性
@property (nonatomic, unsafe_unretained) AWRTAttchmentBoundsDepend boundsDepend;

/// 绘制尺寸
@property (nonatomic, unsafe_unretained) CGRect bounds;

/// 绘制位置偏移
@property (nonatomic, unsafe_unretained) CGPoint offset;

#pragma mark - build attach
/// 创建AWRTAttachment
-(void) buildAttachment;

#pragma mark - override
/// 获取View或Image的本身尺寸
-(CGRect) contentPresetBounds;

#pragma mark - chains
-(AWRTAttachmentComponentChain)AWContent;
-(AWRTAttachmentComponentChain)AWContentSizeScale;
-(AWRTAttachmentComponentChain)AWBounds;
-(AWRTAttachmentComponentChain)AWAlignment;
-(AWRTAttachmentComponentChain)AWBoundsDepend;
-(AWRTAttachmentComponentChain)AWOffsets;
-(AWRTAttachmentComponentChain)AWScaleType;

-(AWRTAttachmentComponentChain)AWFont;
-(AWRTAttachmentComponentChain)AWPaddingLeft;
-(AWRTAttachmentComponentChain)AWPaddingRight;
-(AWRTAttachmentComponentChain)AWDebugFrame;
@end
