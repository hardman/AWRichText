/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTImageComponent.h"

#define AWRTImageCompImageScale @"AWRTImageCompImageScale"
#define AWRTImageCompImage @"AWRTImageCompImage"

@interface AWRTImageComponent()
@property (nonatomic, strong) UIImage *image;
@end

@implementation AWRTImageComponent

#pragma mark init
-(void)onInit{
    [super onInit];
    self.imageScale = 1;
}

#pragma mark - override
-(CGRect)contentPresetBounds{
    return CGRectMake(0, 0, _image.size.width, _image.size.height);
}

-(NSAttributedString *)build{
    if (!_image) {
        return nil;
    }
    
    return [super build];
}

-(NSSet *)editableAttributes{
    NSMutableSet *set = [NSMutableSet setWithArray:@[@"image", @"font", @"paddingLeft", @"paddingRight", @"imageScale"]];
    [set unionSet:[super editableAttributes]];
    return set;
}

#pragma mark - attributes
-(void)setImage:(UIImage *)image{
    if (![image isKindOfClass:[UIImage class]]) {
        return;
    }
    
    _image = image;
    
    self.content = image;
}

-(void)_setImagePath:(NSString *)imagePath{
    if (![imagePath isKindOfClass:[NSString class]] || imagePath.length == 0) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = nil;
        if (imagePath.isAbsolutePath) {
            image = [UIImage imageWithContentsOfFile:imagePath];
        }else{
            image = [UIImage imageNamed:imagePath];
        }
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    self.image = image;
                }
            });
        }
    });
}

-(void)setAsyncArchiveBlock:(AWRTImagComponentAsyncArchiveBlock)asyncArchiveBlock{
    _asyncArchiveBlock = asyncArchiveBlock;
    if (_asyncArchiveBlock) {
        _asyncArchiveBlock(self);
    }
}

#pragma mark - chain
-(AWRTImageComponentChain)AWImage{
    return ^(id image){
        if ([image isKindOfClass:[UIImage class]]) {
            self.image = image;
        }
        return self;
    };
}

-(AWRTImageComponentChain)AWImageScale{
    return ^(id scale){
        if ([scale respondsToSelector:@selector(floatValue)]) {
            self.imageScale = [scale floatValue];
        }
        return self;
    };
}

-(AWRTImageComponentChain)AWImagePath{
    return ^(id path){
        if ([path isKindOfClass:[NSString class]] && [path length] > 0) {
            [self _setImagePath:path];
        }
        return self;
    };
}

-(AWRTImageComponentChain)AWAsyncArchiveBlock{
    return ^(id block){
        self.asyncArchiveBlock = block;
        return self;
    };
}

-(AWRTImageComponentChain)AWContent{
    return (AWRTImageComponentChain) [super AWContent];
}

-(AWRTImageComponentChain)AWBoundsDepend{
    return (AWRTImageComponentChain) [super AWBoundsDepend];
}

-(AWRTImageComponentChain)AWBounds{
    return (AWRTImageComponentChain) [super AWBounds];
}

-(AWRTImageComponentChain)AWAlignment{
    return (AWRTImageComponentChain) [super AWAlignment];
}

-(AWRTImageComponentChain)AWOffsets{
    return (AWRTImageComponentChain) [super AWOffsets];
}

-(AWRTImageComponentChain)AWFont{
    return (AWRTImageComponentChain) [super AWFont];
}

-(AWRTImageComponentChain)AWPaddingLeft{
    return (AWRTImageComponentChain) [super AWPaddingLeft];
}

-(AWRTImageComponentChain)AWPaddingRight{
    return (AWRTImageComponentChain) [super AWPaddingRight];
}

-(AWRTImageComponentChain)AWDebugFrame{
    return (AWRTImageComponentChain) [super AWDebugFrame];
}

#pragma mark - coding
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        self.imageScale = [aDecoder decodeFloatForKey:AWRTImageCompImageScale];
        self.image = [aDecoder decodeObjectForKey:AWRTImageCompImage];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];
    [aCoder encodeFloat:self.imageScale forKey:AWRTImageCompImageScale];
    [aCoder encodeObject:self.image forKey:AWRTImageCompImage];
}

#pragma mark - copy
-(id)copyWithZone:(NSZone *)zone{
    return ((AWRTImageComponent *)[super copyWithZone:zone])
    .AWImage([self.image copy]).AWImageScale(@(self.imageScale));
}

@end
