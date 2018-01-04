//
//  AWRichText.m
//  AWMvc
//
//  Created by wanghongyu on 3/3/17.
//  Copyright © 2017年 wanghongyu. All rights reserved.
//

#import "AWRichText.h"
#import "AWRTWeekRefrence.h"
#import "AWRTViewComponent.h"

#import <CoreText/CoreText.h>

#define AWRichTextMinValue -100000
#define AWRichTextMaxValue 100000

#define AWRTLineSpace @"AWRTLineSpace"
#define AWRTAlignment @"AWRTAlignment"
#define AWRTLineBreakMode @"AWRTLineBreakMode"
#define AWRTParagraphStyle @"AWRTParagraphStyle"
#define AWRTTruncatingTokenComp @"AWRTTruncatingTokenComp"
#define AWRTComponents @"AWRTComponents"

/// 缓存类
@interface AWRTComponentPool()
@property (nonatomic, strong) NSMutableArray *textCompArray;
@property (nonatomic, strong) NSMutableArray *imageCompArray;
@property (nonatomic, strong) NSMutableArray *viewCompArray;
@end

@implementation AWRTComponentPool
-(NSMutableArray *)textCompArray{
    if (!_textCompArray) {
        _textCompArray = [[NSMutableArray alloc] init];
    }
    return _textCompArray;
}

-(NSMutableArray *)imageCompArray{
    if (!_imageCompArray) {
        _imageCompArray = [[NSMutableArray alloc] init];
    }
    return _imageCompArray;
}

-(NSMutableArray *)viewCompArray{
    if (!_viewCompArray) {
        _viewCompArray = [[NSMutableArray alloc] init];
    }
    return _viewCompArray;
}

-(AWRTComponent *)retainComponentWithType:(AWRTComponentType)type{
    AWRTComponent *comp = nil;
    switch (type) {
        case AWRTComponentTypeImage:
            comp = self.retainImageComponent;
            break;
        case AWRTComponentTypeView:
            comp = self.retainViewComponent;
            break;
        case AWRTComponentTypeText:
            comp = self.retainTextComponent;
            break;
    }
    return comp;
}

-(void) releaseComponent:(AWRTComponent *)comp{
    if ([comp isKindOfClass:[AWRTImageComponent class]]) {
        [self releaseImageComponent:(id)comp];
    }else if([comp isKindOfClass:[AWRTViewComponent class]]){
        [self releaseViewComponent:(id)comp];
    }else if([comp isKindOfClass:[AWRTTextComponent class]]){
        [self releaseTextComponent:(id)comp];
    }
}

-(AWRTTextComponent *)retainTextComponent{
    AWRTTextComponent *textComp = nil;
    if (self.textCompArray.count > 0) {
        textComp = self.textCompArray.lastObject;
        [self.textCompArray removeLastObject];
    }else{
        textComp = [[AWRTTextComponent alloc] init];
    }
    return textComp;
}

-(void) releaseTextComponent:(AWRTTextComponent *)textComponent{
    [self.textCompArray addObject:textComponent];
}

-(AWRTImageComponent *)retainImageComponent{
    AWRTImageComponent *imageComp = nil;
    if (self.imageCompArray.count > 0) {
        imageComp = self.imageCompArray.lastObject;
        [self.imageCompArray removeLastObject];
    }else{
        imageComp = [[AWRTImageComponent alloc] init];
    }
    return imageComp;
}

-(void) releaseImageComponent:(AWRTImageComponent *)imageComponent{
    [imageComponent emptyComponentAttributes];
    [self.imageCompArray addObject:imageComponent];
}

-(AWRTViewComponent *)retainViewComponent{
    AWRTViewComponent *viewComp = nil;
    if (self.viewCompArray.count > 0) {
        viewComp = self.viewCompArray.lastObject;
        [self.viewCompArray removeLastObject];
    }else{
        viewComp = [[AWRTViewComponent alloc] init];
    }
    return viewComp;
}

-(void) releaseViewComponent:(AWRTViewComponent *)viewComponent{
    [viewComponent emptyComponentAttributes];
    [self.viewCompArray addObject:viewComponent];
}
@end

@interface AWRichText()
/// 每个AWRichText包含多个component
/// 每个component代表一小段富文本
/// 最终将components数组中的每个component依次拼接在一起，成为AWRichText
@property (nonatomic, strong) NSMutableArray *components;

/// 最终生成的 AttributedString，可直接应用于UILabel中
@property (nonatomic, strong) NSMutableAttributedString *attributedString;

/// 可监听AWRichText的状态变化 及 构建成功等消息。
@property (nonatomic, strong) NSMutableArray *listeners;

/// 辅助变量
@property (nonatomic, unsafe_unretained) AWRichTextBuildState updateState;
@property (nonatomic, strong) NSOperationQueue *buildQueue;
@property (nonatomic, unsafe_unretained) BOOL needBuild;

/// pool
@property (nonatomic, strong) AWRTComponentPool *pool;
@end

@implementation AWRichText{
    /// 段落
    NSMutableParagraphStyle *_paragraphStyle;
}

#pragma mark - 初始化

- (instancetype) init{
    self = [super init];
    if (self) {
        [self onInit];
    }
    return self;
}

-(void) onInit{
    _buildQueue = [[NSOperationQueue alloc] init];
    _buildQueue.maxConcurrentOperationCount = 1;
    _buildQueue.qualityOfService = NSQualityOfServiceUtility;
    
    _components = [[NSMutableArray alloc] init];
    
    _paragraphStyle = [[NSMutableParagraphStyle alloc] init];
}

-(void)dealloc{
    [self.buildQueue cancelAllOperations];
}

-(AWRichTextLabel *) createRichTextLabel{
    return [AWRichTextLabel labelWithRichText:self];
}

#pragma mark - 状态变更

-(BOOL) checkUpdateStateFrom:(AWRichTextBuildState)from to:(AWRichTextBuildState)to{
    if (from == to) {
        return NO;
    }
    
    /// 状态变化方向
    /// -> [被动] initing -> stable
    /// -> [主动] stable -> 调用update函数 -> updating -> updated -> stable(self.needBuild)
    /// -> [被动] stable(self.needBuild) -> willbuilding -> building -> built([label setNeedsDisplay])
    
    /// ->initing
    if (to == AWRichTextBuildStateIniting) {
        return NO;
    }
    
    /// ->stable
    if (to == AWRichTextBuildStateStable && from != AWRichTextBuildStateBuilt) {
        return NO;
    }
    
    /// ->willbuilding
    if (to == AWRichTextBuildStateWillBuilding && from != AWRichTextBuildStateIniting && from != AWRichTextBuildStateStable) {
        return NO;
    }
    
    /// ->building
    if (to == AWRichTextBuildStateBuilding && from != AWRichTextBuildStateWillBuilding) {
        return NO;
    }
    
    /// ->built
    if (to == AWRichTextBuildStateBuilt && from != AWRichTextBuildStateBuilding && from != AWRichTextBuildStateWillBuilding) {
        return NO;
    }
    
    return YES;
}

-(void)setUpdateState:(AWRichTextBuildState)updateState{
    assert([NSThread isMainThread]);
    
    if (_updateState == updateState) {
        return;
    }
    AWRichTextBuildState oldState = _updateState;
    
    if (![self checkUpdateStateFrom:oldState to:updateState]) {
        return;
    }
    
    _updateState = updateState;
    
    [self _updateStateChangedFrom:oldState toState:updateState];
}

-(void) _updateStateChangedFrom:(AWRichTextBuildState)fromState toState:(AWRichTextBuildState)toState{
    
    [self _triggerListenersFmBuildState:fromState toBuildState:toState];
    
    switch (toState) {
        case AWRichTextBuildStateWillBuilding:{
            ///使用异步避免无意义的重复调用
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.updateState = AWRichTextBuildStateBuilding;
            });
        }
            break;
        case AWRichTextBuildStateBuilding:{
            [self updateIfNeed];
        }
            break;
        case AWRichTextBuildStateBuilt:{
            ///构建成功后会触发回调，通知观察者richtext已经改变
            [self _triggerListenersUpdated];
            self.updateState = AWRichTextBuildStateStable;
        }
            break;
        case AWRichTextBuildStateStable:{
            /// do nothing
        }
            break;
        default:// AWRichTextBuildStateIniting:
            break;
    }
}

#pragma mark - 回调事件处理
-(BOOL) _isAddedListener:(id<AWRichTextDelegate>)listener{
    if (![listener respondsToSelector:@selector(updatedForAWRichText:)]) {
        return NO;
    }
    
    for (AWRTWeekRefrence *lisValue in _listeners) {
        if ([lisValue isEqual:lisValue]) {
            return YES;
        }
    }
    
    return NO;
}

-(void) _triggerListenersUpdated{
    for (NSInteger i = _listeners.count - 1; i >= 0; i--) {
        AWRTWeekRefrence *lisValue = _listeners[i];
        if (lisValue.ref && [lisValue respondsToSelector:@selector(updatedForAWRichText:)]) {
            [(id)lisValue updatedForAWRichText:self];
        }else{
            [_listeners removeObject:lisValue];
        }
    }
}

-(void) _triggerListenersFmBuildState:(AWRichTextBuildState)fm toBuildState:(AWRichTextBuildState)to{
    for (NSInteger i = _listeners.count - 1; i >= 0; i--) {
        AWRTWeekRefrence *lisValue = _listeners[i];
        if (lisValue.ref && [lisValue respondsToSelector:@selector(awRichText:fmBuildState:toBuildState:)]) {
            [(id)lisValue awRichText:self fmBuildState:fm toBuildState:to];
        }else{
            [_listeners removeObject:lisValue];
        }
    }
}

-(void) addListener:(id<AWRichTextDelegate>)listener{
    if ([self checkIfBuildingState]) {
        NSLog(@"addListener when building");
        return;
    }
    
    if (![listener respondsToSelector:@selector(updatedForAWRichText:)]) {
        return;
    }
    
    if ([self _isAddedListener:listener]) {
        return;
    }
    
    if (!_listeners) {
        _listeners = [[NSMutableArray alloc] init];
    }
    
    [_listeners addObject:[[AWRTWeekRefrence alloc] initWithRef:listener]];
}

-(void) removeListener:(id<AWRichTextDelegate>)listener{
    if ([self checkIfBuildingState]) {
        NSLog(@"removeListener when building");
        return;
    }
    if (![listener respondsToSelector:@selector(updatedForAWRichText:)]) {
        return;
    }
    
    for (NSInteger i = _listeners.count - 1; i >= 0; i--) {
        AWRTWeekRefrence *lisValue = _listeners[i];
        if ([lisValue isEqual:listener]) {
            [_listeners removeObject:lisValue];
            break;
        }
    }
}

#pragma mark - AWRTComponentUpdateDelegate
/// 此方法用于更新AWRichText
/// 当属性改变时调用此方法，AWRichText就会重新计算尺寸，重新绘制。
-(void) setNeedsBuild{
    if ([NSThread isMainThread]) {
        self.updateState = AWRichTextBuildStateWillBuilding;
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updateState = AWRichTextBuildStateWillBuilding;
        });
    }
}

/// setNeedsBuild调用成功后，会调用此方法。
-(void)updateIfNeed{
    if (![self checkIfBuildingState]) {
        return;
    }
    ///异步构建 vs 主线程构建
    ///使用异步构建理论上可以提升一些性能，但可能出现闪屏现象，另外编程复杂度特别高。
    ///推荐使用主线程构建，主线程性能也足以满足大部分需求了。
#if 0
    [self _buildOnBackgroundThreadWithCompletion:^() {
        self.updateState = AWRichTextBuildStateBuilt;
    }];
#else
    [self _build];
#endif
}

///检查状态
-(BOOL) checkIfBuildingState{
    return self.updateState == AWRichTextBuildStateBuilding;
}

-(BOOL) checkIfInitingState{
    return self.updateState == AWRichTextBuildStateIniting;
}

#pragma mark - 构造富文本
-(AWRTComponentPool *) pool{
    if (!_pool) {
        _pool = [[AWRTComponentPool alloc] init];
    }
    return _pool;
}

-(AWRTComponent *) addComponentFromPoolWithType:(AWRTComponentType)type{
    AWRTComponent *comp = [self.pool retainComponentWithType:type];
    if([self addComponent:comp]){
        return comp;
    }
    return nil;
}

-(BOOL) removeAndAddToPoolWithComponent:(AWRTComponent *)comp{
    if ([self removeComponent:comp]) {
        [self.pool releaseComponent:comp];
        return YES;
    }
    return NO;
}

-(BOOL) removeAllComponentsAndAddToPool{
    if (self.components.count <= 0) {
        return YES;
    }
    
    [self enumationComponentsWithBlock:^(AWRTComponent *comp, BOOL *stop) {
        [self removeAndAddToPoolWithComponent:comp];
    } reverse:YES];
    
    self.components = [[NSMutableArray alloc] init];
    
    return YES;
}

-(BOOL) addComponent:(AWRTComponent *)component{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return NO;
    }
    
    if (![component isKindOfClass:[AWRTComponent class]]) {
        return NO;
    }
    
    if ([self.components containsObject:component]) {
        return NO;
    }
    
    [self.components addObject:component];
    
    component.parent = self;
    
    return YES;
}

-(BOOL) addComponents:(NSArray *)components{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return NO;
    }
    if (![components isKindOfClass:[NSArray class]]) {
        return NO;
    }
    for (AWRTComponent *comp in components) {
        [self addComponent:comp];
    }
    return YES;
}

-(BOOL) addComponentsFromRichText:(AWRichText *)richText{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return NO;
    }
    if (![richText isKindOfClass:[AWRichText class]]) {
        return NO;
    }
    if ([self isEqual:richText]) {
        return NO;
    }
    [self addComponents:richText.components];
    return YES;
}

-(BOOL) removeComponent:(AWRTComponent *)component{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return NO;
    }
    if (![component isKindOfClass:[AWRTComponent class]]) {
        return NO;
    }
    if (![self.components containsObject:component]) {
        return NO;
    }
    
    [self.components removeObject:component];
    return YES;
}

-(BOOL) removeAllComponents{
    if (self.components.count <= 0) {
        return YES;
    }
    
    [self enumationComponentsWithBlock:^(AWRTComponent *comp, BOOL *stop) {
        [self removeComponent:comp];
    } reverse:YES];
    
    self.components = [[NSMutableArray alloc] init];
    
    return YES;
}

-(AWRTComponent *)componentWithIndex:(NSInteger) index{
    if (self.components.count > index) {
        return [self.components objectAtIndex:index];
    }
    return nil;
}

-(AWRTComponent *)componentWithTag:(NSString *)tag{
    if (![tag isKindOfClass:[NSString class]] || tag.length == 0) {
        return nil;
    }
    __block AWRTComponent *retComp = nil;
    [self enumationComponentsWithBlock:^(AWRTComponent *comp, BOOL *stop) {
        if ([comp.tag isKindOfClass:[NSString class]] && comp.tag.length > 0 && [tag isEqualToString:comp.tag]) {
            retComp = comp;
            *stop = YES;
        }
    }];
    return retComp;
}

-(NSInteger) componentCount{
    return self.components.count;
}

-(void) enumationComponentsWithBlock:(void(^)(AWRTComponent *comp, BOOL *stop))block reverse:(BOOL)reverse{
    if (self.components.count <= 0) {
        return;
    }
    if (block) {
        BOOL isStop = NO;
        NSInteger startIdx = 0;
        NSInteger endIdx = self.components.count - 1;
        if (reverse) {
            startIdx = self.components.count - 1;
            endIdx = 0;
        }
        for (NSInteger i = startIdx; reverse ? i >= endIdx : i <= endIdx; reverse ? i-- : i++) {
            block(self.components[i], &isStop);
            if (isStop) {
                break;
            }
        }
    }
}

-(void) enumationComponentsWithBlock:(void(^)(AWRTComponent *comp, BOOL *stop))block{
    [self enumationComponentsWithBlock:block reverse:NO];
}

#pragma mark - build富文本
-(BOOL) _build{
    [self doBuild];
    self.updateState = AWRichTextBuildStateBuilt;
    return YES;
}

-(BOOL) doBuild{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    NSArray *components = self.components;
    
    NSInteger locate = 0;
    for (NSInteger i = 0; i < components.count; i++) {
        AWRTComponent *component = components[i];
        NSAttributedString *attrStr = component.attributedString;
        if (attrStr) {
            [attributedString appendAttributedString:attrStr];
            component.range = NSMakeRange(locate, attrStr.length);
            locate += attrStr.length;
        }
    }
    
    if (self.paragraphStyle.lineBreakMode > NSLineBreakByCharWrapping) {
        self.paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    }
    
    [attributedString addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:NSMakeRange(0, attributedString.length)];
    
    /// 文字方向，目前支持left->right方向
    [attributedString addAttribute:NSWritingDirectionAttributeName value:@[@(NSWritingDirectionLeftToRight | NSTextWritingDirectionEmbedding)] range:NSMakeRange(0, attributedString.length)];
    
    _attributedString = attributedString;
    return YES;
}

///异步构造
-(void) _buildOnBackgroundThreadWithCompletion:(void(^)(void))completion{
    assert([self checkIfBuildingState]);
    __weak AWRichText *weakSelf = self;
    [self.buildQueue addOperationWithBlock:^{
        if (!weakSelf) {
            return;
        }
        assert([weakSelf checkIfBuildingState]);
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
        
        NSArray *components = weakSelf.components;
        
        NSInteger locate = 0;
        for (NSInteger i = 0; i < components.count; i++) {
            AWRTComponent *component = components[i];
            NSAttributedString *attrStr = component.attributedString;
            if (attrStr) {
                [attributedString appendAttributedString:attrStr];
                component.range = NSMakeRange(locate, attrStr.length);
                locate += attrStr.length;
            }
        }
        
        //paragraph style
        if (weakSelf.paragraphStyle.lineBreakMode > NSLineBreakByCharWrapping) {
            weakSelf.paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        }
        
        [attributedString addAttribute:NSParagraphStyleAttributeName value:weakSelf.paragraphStyle range:NSMakeRange(0, attributedString.length)];
        
        weakSelf.attributedString = attributedString;
        
        if (weakSelf) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf && completion) {
                    completion();
                }
            });
        }
    }];
}

/// 可直接调用此方法获取attributedString，
/// 因为计算富文本尺寸需要_attributedString不为空，因此想要提前计算RichText的size时，可直接调用此方法。
-(NSAttributedString *)attributedString{
    if (!_attributedString) {
        [self _build];
    }
    return _attributedString;
}

#pragma mark - 属性处理
-(void)setLineSpace:(CGFloat)lineSpace{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return;
    }
    if (_lineSpace == lineSpace) {
        return;
    }
    _lineSpace = lineSpace;
    
    [_paragraphStyle setLineSpacing:lineSpace];
    
    [self setNeedsBuild];
}

-(void)setAlignment:(NSTextAlignment)alignment{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return;
    }
    if (_alignment == alignment) {
        return;
    }
    _alignment = alignment;
    
    [_paragraphStyle setAlignment:alignment];
    
    [self setNeedsBuild];
}

-(void)setLineBreakMode:(NSLineBreakMode)lineBreakMode{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return;
    }
    if (_lineBreakMode == lineBreakMode) {
        return;
    }
    _lineBreakMode = lineBreakMode;
    
    ///此处不赋值给paragraph，后续会使用CoreText处理tranc的情况
    //[_paragraphStyle setLineBreakMode:lineBreakMode];
    
    [self setNeedsBuild];
}

-(void)setParagraphStyle:(NSParagraphStyle *)paragraphStyle{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return;
    }
    if (_paragraphStyle == paragraphStyle) {
        return;
    }
    _paragraphStyle = [paragraphStyle mutableCopy];
    
    [self setNeedsBuild];
}

-(void)setTruncatingTokenComp:(AWRTComponent *)truncatingTokenComp{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return;
    }
    if (_truncatingTokenComp == truncatingTokenComp) {
        return;
    }
    _truncatingTokenComp = truncatingTokenComp;
    
    [self _triggerListenersUpdated];
}

-(void)setAlwaysShowDebugFrames:(BOOL)alwaysShowDebugFrames{
    assert(![self checkIfBuildingState]);
    if ([self checkIfBuildingState]) {
        return;
    }
    if (_alwaysShowDebugFrames == alwaysShowDebugFrames) {
        return;
    }
    _alwaysShowDebugFrames = alwaysShowDebugFrames;
    
    [self _triggerListenersUpdated];
}

#pragma mark - 属性的链式操作
-(AWRichTextPropertyChain) AWLineSpace{
    return ^(id number){
        if ([number respondsToSelector:@selector(floatValue)]) {
            self.lineSpace = [number floatValue];
        }
        return self;
    };
}

-(AWRichTextPropertyChain)AWAlignment{
    return ^(id alignment){
        if ([alignment respondsToSelector:@selector(integerValue)]) {
            self.alignment = [alignment integerValue];
        }
        return self;
    };
}

-(AWRichTextPropertyChain)AWLineBreakMode{
    return ^(id breakMode){
        if ([breakMode respondsToSelector:@selector(integerValue)]) {
            self.lineBreakMode = [breakMode integerValue];
        }
        return self;
    };
}

-(AWRichTextPropertyChain) AWParagraphStyle{
    return ^(id paragraphStyle){
        if ([paragraphStyle isKindOfClass:[NSParagraphStyle class]]) {
            self.paragraphStyle = paragraphStyle;
        }
        return self;
    };
}

-(AWRichTextPropertyChain) AWTruncatingTokenComp{
    return ^(id truncatingTokenComp){
        if ([truncatingTokenComp isKindOfClass:[AWRTComponent class]]) {
            self.truncatingTokenComp = truncatingTokenComp;
        }
        return self;
    };
}

-(AWRichTextPropertyChain) AWAlwaysShowDebugFrames{
    return ^(id alwaysShowDebugFrames){
        if ([alwaysShowDebugFrames respondsToSelector:@selector(boolValue)]) {
            self.alwaysShowDebugFrames = [alwaysShowDebugFrames boolValue];
        }
        return self;
    };
}

#pragma mark - 使用core text绘制富文本
///使用core text绘制富文本
-(void)drawRect:(CGRect)rect label:(UILabel *)label{
    ///building时，应该避免绘制
    if ([self checkIfBuildingState]) {
        return;
    }
    
    [self _drawRect:rect label:label attributedText:_attributedString components:self.components];
}

-(void) removeSubviewsWithLabel:(UILabel *)label{
    for (NSInteger i = label.subviews.count - 1; i >= 0; i--) {
        UIView *view = label.subviews[i];
        [view removeFromSuperview];
    }
}

-(void) _drawRect:(CGRect) rect label:(UILabel *)label attributedText:(NSMutableAttributedString *)attributedText components:(NSArray *)components{
    if (!attributedText) {
        return;
    }
    
    CGRect drawRect = rect;
    
    ///1.CoreGraphics获取上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    ///2.创建CTFrameRef，这里面包含富文本的位置／尺寸／属性等所有信息。
    CTFramesetterRef frameSetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedText);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, drawRect.size.width, drawRect.size.height));
    CTFrameRef ctFrame = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0, attributedText.length), path, NULL);
    
    CGPathRelease(path);
    CFRelease(frameSetterRef);
    
    ///3.获取行数
    CFArrayRef lineArray = CTFrameGetLines(ctFrame);
    NSInteger lineCount = CFArrayGetCount(lineArray);
    
    if (lineCount == 0) {
        CFRelease(ctFrame);
        return;
    }
    
    [self removeSubviewsWithLabel:label];
    
    ///4.准备绘制，保存CGContext状态，令画布变换影响范围缩小
    CGContextSaveGState(context);
    ///5.坐标系变换，防止绘制出倒立图片
    CGContextTranslateCTM(context, 0, drawRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    ///6.判断是否需要截断
    CFRange visibleRange = CTFrameGetVisibleStringRange(ctFrame);
    
    BOOL needTrunc = visibleRange.location + visibleRange.length < attributedText.length;
    __block AWRTComponent *truncatingTokenComp = self.truncatingTokenComp;
    if (needTrunc && !truncatingTokenComp) {
        [self enumationComponentsWithBlock:^(AWRTComponent *comp, BOOL *stop) {
            if ([comp isKindOfClass:[AWRTTextComponent class]]) {
                truncatingTokenComp = [comp copy];
                ((AWRTTextComponent *)truncatingTokenComp).AWText(@"...");
                *stop = YES;
            }
        } reverse:YES];
        
        if (!truncatingTokenComp) {
            truncatingTokenComp = [[AWRTTextComponent alloc] init].AWFont([UIFont systemFontOfSize:14]).AWColor([UIColor blackColor]).AWText(@"...");
        }
    }
    CTLineRef truncedLine = NULL;
    CFRange truncedLineRange = CFRangeMake(0, 0);
    if (needTrunc && truncatingTokenComp) {
        NSAttributedString *tokenAttrStr = truncatingTokenComp.attributedString;
        CTLineRef truncTokenLine = CTLineCreateWithAttributedString((CFAttributedStringRef)tokenAttrStr);
        CTLineTruncationType truncType = kCTLineTruncationEnd;
        if (self.lineBreakMode == NSLineBreakByTruncatingHead) {
            truncType = kCTLineTruncationStart;
        }else if(self.lineBreakMode == NSLineBreakByTruncatingMiddle){
            truncType = kCTLineTruncationMiddle;
        }
        CTLineRef lastLine = CFArrayGetValueAtIndex(lineArray, lineCount - 1);
        CFRange lastLineRange = CTLineGetStringRange(lastLine);
        NSMutableAttributedString *lastLineAttrStr = [attributedText attributedSubstringFromRange:NSMakeRange(lastLineRange.location, lastLineRange.length)].mutableCopy;
        [lastLineAttrStr appendAttributedString:tokenAttrStr];
        
        CTLineRef lastNewLine = CTLineCreateWithAttributedString((CFAttributedStringRef)lastLineAttrStr);
        CGFloat truncWid = CTLineGetTypographicBounds(lastLine, NULL, NULL, NULL);
        
        truncedLine = CTLineCreateTruncatedLine(lastNewLine, truncWid, truncType, truncTokenLine);
        truncedLineRange = CTLineGetStringRange(truncedLine);
        
        CFRelease(truncTokenLine);
        CFRelease(lastNewLine);
    }
    
    ///6.获取每行位置
    CGPoint linePoses[CFArrayGetCount(lineArray)];
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), linePoses);
    
    ///7.重置触摸位置
    NSInteger compIndex = 0;
    [self enumationComponentsWithBlock:^(AWRTComponent *comp, BOOL *stop) {
        comp.touchRects = [[NSMutableArray alloc] init];
    }];
    
    ///8.遍历每一行
    for (NSInteger i = 0; i < lineCount; i++) {
        ///8.1. 取到当前行CTLineRef对象
        CTLineRef oneLine = CFArrayGetValueAtIndex(lineArray, i);
        
        ///8.2. 是否使用truncedLine替代最后一行
        if (truncedLine && i == lineCount - 1) {
            oneLine = truncedLine;
        }
        
        CGFloat oneLineAscent = 0.f, oneLineDescent = 0.f, oneLineLeading = 0.f;
        ///8.3. 取到行相关的位置信息：ascent表示baseline之上的高度，descent表示baseline之下的高度，oneLineLeading表示行距，descent到下一行ascent的距离
        CTLineGetTypographicBounds(oneLine, &oneLineAscent, &oneLineDescent, &oneLineLeading);
        CGFloat lineHei = oneLineAscent + oneLineDescent  + oneLineLeading;
        
        CGPoint linePos = linePoses[i];
        
        CFArrayRef ctRunArray = CTLineGetGlyphRuns(oneLine);
        
        NSInteger ctRunCount = CFArrayGetCount(ctRunArray);
        
        ///8.4. 绘制起始位置
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextSetTextPosition(context, linePos.x, linePos.y);
        
        ///8.5. 绘制每个CTRun
        for (NSInteger j = 0; j < ctRunCount; j++) {
            CTRunRef ctRun = CFArrayGetValueAtIndex(ctRunArray, j);
            
            CFRange ctRunRange = CTRunGetStringRange(ctRun);
            
            NSDictionary *ctRunAttributes = (NSDictionary *)CTRunGetAttributes(ctRun);
            
            ///8.5.1 计算CTRun的尺寸和位置
            CGFloat ctRunAscent = 0.f, ctRunDescent = 0.f, ctRunLeading = 0.f;
            CGFloat ctRunWidth = ceilf(CTRunGetTypographicBounds(ctRun, CFRangeMake(0, 0), &ctRunAscent, &ctRunDescent, &ctRunLeading));
            CGFloat ctRunXOffset = floorf(CTLineGetOffsetForStringIndex(oneLine, ctRunRange.location, NULL));
            CGFloat ctRunHeight = ctRunAscent + ctRunDescent + ctRunLeading;
            CGRect ctRunRect = CGRectMake(linePos.x + ctRunXOffset, linePos.y - ctRunDescent - ctRunLeading, ctRunWidth, ctRunHeight);
            
            CGContextSaveGState(context);
            
            ///8.5.2 绘制背景色
            UIColor *backgroundColor = ctRunAttributes[NSBackgroundColorAttributeName];
            if (backgroundColor) {
                CGRect bgcolorRect = CGRectMake(ctRunRect.origin.x, linePos.y - oneLineDescent - oneLineLeading, ctRunWidth, lineHei);
                CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
                CGContextFillRect(context, bgcolorRect);
            }
            
            ///8.5.3 绘制阴影
            NSShadow *ctRunShadow = ctRunAttributes[NSShadowAttributeName];
            if (ctRunShadow) {
                CGContextSetShadowWithColor(context, ctRunShadow.shadowOffset, ctRunShadow.shadowBlurRadius, [ctRunShadow.shadowColor CGColor]);
            }
            
            ///8.5.4 绘制文字
            CTRunDraw(ctRun, context, CFRangeMake(0, 0));
            
            CGContextRestoreGState(context);
            
            ///8.5.5 保存点击范围
            AWRTComponent *comp = [self componentWithIndex:compIndex];
            [comp.touchRects addObject:[NSValue valueWithCGRect:CGRectMake(ctRunRect.origin.x, drawRect.size.height - ctRunRect.origin.y - ctRunHeight, ctRunWidth, ctRunHeight)]];
            if (ctRunRange.location + ctRunRange.length >= comp.range.location + comp.range.length) {
                compIndex++;
            }
            
            ///8.5.6 绘制debugFrame
            if (self.alwaysShowDebugFrames || comp.debugFrame) {
                UIColor *redColor = [UIColor redColor];
                CGFloat redR, redG, redB, redA;
                [redColor getRed:&redR green:&redG blue:&redB alpha:&redA];
                CGMutablePathRef pathRef = CGPathCreateMutable();
                CGPathAddRect(pathRef, NULL, ctRunRect);
                CGContextAddPath(context, pathRef);
                CGContextSetRGBStrokeColor(context, redR, redG, redB, redA);
                CGContextDrawPath(context, kCGPathStroke);
                CGPathRelease(pathRef);
            }
            
            ///8.5.7 绘制图片 & UIView
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[ctRunAttributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (!delegate) {
                continue;
            }
            AWRTAttachment *attachment = CTRunDelegateGetRefCon(delegate);
            
            id content = attachment.content;
            if ([content isKindOfClass:[UIImage class]]) {
                ///8.5.8 绘制纯图片
                CGRect drawImageRect = ctRunRect;
                CGContextDrawImage(context, drawImageRect, [content CGImage]);
            }else if([content isKindOfClass:[UIView class]]){
                ///8.5.9 绘制UIView
                UIView *attachmentView = content;
                if (attachmentView.superview) {
                    [attachmentView removeFromSuperview];
                }
                [label addSubview:attachmentView];
                
                CGRect contentTargetFrame = CGRectMake(linePos.x + ctRunXOffset, drawRect.size.height - linePos.y - ctRunAscent, ctRunWidth, ctRunHeight);
                if (attachment.scaleType == AWRTAttachmentViewScaleTypeByHeight) {
                    CGFloat scaleRate = contentTargetFrame.size.height / attachmentView.frame.size.height;
                    attachmentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleRate, scaleRate);
                }else if(attachment.scaleType == AWRTAttachmentViewScaleTypeByWidth){
                    CGFloat scaleRate = contentTargetFrame.size.width / attachmentView.frame.size.width;
                    attachmentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleRate, scaleRate);
                }
                attachmentView.frame = contentTargetFrame;
            }else{
                NSLog(@"[Error] unsupported attachment content(%@)", content);
            }
        }
    }
    CGContextRestoreGState(context);
    
    ///9.释放资源
    if (truncedLine) {
        CFRelease(truncedLine);
    }
    CFRelease(ctFrame);
}

#pragma mark sizeThat
-(CGSize)sizeThatFits:(CGSize)sizex label:(UILabel *)label{
    CGSize rtSize = sizex;
    NSAttributedString *attributedText = _attributedString;
    
    if (!attributedText) {
        return rtSize;
    }
    
    if (rtSize.width > 0 && rtSize.height > 0) {
        return rtSize;
    }
    
    if (rtSize.width <= 0) {
        rtSize.width = AWRichTextMaxValue;
    }
    
    if (rtSize.height <= 0) {
        rtSize.height = AWRichTextMaxValue;
    }
    
    CTFramesetterRef frameSetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedText);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, rtSize.width, rtSize.height));
    CTFrameRef ctFrame = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0, attributedText.length), path, NULL);
    
    CGPathRelease(path);
    CFRelease(frameSetterRef);
    
    CFArrayRef lineArray = CTFrameGetLines(ctFrame);
    
    NSInteger lineCount = CFArrayGetCount(lineArray);
    
    if (lineCount == 0) {
        CFRelease(ctFrame);
        return rtSize;
    }
    
    CGPoint linePoses[lineCount];
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), linePoses);
    
    CGFloat maxX = AWRichTextMinValue;
    CGFloat maxY = AWRichTextMinValue;
    
    for (NSInteger i = 0; i < lineCount; i++) {
        CTLineRef oneLine = CFArrayGetValueAtIndex(lineArray, i);
        CGFloat oneLineAscent, oneLineDescent, oneLineLeading;
        CGFloat lineWid = CTLineGetTypographicBounds(oneLine, &oneLineAscent, &oneLineDescent, &oneLineLeading);
        
        CGPoint linePos = linePoses[i];
        
        CGFloat lineMaxX = [self ceilValue: linePos.x + lineWid];
        if (lineMaxX > maxX) {
            maxX = lineMaxX;
        }
        
        CGFloat lineMaxY = [self ceilValue: rtSize.height - linePos.y + oneLineDescent + oneLineLeading];
        if (lineMaxY > maxY) {
            maxY = lineMaxY;
        }
        
        CFArrayRef ctRunArray = CTLineGetGlyphRuns(oneLine);
        for (NSInteger j = 0; j < CFArrayGetCount(ctRunArray); j++) {
            CTRunRef ctRun = CFArrayGetValueAtIndex(ctRunArray, j);
            CGFloat ctRunAscent, ctRunDescent, ctRunLeading;
            CGFloat ctRunWidth = CTRunGetTypographicBounds(ctRun, CFRangeMake(0, 0), &ctRunAscent, &ctRunDescent, &ctRunLeading);
            CGFloat ctRunXOffset = CTLineGetOffsetForStringIndex(oneLine, CTRunGetStringRange(ctRun).location, NULL);
            CGFloat ctRunHeight = ctRunAscent + ctRunDescent + ctRunLeading;
            
            CGRect runAttachmentRect = CGRectMake(linePos.x + ctRunXOffset, rtSize.height - linePos.y - ctRunAscent, ctRunWidth, ctRunHeight);
            
            CGFloat runAttachRctMaxX = [self ceilValue: runAttachmentRect.origin.x + runAttachmentRect.size.width];
            if (runAttachRctMaxX > maxX) {
                maxX = runAttachRctMaxX;
            }
            
            CGFloat runAttachRctMaxY = [self ceilValue: rtSize.height - linePos.y + ctRunDescent];
            if (runAttachRctMaxY > maxY) {
                maxY = runAttachRctMaxY;
            }
        }
    }
    
    CFRelease(ctFrame);
    
    return CGSizeMake(maxX, maxY);
}

-(CGSize) intrinsicContentSizeWithPreferMaxWidth:(CGFloat) maxWidth label:(UILabel *)label{
    return [self sizeThatFits:CGSizeMake(maxWidth, 0) label:label];
}

#pragma mark - 浮点数近似处理
-(CGFloat) ceilValue:(CGFloat)value{
    return ceilf(value);
}

#pragma mark - coding
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self) {
        self.lineSpace = [aDecoder decodeFloatForKey:AWRTLineSpace];
        self.alignment = [aDecoder decodeIntegerForKey:AWRTAlignment];
        self.lineBreakMode = [aDecoder decodeIntegerForKey:AWRTLineBreakMode];
        self.paragraphStyle = [aDecoder decodeObjectForKey:AWRTParagraphStyle];
        self.truncatingTokenComp = [aDecoder decodeObjectForKey:AWRTTruncatingTokenComp];
        self.components = [aDecoder decodeObjectForKey:AWRTComponents];
        
        _buildQueue = [[NSOperationQueue alloc] init];
        _buildQueue.maxConcurrentOperationCount = 1;
        _buildQueue.qualityOfService = NSQualityOfServiceUtility;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeFloat:self.lineSpace forKey:AWRTLineSpace];
    [aCoder encodeInteger:self.alignment forKey:AWRTAlignment];
    [aCoder encodeInteger:self.lineBreakMode forKey:AWRTLineBreakMode];
    [aCoder encodeObject:self.paragraphStyle forKey:AWRTParagraphStyle];
    [aCoder encodeObject:self.truncatingTokenComp forKey:AWRTTruncatingTokenComp];
    [aCoder encodeObject:self.components forKey:AWRTComponents];
}

#pragma mark - copy
-(id)copyWithZone:(NSZone *)zone{
    AWRichText *newRichText = [[AWRichText alloc] init]
    .AWLineSpace(@(self.lineSpace))
    .AWAlignment(@(self.alignment))
    .AWLineBreakMode(@(self.lineBreakMode))
    .AWParagraphStyle([self.paragraphStyle copyWithZone:zone])
    .AWTruncatingTokenComp([self.truncatingTokenComp copyWithZone:zone]);
    for (AWRTComponent *comp in self.components) {
        [newRichText addComponent:[comp copyWithZone:zone]];
    }
    return newRichText;
}

#pragma mark - gif animating
-(void) letAnimStartOrStop:(BOOL) isStart{
    [self enumationComponentsWithBlock:^(AWRTComponent *comp, BOOL *stop) {
        if ([comp isKindOfClass:[AWRTViewComponent class]]) {
            AWRTViewComponent *viewComp = (id)comp;
            if ([viewComp.content isKindOfClass:[UIImageView class]]) {
                UIImageView *imgView = viewComp.content;
                if (imgView.animationImages.count > 1 && imgView.animationDuration > 0) {
                    if (imgView.isAnimating) {
                        [imgView stopAnimating];
                    }
                    if (isStart) {
                        [imgView startAnimating];
                    }
                }
            }
        }
    }];
}
@end
