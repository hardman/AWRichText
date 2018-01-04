/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTViewComponent.h"

#define AWRTViewCompView @"AWRTViewCompView"

@implementation AWRTViewComponent

#pragma mark - override
-(void)onInit{
    [super onInit];
}

-(CGRect)contentPresetBounds{
    return _view.frame;
}

#pragma mark - attributes
-(void)setView:(UIView *)view{
    if (![view isKindOfClass:[UIView class]]) {
        return;
    }
    if (_view == view) {
        return;
    }
    _view = view;
    self.content = view;
}

#pragma mark - chain
-(AWRTViewComponentChain)AWView{
    return ^(id view){
        if ([view isKindOfClass:[UIView class]]) {
            self.view = view;
        }
        return self;
    };
}

-(AWRTViewComponentChain)AWContent{
    return (AWRTViewComponentChain) [super AWContent];
}

-(AWRTViewComponentChain)AWBoundsDepend{
    return (AWRTViewComponentChain) [super AWBoundsDepend];
}

-(AWRTViewComponentChain)AWBounds{
    return (AWRTViewComponentChain) [super AWBounds];
}

-(AWRTViewComponentChain)AWAlignment{
    return (AWRTViewComponentChain) [super AWAlignment];
}

-(AWRTViewComponentChain)AWOffsets{
    return (AWRTViewComponentChain) [super AWOffsets];
}

-(AWRTViewComponentChain)AWScaleType{
    return (AWRTViewComponentChain) [super AWScaleType];
}

-(AWRTViewComponentChain)AWFont{
    return (AWRTViewComponentChain) [super AWFont];
}

-(AWRTViewComponentChain)AWPaddingLeft{
    return (AWRTViewComponentChain) [super AWPaddingLeft];
}

-(AWRTViewComponentChain)AWPaddingRight{
    return (AWRTViewComponentChain) [super AWPaddingRight];
}

-(AWRTViewComponentChain)AWDebugFrame{
    return (AWRTViewComponentChain) [super AWDebugFrame];
}

#pragma mark - coding
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        self.view = [aDecoder decodeObjectForKey:AWRTViewCompView];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.view forKey:AWRTViewCompView];
}

#pragma mark - copy
-(id)copyWithZone:(NSZone *)zone{
    AWRTViewComponent *viewComp = ((AWRTViewComponent *)[super copyWithZone:zone]);
    
    NSData *viewData = nil;
    if (self.view) {
        viewData = [NSKeyedArchiver archivedDataWithRootObject:self.view];
        if (viewData) {
            viewComp.AWView([NSKeyedUnarchiver unarchiveObjectWithData:viewData]);
        }
    }
    
    return viewComp;
}

@end
