/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTTextComponent.h"

#define AWRTTextCompShadowColor @"AWRTTextCompShadowColor"
#define AWRTTextCompShadowOffset @"AWRTTextCompShadowOffset"
#define AWRTTextCompShadowBlurRadius @"AWRTTextCompShadowBlurRadius"
#define AWRTTextCompStrokeColor @"AWRTTextCompStrokeColor"
#define AWRTTextCompStrokeWidth @"AWRTTextCompStrokeWidth"
#define AWRTTextCompBgColor @"AWRTTextCompBgColor"
#define AWRTTextCompColor @"AWRTTextCompColor"
#define AWRTTextCompText @"AWRTTextCompText"
#define AWRTTextCompLeftSeperateString @"AWRTTextCompLeftSeperateString"
#define AWRTTextCompRightSeperateString @"AWRTTextCompRightSeperateString"
#define AWRTTextCompSeperateStringColor @"AWRTTextCompSeperateStringColor"
#define AWRTTextCompUnderlineColor @"AWRTTextCompUnderlineColor"
#define AWRTTextCompUnderlineStyle @"AWRTTextCompUnderlineStyle"

#define AWRTTextCompLigature @"AWRTTextCompLigature"
#define AWRTTextCompKern @"AWRTTextCompKern"
#define AWRTTextCompStrikethroughStyle @"AWRTTextCompStrikethroughStyle"
#define AWRTTextCompStrikethroughColor @"AWRTTextCompStrikethroughColor"
#define AWRTTextCompLinkUrl @"AWRTTextCompLinkUrl"
#define AWRTTextCompBaselineOffset @"AWRTTextCompBaselineOffset"

@interface AWRTTextComponent()
@property (nonatomic, copy) NSString *showText;
@end

@implementation AWRTTextComponent

#pragma mark - 生命周期
-(void)onInit{
    [super onInit];
    self.backgroundColor = [UIColor clearColor];
    self.shadowOffset = CGSizeMake(1, 1);
    self.font = [UIFont systemFontOfSize:14];
}

#pragma mark - encode
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        self.shadowColor = [aDecoder decodeObjectForKey:AWRTTextCompShadowColor];
        self.shadowOffset = [[aDecoder decodeObjectForKey:AWRTTextCompShadowOffset] CGSizeValue];
        self.shadowBlurRadius = [aDecoder decodeFloatForKey:AWRTTextCompShadowBlurRadius];
        
        self.strokeColor = [aDecoder decodeObjectForKey:AWRTTextCompStrokeColor];
        self.strokeWidth = [aDecoder decodeFloatForKey:AWRTTextCompStrokeWidth];
        
        self.backgroundColor = [aDecoder decodeObjectForKey:AWRTTextCompBgColor];
        self.color = [aDecoder decodeObjectForKey:AWRTTextCompColor];
        
        self.text = [aDecoder decodeObjectForKey:AWRTTextCompText];
        self.leftSeperateString = [aDecoder decodeObjectForKey:AWRTTextCompLeftSeperateString];
        self.rightSeperateString = [aDecoder decodeObjectForKey:AWRTTextCompRightSeperateString];
        self.seperateStringColor = [aDecoder decodeObjectForKey:AWRTTextCompSeperateStringColor];
        
        self.underlineColor = [aDecoder decodeObjectForKey:AWRTTextCompUnderlineColor];
        self.underlineStyle = [aDecoder decodeIntegerForKey:AWRTTextCompUnderlineStyle];
        
        self.ligature = [aDecoder decodeIntegerForKey:AWRTTextCompLigature];
        self.kern = [aDecoder decodeFloatForKey:AWRTTextCompKern];
        self.strikethroughStyle = [aDecoder decodeIntegerForKey:AWRTTextCompStrikethroughStyle];
        self.strikethroughColor = [aDecoder decodeObjectForKey:AWRTTextCompStrikethroughColor];
        self.linkUrl = [aDecoder decodeObjectForKey:AWRTTextCompLinkUrl];
        self.baselineOffset = [aDecoder decodeFloatForKey:AWRTTextCompBaselineOffset];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.shadowColor forKey:AWRTTextCompShadowColor];
    [aCoder encodeObject:[NSValue valueWithCGSize:self.shadowOffset] forKey:AWRTTextCompShadowOffset];
    [aCoder encodeFloat:self.shadowBlurRadius forKey:AWRTTextCompShadowBlurRadius];
    
    [aCoder encodeObject:self.strokeColor forKey:AWRTTextCompStrokeColor];
    [aCoder encodeFloat:self.strokeWidth forKey:AWRTTextCompStrokeWidth];
    
    [aCoder encodeObject:self.color forKey:AWRTTextCompColor];
    [aCoder encodeObject:self.backgroundColor forKey:AWRTTextCompBgColor];
    
    [aCoder encodeObject:self.text forKey:AWRTTextCompText];
    [aCoder encodeObject:self.leftSeperateString forKey:AWRTTextCompLeftSeperateString];
    [aCoder encodeObject:self.rightSeperateString forKey:AWRTTextCompRightSeperateString];
    [aCoder encodeObject:self.seperateStringColor forKey:AWRTTextCompSeperateStringColor];
    
    [aCoder encodeObject:self.underlineColor forKey:AWRTTextCompUnderlineColor];
    [aCoder encodeInteger:self.underlineStyle forKey:AWRTTextCompUnderlineStyle];
    
    [aCoder encodeInteger:self.ligature forKey:AWRTTextCompLigature];
    [aCoder encodeFloat:self.kern forKey:AWRTTextCompKern];
    [aCoder encodeInteger:self.strikethroughStyle forKey:AWRTTextCompStrikethroughStyle];
    [aCoder encodeObject:self.strikethroughColor forKey:AWRTTextCompStrikethroughColor];
    [aCoder encodeObject:self.linkUrl forKey:AWRTTextCompLinkUrl];
    [aCoder encodeFloat:self.baselineOffset forKey:AWRTTextCompBaselineOffset];
}

#pragma mark - copy
-(id)copyWithZone:(NSZone *)zone{
    return ((AWRTTextComponent *)[super copyWithZone:zone])
    .AWShadowColor([self.shadowColor copyWithZone:zone])
    .AWShadowOffset([NSValue valueWithCGSize:self.shadowOffset])
    .AWShadowBlurRadius(@(self.shadowBlurRadius))
    .AWStrokeColor([self.strokeColor copyWithZone:zone])
    .AWStrokeWidth(@(self.strokeWidth))
    .AWColor([self.color copyWithZone:zone])
    .AWBackgroundColor([self.backgroundColor copyWithZone:zone])
    .AWText([self.text copyWithZone:zone])
    .AWLeftSeperateString([self.leftSeperateString copyWithZone:zone])
    .AWRightSeperateString([self.rightSeperateString copyWithZone:zone])
    .AWSeperateStringColor([self.seperateStringColor copyWithZone:zone])
    .AWUnderlineStyle(@(self.underlineStyle))
    .AWUnderlineColor([self.underlineColor copyWithZone:zone])
    .AWLigature(@(self.ligature))
    .AWKern(@(self.kern))
    .AWStrikethroughStyle(@(self.strikethroughStyle))
    .AWStrikethroughColor([self.strikethroughColor copyWithZone:zone])
    .AWLinkUrl([self.linkUrl copyWithZone:zone])
    .AWBaselineOffset(@(self.baselineOffset))
    ;
}

#pragma mark - override

-(NSAttributedString *)build{
    if (![self.text isKindOfClass:[NSString class]] || self.text.length == 0) {
        NSLog(@" build failed for self.text is invalid %@", @"");
        return nil;
    }
    
    ///使用showText
    self.showText = self.text;
    
    ///字体
    UIFont *font = self.font;
    
    NSMutableDictionary *defaultDict = [NSMutableDictionary dictionary];
    assert(font != nil);
    defaultDict[NSFontAttributeName] = font;
    
    ///文字颜色
    if (!self.color) {
        self.color = [UIColor blackColor];
    }
    defaultDict[NSForegroundColorAttributeName] = self.color;
    
    ///背景色
    if (self.backgroundColor) {
        defaultDict[NSBackgroundColorAttributeName] = self.backgroundColor;
    }
    
    ///shadow
    NSShadow *strShadow = nil;
    if (self.shadowBlurRadius != 0 && self.shadowColor) {
        strShadow = [[NSShadow alloc] init];
        strShadow.shadowBlurRadius = self.shadowBlurRadius;
        strShadow.shadowColor = self.shadowColor;
        strShadow.shadowOffset = self.shadowOffset;
        defaultDict[NSShadowAttributeName] = strShadow;
    }
    
    ///stroke
    if (self.strokeColor && self.strokeWidth != 0) {
        defaultDict[NSStrokeColorAttributeName] = self.strokeColor;
        defaultDict[NSStrokeWidthAttributeName] = @(self.strokeWidth);
    }
    
    ///underline
    if ([self.underlineColor isKindOfClass:[UIColor class]] && self.underlineStyle > 0) {
        defaultDict[NSUnderlineColorAttributeName] = self.underlineColor;
        defaultDict[NSUnderlineStyleAttributeName] = @(self.underlineStyle);
    }
    
    ///ligature
    if (self.ligature > 0) {
        defaultDict[NSLigatureAttributeName] = @(self.ligature);
    }
    
    ///kern
    if (self.kern > 0) {
        defaultDict[NSKernAttributeName] = @(self.kern);
    }
    
    ///strike
    if (self.strikethroughColor && self.strikethroughStyle > 0) {
        defaultDict[NSStrikethroughColorAttributeName] = self.strikethroughColor;
        defaultDict[NSStrikethroughStyleAttributeName] = @(self.strikethroughStyle);
    }
    
    ///linkUrl
    if (self.linkUrl) {
        defaultDict[NSLinkAttributeName] = self.linkUrl;
    }
    
    ///baseline offset
    if (self.baselineOffset) {
        defaultDict[NSBaselineOffsetAttributeName] = @(self.baselineOffset);
    }
    
    NSMutableAttributedString *textAttrString = [[NSMutableAttributedString alloc] initWithString:self.showText
                                                                         attributes:defaultDict];
    
    ///分隔符 left
    NSMutableAttributedString *mutableAttrString = nil;
    NSMutableDictionary *sepAttributes = nil;
    
    if (self.leftSeperateString || self.rightSeperateString) {
        mutableAttrString = [NSMutableAttributedString new];
        
        sepAttributes = [defaultDict mutableCopy];
        if (self.seperateStringColor) {
            sepAttributes[NSForegroundColorAttributeName] = self.seperateStringColor;
        }
    }
    
    if (self.leftSeperateString) {
        NSAttributedString *leftSepAttrStr = [[NSAttributedString alloc] initWithString:self.leftSeperateString
                                                                             attributes:sepAttributes];
        
        [mutableAttrString appendAttributedString:leftSepAttrStr];
    }
    
    ///分隔符 right
    if (self.rightSeperateString) {
        NSAttributedString *rightSepAttrStr = [[NSAttributedString alloc] initWithString:self.rightSeperateString
                                                                              attributes:sepAttributes];
        [mutableAttrString appendAttributedString:textAttrString];
        [mutableAttrString appendAttributedString:rightSepAttrStr];
    }else{
        [mutableAttrString appendAttributedString:textAttrString];
    }
    
    NSMutableAttributedString *retAttributedString = mutableAttrString ? mutableAttrString : textAttrString;
    
    ///防止属性类似的相邻component被解析成同一个CTRun影响触摸事件
    NSMutableAttributedString *markAttributedString = [[NSMutableAttributedString alloc] initWithString:@"\ufffc"
                                                                                             attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:0.1]}];
    [retAttributedString appendAttributedString:markAttributedString];
    
    return retAttributedString;
}

-(NSSet *)editableAttributes{
    NSMutableSet *set = [NSMutableSet setWithArray:@[@"shadowBlurRadius", @"shadowColor", @"shadowOffset", @"strokeColor", @"strokeWidth", @"color", @"backgroundColor", @"text", @"leftSeperateString", @"rightSeperateString", @"seperateStringColor", @"font", @"paddingLeft", @"paddingRight", @"underlineColor", @"underlineStyle", @"ligature", @"kern", @"strikethroughStyle", @"strikethroughColor", @"linkUrl", @"baselineOffset"]];
    [set unionSet:[super editableAttributes]];
    return set;
}

#pragma mark - attributes

-(void)setBackgroundColor:(UIColor *)backgroundColor{
    if ([_backgroundColor isEqual:backgroundColor]) {
        return;
    }
    _backgroundColor = backgroundColor;
}

-(void)setColor:(UIColor *)color{
    if ([_color isEqual:color]) {
        return;
    }
    _color = color;
}

-(void)setText:(NSString *)text{
    if ([_text isEqualToString:text]) {
        return;
    }
    _text = text;
}

-(void)setLeftSeperateString:(NSString *)leftSeperateString{
    if ([_leftSeperateString isEqualToString:leftSeperateString]) {
        return;
    }
    _leftSeperateString = leftSeperateString;
}

-(void)setRightSeperateString:(NSString *)rightSeperateString{
    if ([_rightSeperateString isEqualToString:rightSeperateString]) {
        return;
    }
    _rightSeperateString = rightSeperateString;
}

-(void)setSeperateStringColor:(UIColor *)seperateStringColor{
    if ([_seperateStringColor isEqual:seperateStringColor]) {
        return;
    }
    _seperateStringColor = seperateStringColor;
}

-(void)setShadowBlurRadius:(CGFloat)shadowBlurRadius{
    if (_shadowBlurRadius == shadowBlurRadius) {
        return;
    }
    _shadowBlurRadius = shadowBlurRadius;
}

-(void)setShadowColor:(UIColor *)shadowColor{
    if ([_shadowColor isEqual:shadowColor]) {
        return;
    }
    _shadowColor = shadowColor;
}

-(void)setShadowOffset:(CGSize )shadowOffset{
    if (CGSizeEqualToSize(shadowOffset, _shadowOffset)) {
        return;
    }
    _shadowOffset = shadowOffset;
}

-(void)setStrokeColor:(UIColor *)strokeColor{
    if ([_strokeColor isEqual:strokeColor]) {
        return;
    }
    _strokeColor = strokeColor;
}

-(void)setStrokeWidth:(CGFloat)strokeWidth{
    if (_strokeWidth == strokeWidth) {
        return;
    }
    _strokeWidth = strokeWidth;
}

-(void)setUnderlineColor:(UIColor *)underlineColor{
    if ([_underlineColor isEqual:underlineColor]) {
        return;
    }
    _underlineColor = underlineColor;
}

-(void)setUnderlineStyle:(NSUnderlineStyle)underlineStyle{
    if (_underlineStyle == underlineStyle) {
        return;
    }
    _underlineStyle = underlineStyle;
}

-(void)setLigature:(NSInteger)ligature{
    if (_ligature == ligature) {
        return;
    }
    _ligature = ligature;
}

-(void)setKern:(CGFloat)kern{
    if (_kern == kern) {
        return;
    }
    _kern = kern;
}

-(void)setStrikethroughStyle:(NSInteger)strikethroughStyle{
    if (_strikethroughStyle == strikethroughStyle) {
        return;
    }
    _strikethroughStyle = strikethroughStyle;
}

-(void)setStrikethroughColor:(UIColor *)strikethroughColor{
    if ([_strikethroughColor isEqual:strikethroughColor]) {
        return;
    }
    _strikethroughColor = strikethroughColor;
}

-(void)setLinkUrl:(NSString *)linkUrl{
    if ([_linkUrl isEqualToString:linkUrl]) {
        return;
    }
    _linkUrl = linkUrl;
}

-(void)setBaselineOffset:(CGFloat)baselineOffset{
    if (_baselineOffset == baselineOffset) {
        return;
    }
    _baselineOffset = baselineOffset;
}

#pragma mark chain funs
-(AWTextComponentChain) AWShadowBlurRadius{
    return ^(id shadowBlurRadius){
        if ([shadowBlurRadius respondsToSelector:@selector(floatValue)]) {
            self.shadowBlurRadius = [shadowBlurRadius floatValue];
        }
        return self;
    };
}

-(AWTextComponentChain) AWShadowColor{
    return ^(id shadowColor){
        if ([shadowColor isKindOfClass:[UIColor class]]) {
            self.shadowColor = shadowColor;
        }
        return self;
    };
}

-(AWTextComponentChain) AWShadowOffset{
    return ^(id shadowOffset){
        if ([shadowOffset respondsToSelector:@selector(CGSizeValue)]) {
            self.shadowOffset = [shadowOffset CGSizeValue];
        }
        return self;
    };
}

-(AWTextComponentChain) AWStrokeColor{
    return ^(id strokeColor){
        if ([strokeColor isKindOfClass:[UIColor class]]) {
            self.strokeColor = strokeColor;
        }
        return self;
    };
}

-(AWTextComponentChain) AWStrokeWidth{
    return ^(id strokeWidth){
        if ([strokeWidth respondsToSelector:@selector(floatValue)]) {
            self.strokeWidth = [strokeWidth floatValue];
        }
        return self;
    };
}

-(AWTextComponentChain) AWColor{
    return ^(id color){
        if ([color isKindOfClass:[UIColor class]]) {
            self.color = color;
        }
        return self;
    };
}

-(AWTextComponentChain) AWBackgroundColor{
    return ^(id color){
        if ([color isKindOfClass:[UIColor class]]) {
            self.backgroundColor = color;
        }
        return self;
    };
}

-(AWTextComponentChain) AWText{
    return ^(id text){
        if ([text isKindOfClass:[NSString class]]) {
            self.text = text;
        }
        return self;
    };
}

-(AWTextComponentChain) AWLeftSeperateString{
    return ^(id leftSeperateString){
        if ([leftSeperateString isKindOfClass:[NSString class]]) {
            self.leftSeperateString = leftSeperateString;
        }
        return self;
    };
}

-(AWTextComponentChain) AWRightSeperateString{
    return ^(id rightSeperateString){
        if ([rightSeperateString isKindOfClass:[NSString class]]) {
            self.rightSeperateString = rightSeperateString;
        }
        return self;
    };
}

-(AWTextComponentChain) AWSeperateStringColor{
    return ^(id seperateStringColor){
        if ([seperateStringColor isKindOfClass:[UIColor class]]) {
            self.seperateStringColor = seperateStringColor;
        }
        return self;
    };
}

-(AWTextComponentChain) AWUnderlineColor{
    return ^(id color){
        if ([color isKindOfClass:[UIColor class]]) {
            self.underlineColor = color;
        }
        return self;
    };
}

-(AWTextComponentChain) AWUnderlineStyle{
    return ^(id style){
        if ([style respondsToSelector:@selector(integerValue)]) {
            self.underlineStyle = [style integerValue];
        }
        return self;
    };
}

-(AWTextComponentChain)AWPaddingLeft{
    return (AWTextComponentChain) [super AWPaddingLeft];
}

-(AWTextComponentChain)AWPaddingRight{
    return (AWTextComponentChain) [super AWPaddingRight];
}

-(AWTextComponentChain)AWFont{
    return (AWTextComponentChain)[super AWFont];
}

-(AWTextComponentChain)AWDebugFrame{
    return (AWTextComponentChain)[super AWDebugFrame];
}

-(AWTextComponentChain) AWLigature{
    return ^(id ligature){
        if ([ligature respondsToSelector:@selector(integerValue)]) {
            self.ligature = [ligature integerValue];
        }
        return self;
    };
}

-(AWTextComponentChain) AWKern{
    return ^(id kern){
        if ([kern respondsToSelector:@selector(floatValue)]) {
            self.kern = [kern integerValue];
        }
        return self;
    };
}

-(AWTextComponentChain) AWStrikethroughStyle{
    return ^(id strikethroughStyle){
        if ([strikethroughStyle respondsToSelector:@selector(integerValue)]) {
            self.strikethroughStyle = [strikethroughStyle integerValue];
        }
        return self;
    };
}

-(AWTextComponentChain) AWStrikethroughColor{
    return ^(id strikethroughColor){
        if ([strikethroughColor isKindOfClass:[UIColor class]]) {
            self.strikethroughColor = strikethroughColor;
        }
        return self;
    };
}

-(AWTextComponentChain) AWLinkUrl{
    return ^(id linkUrl){
        if ([linkUrl isKindOfClass:[NSString class]]) {
            self.linkUrl = linkUrl;
        }
        return self;
    };
}

-(AWTextComponentChain) AWBaselineOffset{
    return ^(id baselineOffset){
        if ([baselineOffset respondsToSelector:@selector(floatValue)]) {
            self.baselineOffset = [baselineOffset floatValue];
        }
        return self;
    };
}

@end
