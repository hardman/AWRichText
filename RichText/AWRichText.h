/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <UIKit/UIKit.h>
#import "AWRTComponent.h"
#import "AWRTTextComponent.h"
#import "AWRTImageComponent.h"
#import "AWRTViewComponent.h"
#import "AWRichTextLabel.h"
#import "AWRTWeekRefrence.h"

typedef enum : NSUInteger {
    AWRTComponentTypeText,
    AWRTComponentTypeImage,
    AWRTComponentTypeView,
} AWRTComponentType;

typedef enum : NSUInteger {
    AWRichTextBuildStateIniting,
    AWRichTextBuildStateStable,
    AWRichTextBuildStateWillBuilding,
    AWRichTextBuildStateBuilding,
    AWRichTextBuildStateBuilt,
} AWRichTextBuildState;

@protocol AWRichTextDelegate<NSObject>
@optional
-(void) updatedForAWRichText:(AWRichText *)richText;
-(void) awRichText:(AWRichText *)richText fmBuildState:(AWRichTextBuildState)from toBuildState:(AWRichTextBuildState)to;
@end

typedef AWRichText *(^AWRichTextPropertyChain)(id);

/// 缓存类
@interface AWRTComponentPool : NSObject
-(AWRTComponent *)retainComponentWithType:(AWRTComponentType)type;
-(void) releaseComponent:(AWRTComponent *)comp;

-(AWRTTextComponent *)retainTextComponent;
-(void) releaseTextComponent:(AWRTTextComponent *)textComponent;

-(AWRTImageComponent *)retainImageComponent;
-(void) releaseImageComponent:(AWRTImageComponent *)imageComponent;

-(AWRTViewComponent *)retainViewComponent;
-(void) releaseViewComponent:(AWRTViewComponent *)viewComponent;
@end;

///创建富文本
@interface AWRichText : NSObject<NSCopying, NSCoding, AWRTComponentUpdateDelegate>

#pragma mark - 承载label
///当AWRichtext创建好了之后可以通过此方法直接创建Label
-(AWRichTextLabel *) createRichTextLabel;

-(void) addListener:(id<AWRichTextDelegate>)listener;
-(void) removeListener:(id<AWRichTextDelegate>)listener;

///组件（component）被点击时的回调，component.touchable必须为YES才能接收到回调
@property (nonatomic, strong) void (^touchCallback)(AWRTComponent * comp, AWRTLabelTouchEvent touchEvent);

#pragma mark - 构造富文本
-(BOOL) addComponent:(AWRTComponent *)component;
-(BOOL) addComponents:(NSArray *)components;
-(BOOL) addComponentsFromRichText:(AWRichText *)richText;
-(BOOL) removeComponent:(AWRTComponent *)component;
-(BOOL) removeAllComponents;
-(AWRTComponent *)componentWithIndex:(NSInteger) index;
-(AWRTComponent *)componentWithTag:(NSString *)tag;
-(NSInteger) componentCount;
-(void) enumationComponentsWithBlock:(void(^)(AWRTComponent *comp, BOOL *stop))block;
-(void) enumationComponentsWithBlock:(void(^)(AWRTComponent *comp, BOOL *stop))block reverse:(BOOL)reverse;

@property (nonatomic, readonly, strong) AWRTComponentPool *pool;
-(AWRTComponent *) addComponentFromPoolWithType:(AWRTComponentType)type;
-(BOOL) removeAndAddToPoolWithComponent:(AWRTComponent *)comp;
-(BOOL) removeAllComponentsAndAddToPool;

#pragma mark - 属性操作
///行距
@property (nonatomic, unsafe_unretained) CGFloat lineSpace;
///文本对齐
@property (nonatomic, unsafe_unretained) NSTextAlignment alignment;
///breakMode
@property (nonatomic, unsafe_unretained) NSLineBreakMode lineBreakMode;
///paragraphStyle
@property (nonatomic, strong) NSMutableParagraphStyle *paragraphStyle;
///文字过多时的省略符号，如果不指定，默认为"..."
@property (nonatomic, strong) AWRTComponent *truncatingTokenComp;
///是否强制显示debugFrame
@property (nonatomic, unsafe_unretained) BOOL alwaysShowDebugFrames;
///是否自动播放gif动画
@property (nonatomic, unsafe_unretained) BOOL isGifAnimAutoRun;

#pragma mark - 属性的链式操作
///链式操作
-(AWRichTextPropertyChain) AWLineSpace;
-(AWRichTextPropertyChain) AWAlignment;
-(AWRichTextPropertyChain) AWLineBreakMode;
-(AWRichTextPropertyChain) AWParagraphStyle;
-(AWRichTextPropertyChain) AWTruncatingTokenComp;
-(AWRichTextPropertyChain) AWAlwaysShowDebugFrames;
-(AWRichTextPropertyChain) AWIsGifAnimAutoRun;

#pragma mark - 获取NSAttributedString，提前计算RichText的size时一般直接调用此方法。
///可直接调用此方法获取attributedString，直接触发build及drawRect
///因为计算富文本尺寸需要_attributedString不为空，因此想要提前计算RichText的size时，可直接调用此方法。
-(NSAttributedString *)attributedString;

#pragma mark - 绘制
-(void) drawRect:(CGRect) rect label:(UILabel *)label;

#pragma mark - 尺寸计算
-(CGSize)sizeThatFits:(CGSize)size;
-(CGSize)intrinsicContentSizeWithPreferMaxWidth:(CGFloat)maxWidth;

//实际绘制行数，会在计算尺寸和绘制中赋值，只有成功触发计算尺寸及绘制后，值才是正确的
-(NSUInteger) drawingLineCount;

#pragma mark - 动画
///如果components中有gif，如果某些情况下动画停止了（比如label移除后又添加），可以使用此函数。
-(void) letAnimStartOrStop:(BOOL) isStart;
@end
