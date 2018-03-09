/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRichTextLabel.h"
#import "AWRichText.h"
#import <objc/runtime.h>

#define AWRichTextEC @"AWRichTextEC"

@interface AWRichTextLabel()<AWRichTextDelegate>
@property (nonatomic, weak) AWRTComponent *touchingComponent;

@property (nonatomic, unsafe_unretained) BOOL isRedrawingRTLabel;
@end

@implementation AWRichTextLabel

@synthesize richText=_richText;

+(instancetype) labelWithRichText:(AWRichText *)richText rtFrame:(CGRect)rtFrame{
    return [[self alloc] initWithRichText:richText rtFrame:rtFrame];
}

+(instancetype) labelWithRichText:(AWRichText *)richText{
    return [[self alloc] initWithRichText:richText];
}

-(instancetype) initWithRichText:(AWRichText *)richText{
    return [self initWithRichText:richText rtFrame:CGRectZero];
}

-(instancetype)initWithRichText:(AWRichText *)richText rtFrame:(CGRect)rtFrame{
    self = [super init];
    if (self) {
        _rtFrame = rtFrame;
        
        self.richText = richText;
    }
    return self;
}

///设置或修改richtext
-(void)setRichText:(AWRichText *)richText{
    if ([self.richText isEqual:richText]) {
        return;
    }
    
    _richText = richText;
    
    [richText addListener:(id<AWRichTextDelegate>)self];
    
    self.userInteractionEnabled = YES;
    
    if ([self.richText checkIfInitingState]) {
        [self.richText setNeedsBuild];
    }else{
        [self redrawRichTextLabel];
    }
}

-(void)setRtFrame:(CGRect)rtFrame{
    if (CGRectEqualToRect(_rtFrame, rtFrame)) {
        return;
    }
    
    _rtFrame = rtFrame;
    
    [self redrawRichTextLabel];
}

-(void)setRtMaxWidth:(CGFloat)rtMaxWidth{
    if (_rtFrame.size.width == rtMaxWidth) {
        return;
    }
    
    _rtFrame = CGRectMake(_rtFrame.origin.x, _rtFrame.origin.y, rtMaxWidth, _rtFrame.size.height);
}

-(CGFloat)rtMaxWidth{
    return _rtFrame.size.width;
}

-(BOOL) usingAutoLayout{
    if (self.constraints.count > 0) {
        return YES;
    }
    return _usingAutoLayout;
}

#pragma mark - touch 处理
-(AWRTComponent *)componentWithTouchPoint:(CGPoint) point{
    __block AWRTComponent *retComponent = nil;
    [self.richText enumationComponentsWithBlock:^(AWRTComponent *comp, BOOL *stop) {
        if (comp.touchable && (comp.touchCallback || self.richText.touchCallback)) {
            for (NSValue *touchRects in comp.touchRects) {
                if ([touchRects respondsToSelector:@selector(CGRectValue)]) {
                    CGRect rect = touchRects.CGRectValue;
                    if (CGRectContainsPoint(rect, point)) {
                        retComponent = comp;
                        *stop = YES;
                        break;
                    }
                }
            }
        }
    }];
    return retComponent;
}

-(void)notifyRichTextTouchComponent:(AWRTComponent *)comp touchEvent:(AWRTLabelTouchEvent) touchEvent{
    if (comp.touchCallback) {
        comp.touchCallback(comp, touchEvent);
    }
    if (self.richText.touchCallback) {
        self.richText.touchCallback(comp, touchEvent);
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    self.touchingComponent = [self componentWithTouchPoint:point];
    if (self.touchingComponent) {
        [self notifyRichTextTouchComponent:self.touchingComponent touchEvent:AWRTLabelTouchEventBegan];
    }
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.touchingComponent) {
        UITouch *touch = touches.anyObject;
        CGPoint point = [touch locationInView:self];
        AWRTComponent *touchingComp =  [self componentWithTouchPoint:point];
        CGPoint prePoint = [touch previousLocationInView:self];
        AWRTComponent *preTouchingComp = [self componentWithTouchPoint:prePoint];
        BOOL isMovedIn = self.touchingComponent == touchingComp && self.touchingComponent != preTouchingComp;
        BOOL isMovedOut = self.touchingComponent != touchingComp && self.touchingComponent == preTouchingComp;
        if (isMovedIn) {
            [self notifyRichTextTouchComponent:self.touchingComponent touchEvent:AWRTLabelTouchEventMovedIn];
        }else if(isMovedOut){
            [self notifyRichTextTouchComponent:self.touchingComponent touchEvent:AWRTLabelTouchEventMovedOut];
        }else{
            [self notifyRichTextTouchComponent:self.touchingComponent touchEvent:AWRTLabelTouchEventMoved];
        }
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.touchingComponent) {
        UITouch *touch = touches.anyObject;
        CGPoint point = [touch locationInView:self];
        AWRTComponent *touchingComp =  [self componentWithTouchPoint:point];
        if (self.touchingComponent == touchingComp) {
            [self notifyRichTextTouchComponent:self.touchingComponent touchEvent:AWRTLabelTouchEventEndedIn];
        }else{
            [self notifyRichTextTouchComponent:self.touchingComponent touchEvent:AWRTLabelTouchEventEndedOut];
        }
    }
    
    self.touchingComponent = nil;
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.touchingComponent) {
        [self notifyRichTextTouchComponent:self.touchingComponent touchEvent:AWRTLabelTouchEventCancelled];
    }
    
    self.touchingComponent = nil;
}

#pragma mark - awrichtext delegate
/// 收到richText更新的消息，触发drawRect进行重绘
-(void)updatedForAWRichText:(AWRichText *)richText{
    if (richText == self.richText) {
        [self redrawRichTextLabel];
    }
}

#pragma mark - awrichtext update
-(void) redrawRichTextLabel{
    if ([self.richText checkIfInitingState]) {
        return;
    }
    
    if (self.isRedrawingRTLabel) {
        return;
    }
    
    self.isRedrawingRTLabel = YES;
    
    if (self.usingAutoLayout) {
        self.preferredMaxLayoutWidth = _rtFrame.size.width;
        [self invalidateIntrinsicContentSize];
    }else{
        self.frame = _rtFrame;
        if (self.frame.size.width == 0 || self.frame.size.height == 0) {
            [self sizeToFit];
        }
    }
    
    [self setNeedsDisplay];
    
    self.isRedrawingRTLabel = NO;
}

#pragma mark - 绘制相关
///覆盖系统函数，使用coretext绘制文本
-(void)drawRect:(CGRect)rect{
    [self.richText drawRect:rect label:self];
}

///根据属性，自行计算label的size
-(CGSize)sizeThatFits:(CGSize)size{
    return [self.richText sizeThatFits:size];
}

///autolayout中固有尺寸，用于自适应尺寸
-(CGSize)intrinsicContentSize{
    return [self.richText intrinsicContentSizeWithPreferMaxWidth:self.preferredMaxLayoutWidth];
}

#pragma mark - coding
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        self.richText = [aDecoder decodeObjectForKey:AWRichTextEC];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.richText forKey:AWRichTextEC];
}

@end

