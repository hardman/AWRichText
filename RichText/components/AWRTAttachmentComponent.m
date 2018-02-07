/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTAttachmentComponent.h"

#define AWRTImageAttachBounds @"AWRTImageAttachBounds"
#define AWRTImageAttachAlignment @"AWRTImageAttachAlignment"
#define AWRTImageAttachFontAscent @"AWRTImageAttachFontAscent"
#define AWRTImageAttachFontDescent @"AWRTImageAttachFontDescent"
#define AWRTImageAttachDebugFrame @"AWRTImageAttachDebugFrame"
#define AWRTImageAttachContent @"AWRTImageAttachContent"
#define AWRTImageAttachScaleType @"AWRTImageAttachScaleType"

#define AWRTAttachmentCompAlignment @"AWRTAttachmentCompAlignment"
#define AWRTAttachmentCompBoundsDepend @"AWRTAttachmentCompBoundsDepend"
#define AWRTAttachmentCompOffset @"AWRTAttachmentCompOffset"
#define AWRTAttachmentCompBounds @"AWRTAttachmentCompBounds"

@interface AWRTAttachment()
@property (nonatomic, unsafe_unretained) CGFloat attachmentAscent;
@property (nonatomic, unsafe_unretained) CGFloat attachmentDescent;
@end

@implementation AWRTAttachment

-(void) calcAescentDesccent{
    CGFloat ascent = self.bounds.size.height;
    CGFloat descent = 0;
    switch (self.alignment) {
        case AWRTAttachmentAlignTop:
            ascent = self.fontAscent;
            descent = self.bounds.size.height - self.fontAscent;
            ///因为descent和ascent都是无符号的，所以文字排版baseline上下必须要都要有内容。
            ///descent小于0，说明attachment.bounds.size.height的值太小了，无法满足绘制。
            ///此种情况下，尽可能向上，将descent置为0，ascent为bounds.size.height;
            ///下同
            if (descent < 0) {
                descent = 0;
                ascent = self.bounds.size.height;
//                NSLog(@"[warning] attachment(align top) bounds.size.height is too small, please select a bigger value");
            }
            break;
        case AWRTAttachmentAlignBottom:
            ascent = self.bounds.size.height + self.fontDescent;
            descent = self.fontDescent;
            if (ascent < 0) {
                ascent = 0;
                descent = self.bounds.size.height;
//                NSLog(@"[warning] attachment(align btm) bounds.size.height is too small, please select a bigger value");
            }
            break;
        case AWRTAttachmentAlignCenter:{
            CGFloat tmp = ((self.fontAscent - self.fontDescent) / 2 + self.fontDescent);
            CGFloat halfhei = self.bounds.size.height / 2;
            ascent =  tmp + halfhei;
            descent = tmp - halfhei;
            if (descent > 0) {
                descent = 0;
                ascent = self.bounds.size.height;
//                NSLog(@"[warning] attachment bounds.size.height(align center) is too small, please select a bigger value");
            }
        }
            break;
    }
    
    self.attachmentAscent = ascent;
    self.attachmentDescent = fabs(descent);
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.bounds = [[aDecoder decodeObjectForKey:AWRTImageAttachBounds] CGRectValue];
        self.alignment = [aDecoder decodeIntegerForKey:AWRTImageAttachAlignment];
        self.fontAscent = [aDecoder decodeFloatForKey:AWRTImageAttachFontAscent];
        self.fontDescent = [aDecoder decodeFloatForKey:AWRTImageAttachFontDescent];
        self.debugFrame = [aDecoder decodeBoolForKey:AWRTImageAttachDebugFrame];
        self.content = [aDecoder decodeObjectForKey:AWRTImageAttachContent];
        self.scaleType = [aDecoder decodeIntegerForKey:AWRTImageAttachScaleType];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:[NSValue valueWithCGRect:self.bounds] forKey:AWRTImageAttachBounds];
    [aCoder encodeInteger:self.alignment forKey:AWRTImageAttachAlignment];
    [aCoder encodeFloat:self.fontAscent forKey:AWRTImageAttachFontAscent];
    [aCoder encodeFloat:self.fontDescent forKey:AWRTImageAttachFontDescent];
    [aCoder encodeBool:self.debugFrame forKey:AWRTImageAttachDebugFrame];
    [aCoder encodeObject:self.content forKey:AWRTImageAttachContent];
    [aCoder encodeInteger:self.scaleType forKey:AWRTImageAttachScaleType];
}

-(id)copyWithZone:(NSZone *)zone{
    AWRTAttachment *newAttachment = [[AWRTAttachment alloc] init];
    newAttachment.bounds = self.bounds;
    newAttachment.alignment = self.alignment;
    newAttachment.fontAscent = self.fontAscent;
    newAttachment.fontDescent = self.fontDescent;
    newAttachment.debugFrame = self.debugFrame;
    newAttachment.scaleType = self.scaleType;
    return newAttachment;
}

@end

#pragma mark ct run delegate funcs
static CGFloat AWRTImageCTRunAscentCallback(void *ref){
    AWRTAttachment *attachment = (__bridge AWRTAttachment *)ref;
    return attachment.attachmentAscent;
}

static CGFloat AWRTImageCTRunDescentCallback(void *ref){
    AWRTAttachment *attachment = (__bridge AWRTAttachment *)ref;
    return attachment.attachmentDescent;
}

static CGFloat AWRTImageCTRunWidthCallback(void *ref){
    AWRTAttachment *attachment = (__bridge AWRTAttachment *)ref;
    return attachment.bounds.size.width;
}

static void AWDeallocCallback(void *ref) {
    AWRTAttachment *self = (__bridge_transfer AWRTAttachment *)(ref);
    self = nil; // release
}

@interface AWRTAttachmentComponent()
@property (nonatomic, strong) AWRTAttachment *attachment;
@end

@implementation AWRTAttachmentComponent

-(AWRTAttachmentComponentChain)AWContent{
    return ^(id content){
        self.content = content;
        return self;
    };
}

-(AWRTAttachmentComponentChain)AWScaleType{
    return ^(id scaleType){
        if ([scaleType respondsToSelector:@selector(integerValue)]) {
            self.scaleType = [scaleType integerValue];
        }
        return self;
    };
}

-(AWRTAttachmentComponentChain)AWContentSizeScale{
    return ^(id contentSizeScale){
        self.contentSizeScale = [contentSizeScale floatValue];
        return self;
    };
}

-(AWRTAttachmentComponentChain)AWBounds{
    return ^(id bounds){
        if ([bounds respondsToSelector:@selector(CGRectValue)]) {
            self.bounds = [bounds CGRectValue];
        }
        return self;
    };
}

-(AWRTAttachmentComponentChain)AWBoundsDepend{
    return ^(id boundsDepend){
        if ([boundsDepend respondsToSelector:@selector(integerValue)]) {
            self.boundsDepend = [boundsDepend integerValue];
        }
        return self;
    };
}

-(AWRTAttachmentComponentChain)AWOffsets{
    return ^(id off){
        if ([off respondsToSelector:@selector(CGPointValue)]) {
            self.offset = [off CGPointValue];
        }
        return self;
    };
}

-(AWRTAttachmentComponentChain)AWAlignment{
    return ^(id alignment){
        if ([alignment respondsToSelector:@selector(integerValue)]) {
            self.alignment = [alignment integerValue];
        }
        return self;
    };
}

-(AWRTAttachmentComponentChain)AWPaddingLeft{
    return (AWRTAttachmentComponentChain) [super AWPaddingLeft];
}

-(AWRTAttachmentComponentChain)AWPaddingRight{
    return (AWRTAttachmentComponentChain) [super AWPaddingRight];
}

-(AWRTAttachmentComponentChain)AWFont{
    return (AWRTAttachmentComponentChain)[super AWFont];
}

-(AWRTAttachmentComponentChain)AWDebugFrame{
    return (AWRTAttachmentComponentChain)[super AWDebugFrame];
}

-(NSSet *)editableAttributes{
    NSMutableSet *set = [NSMutableSet setWithArray:@[@"bounds", @"alignment", @"boundsDepend", @"offset", @"content", @"scaleType"]];
    [set unionSet:[super editableAttributes]];
    return set;
}

#pragma mark - override
-(CGSize)contentSize{
    return CGSizeZero;
}

-(CGFloat)contentScale{
    return 1;
}

-(CGRect)contentPresetBounds{
    return CGRectZero;
}

#pragma mark - attach
-(void) buildAttachment{
    if (!_attachment) {
        _attachment = [[AWRTAttachment alloc] init];
    }
    _attachment.fontAscent = self.font.ascender;
    _attachment.fontDescent = self.font.descender;
    _attachment.debugFrame = self.debugFrame;
    
    _attachment.content = self.content;
    _attachment.alignment = self.alignment;
    _attachment.bounds = self.bounds;
    
    _attachment.scaleType = self.scaleType;
    
    [_attachment calcAescentDesccent];
}

-(BOOL) calculateBounds {
    CGFloat scale = self.contentSizeScale;
    if (scale <= 0) {
        scale = 1;
    }
    CGRect presetBounds = self.contentPresetBounds;
    CGFloat contentWid = presetBounds.size.width * scale;
    CGFloat contentHei = presetBounds.size.height * scale;
    switch (self.boundsDepend) {
        case AWRTAttchmentBoundsDependSet:
            if (CGRectEqualToRect(self.bounds, CGRectZero)) {
                NSLog(@"_bounds cannot be Zero when boundsDepend is AWRTImageBoundsDependSet");
                return NO;
            }
            break;
        case AWRTAttchmentBoundsDependFont:{
            if (!self.font) {
                NSLog(@"_font cannot be nil when boundsDepend is AWRTImageBoundsDependFont");
                return NO;
            }
            if (contentWid <= 0 || contentHei <= 0) {
//                NSLog(@"contentWid and contentHei cannot be 0 when boundsDepend is AWRTImageBoundsDependFont");
                return NO;
            }
            CGFloat rate = contentWid / contentHei;
            CGFloat srcHei = fabs(self.font.ascender) + fabs(self.font.descender);
            contentHei = srcHei * scale;
            contentWid = contentHei * rate;
            self.bounds = CGRectMake(0, self.font.ascender - (srcHei / 2) * (scale - 1), contentWid, contentHei);
        }
            break;
        case AWRTAttchmentBoundsDependContent:{
            if (contentWid <= 0 || contentHei <= 0) {
//                NSLog(@"contentWid and contentHei cannot be 0 when boundsDepend is AWRTImageBoundsDependContent");
                return NO;
            }
            self.bounds = CGRectMake(presetBounds.origin.x, presetBounds.origin.y - (presetBounds.size.height / 2) * (scale - 1), contentWid, contentHei);
        }
            break;
        default:
            break;
    }
    
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        NSLog(@" _bounds cant be Zero when calculateBounds");
        return NO;
    }
    
    if (!CGPointEqualToPoint(self.offset, CGPointZero)) {
        self.bounds = CGRectMake(self.bounds.origin.x + self.offset.x, self.bounds.origin.y + self.offset.y, self.bounds.size.width, self.bounds.size.height);
    }
    return YES;
}

-(NSAttributedString *)build{
    if (![self calculateBounds]) {
        return nil;
    }
    
    [self buildAttachment];
    if (!_attachment) {
        return nil;
    }
    
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateCurrentVersion;
    callbacks.getAscent = AWRTImageCTRunAscentCallback;
    callbacks.getDescent = AWRTImageCTRunDescentCallback;
    callbacks.getWidth = AWRTImageCTRunWidthCallback;
    callbacks.dealloc = AWDeallocCallback;
    unichar objectReplacementChar = 0xFFFC;
    NSString *objectReplacementString = [NSString stringWithCharacters:&objectReplacementChar length:1];
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge_retained void *)_attachment);
    _attachment.ctRunDelegateRef = delegate;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:objectReplacementString];
    [attributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id _Nonnull)(delegate) range:NSMakeRange(0, attributedString.length)];
    if (delegate) {
        CFRelease(delegate);
    }
    
    return attributedString;
}

#pragma mark - encode
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        self.alignment = [aDecoder decodeIntegerForKey:AWRTAttachmentCompAlignment];
        self.boundsDepend = [aDecoder decodeIntegerForKey:AWRTAttachmentCompBoundsDepend];
        self.offset = [[aDecoder decodeObjectForKey:AWRTAttachmentCompOffset] CGPointValue];
        self.bounds = [[aDecoder decodeObjectForKey:AWRTAttachmentCompBounds] CGRectValue];
        self.scaleType = [aDecoder decodeIntegerForKey:AWRTImageAttachScaleType];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInteger:self.alignment forKey:AWRTAttachmentCompAlignment];
    [aCoder encodeInteger:self.boundsDepend forKey:AWRTAttachmentCompBoundsDepend];
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.offset] forKey:AWRTAttachmentCompOffset];
    [aCoder encodeObject:[NSValue valueWithCGRect:self.bounds] forKey:AWRTAttachmentCompBounds];
    [aCoder encodeInteger:self.scaleType forKey:AWRTImageAttachScaleType];
}

#pragma mark - copy
-(id)copyWithZone:(NSZone *)zone{
    return ((AWRTAttachmentComponent *)[super copyWithZone:zone])
    .AWAlignment(@(self.alignment))
    .AWBoundsDepend(@(self.boundsDepend))
    .AWOffsets([NSValue valueWithCGPoint:self.offset])
    .AWBounds([NSValue valueWithCGRect:self.bounds])
    .AWScaleType(@(self.scaleType))
    ;
}

@end
