/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWRTComponent.h"

NSString *AWRTComponentDefaultMode = @"aw_rt_default_mode";

#define AWRTCompFont @"AWRTCompFont"
#define AWRTCompPaddingLeft @"AWRTCompPaddingLeft"
#define AWRTCompPaddingRight @"AWRTCompPaddingRight"
#define AWRTCompAttributesForMode @"AWRTCompAttributesForMode"
#define AWRTCompCurrentMode @"AWRTCompCurrentMode"
#define AWRTCompDebugFrame @"AWRTCompDebugFrame"
#define AWRTCompTouchable @"AWRTCompTouchable"

@interface AWRTComponent()
@property (nonatomic, strong) NSMutableDictionary *attributesForMode;
@property (nonatomic, strong) NSAttributedString *attributedString;

@property (nonatomic, unsafe_unretained) BOOL ignoreKvoObserve;
@end

@implementation AWRTComponent

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        [self onInit];
    }
    return self;
}

-(void)dealloc{
    [self _removeUpdateableObservers];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if(self){
        [self _addUpdateableObservers];
        
        self.font = [aDecoder decodeObjectForKey:AWRTCompFont];
        self.paddingLeft = [aDecoder decodeIntegerForKey:AWRTCompPaddingLeft];
        self.paddingRight = [aDecoder decodeIntegerForKey:AWRTCompPaddingRight];
        self.attributesForMode = [aDecoder decodeObjectForKey:AWRTCompAttributesForMode];
        self.currentMode = [aDecoder decodeObjectForKey:AWRTCompCurrentMode];
        self.debugFrame = [aDecoder decodeBoolForKey:AWRTCompDebugFrame];
        self.touchable = [aDecoder decodeBoolForKey:AWRTCompTouchable];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.font forKey:AWRTCompFont];
    [aCoder encodeInteger:self.paddingLeft forKey:AWRTCompPaddingLeft];
    [aCoder encodeInteger:self.paddingRight forKey:AWRTCompPaddingRight];
    [aCoder encodeObject:self.attributesForMode forKey:AWRTCompAttributesForMode];
    [aCoder encodeObject:self.currentMode forKey:AWRTCompCurrentMode];
    [aCoder encodeBool:self.debugFrame forKey:AWRTCompDebugFrame];
    [aCoder encodeBool:self.touchable forKey:AWRTCompTouchable];
}

-(id)copyWithZone:(NSZone *)zone{
    AWRTComponent *newComp = [[self.class alloc] init];
    newComp.font = [self.font copyWithZone:zone];
    newComp.paddingLeft = self.paddingLeft;
    newComp.paddingRight = self.paddingRight;
    newComp.attributesForMode = [self.attributesForMode mutableCopyWithZone:zone];
    newComp.currentMode = self.currentMode;
    newComp.debugFrame = self.debugFrame;
    newComp.touchable = self.touchable;
    
    return newComp;
}

#pragma mark - kvo
-(void)_addUpdateableObservers{
    NSSet *editableAttributes = self.editableAttributes;
    for (NSString *key in editableAttributes) {
        [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
}

-(void)_removeUpdateableObservers{
    NSSet *editableAttributes = self.editableAttributes;
    for (NSString *key in editableAttributes) {
        [self removeObserver:self forKeyPath:key];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (self.ignoreKvoObserve) {
        return;
    }
    if ([change[@"old"] isEqual:change[@"new"]]) {
        return;
    }
    
    [self setNeedsBuild];
}

#pragma mark - update delegate
-(void)setNeedsBuild{
    [self.parent setNeedsBuild];
}

-(void)updateIfNeed{
    [self.parent updateIfNeed];
}

-(BOOL)checkIfBuildingState{
    return [self.parent checkIfBuildingState];
}

-(BOOL)checkIfInitingState{
    return [self.parent checkIfInitingState];
}

#pragma mark - attributes

-(void)setAsyncArchiveBlock:(AWRTComponentAsyncArchiveBlock)asyncArchiveBlock{
    _asyncArchiveBlock = asyncArchiveBlock;
    if (_asyncArchiveBlock) {
        _asyncArchiveBlock(self);
    }
}

-(AWRTComponentChain)AWAsyncArchiveBlock{
    return ^(id block){
        self.asyncArchiveBlock = block;
        return self;
    };
}

-(AWRTComponentChain) AWPaddingLeft{
    return ^(id paddingLeft){
        self.paddingLeft = [paddingLeft integerValue];
        return self;
    };
}

-(AWRTComponentChain) AWPaddingRight{
    return ^(id paddingRight){
        self.paddingRight = [paddingRight integerValue];
        return self;
    };
}

-(AWRTComponentChain)AWDebugFrame{
    return ^(id debugFrame){
        if ([debugFrame respondsToSelector:@selector(integerValue)]) {
            self.debugFrame = [debugFrame integerValue];
        }
        return self;
    };
}

-(AWRTComponentChain) AWFont{
    return ^(id font){
        if ([font isKindOfClass:[UIFont class]]) {
            self.font = font;
        }
        return self;
    };
}

#pragma mark - pading help methods

-(NSString *)paddingStringWithCount:(NSInteger) count{
    if (count > 0) {
        NSMutableString *tempString = [NSMutableString new];
        for (int i = 0; i < count; i++) {
            [tempString appendString:@" "];
        }
        return tempString;
    }
    return nil;
}

-(NSAttributedString *) applyPaddingForAttributedString:(NSAttributedString *)as{
    if (!self.paddingLeft && !self.paddingRight) {
        return as;
    }
    
    NSMutableAttributedString * attributedString = [as mutableCopy];
    
    NSDictionary *paddingAttributes = nil;
    if (self.font) {
        paddingAttributes = @{NSFontAttributeName:self.font};
    }
    NSString *paddingLeft = [self paddingStringWithCount:self.paddingLeft];
    if (paddingLeft) {
        NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithString:paddingLeft attributes:paddingAttributes];
        [newAttributedString appendAttributedString:attributedString];
        attributedString = newAttributedString;
    }
    
    NSString *paddingRight = [self paddingStringWithCount:self.paddingRight];
    if (paddingRight) {
        [attributedString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:paddingRight attributes:paddingAttributes]];
    }
    return attributedString;
}

#pragma mark - override
-(void)onInit{
    self.attributesForMode = [[NSMutableDictionary alloc] init];
    self.currentMode = AWRTComponentDefaultMode;
    [self _addUpdateableObservers];
}

-(NSAttributedString *)attributedString{
    [self _build];
    return _attributedString;
}

-(NSAttributedString *)build{
    return nil;
}

-(NSSet *)editableAttributes{
    return [NSSet setWithArray:@[@"paddingLeft", @"paddingRight", @"font", @"debugFrame"]];
}

-(void) _build{
    _attributedString = [self applyPaddingForAttributedString:[self build]];
}

#pragma mark - mode
///清除当前设置的所有属性
-(NSDictionary *) allAttributesDict{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSString *key in self.editableAttributes) {
        dict[key] = [self valueForKey:key];
    }
    return dict;
}

-(void) emptyComponentAttributes{
    self.ignoreKvoObserve = YES;
    for (NSString *key in self.editableAttributes) {
        if([[self valueForKey:key] isKindOfClass:[NSValue class]]){
            [self setValue:@0 forKey:key];
        } else {
            [self setValue:nil forKey:key];
        }
    }
    self.ignoreKvoObserve = NO;
}

-(void) applyAttributesWithMode:(NSString *)mode{
    NSDictionary *currModeDict = self.attributesForMode[mode];
    if (![currModeDict isKindOfClass:[NSDictionary class]] || currModeDict.count <= 0) {
        return;
    }
    
    ///清除旧值
    [self emptyComponentAttributes];
    
    ///设置新值
    self.ignoreKvoObserve = YES;
    for (NSString *key in currModeDict.allKeys) {
        [self setValue:currModeDict[key] forKey:key];
    }
    self.ignoreKvoObserve = NO;
}

-(void)setCurrentMode:(NSString *)mode{
    if ([_currentMode isEqualToString:mode]) {
        return;
    }
    
    if (_currentMode && !self.attributesForMode[mode]) {
        return;
    }
    
    _currentMode = mode;
    
    [self applyAttributesWithMode:_currentMode];
    
    [self setNeedsBuild];
}

-(NSArray *)allModes{
    return self.attributesForMode.allKeys;
}

-(void) beginUpdateMode:(NSString *)updateMode block:(void (^)(void))block{
    [self beginUpdateMode:updateMode storeAttributesWhenBegin:YES restoreAttributesWhenFinished:YES block:block];
}

-(void) beginUpdateMode:(NSString *)updateMode storeAttributesWhenBegin:(BOOL) storeAttributesWhenBegin restoreAttributesWhenFinished:(BOOL) restoreAttributesWhenFinished block:(void(^)(void))block{
    if (!storeAttributesWhenBegin) {
        [self emptyComponentAttributes];
    }
    
    block();
    
    self.attributesForMode[updateMode] = self.allAttributesDict;
    
    if (restoreAttributesWhenFinished) {
        [self applyAttributesWithMode:self.currentMode];
    }
}

-(void)storeAllAttributesToMode:(NSString *)mode replace:(BOOL)replace{
    NSMutableDictionary *currDict = [self.attributesForMode[mode] mutableCopy];
    if ([currDict isKindOfClass:[NSDictionary class]] && currDict.count > 0) {
        if (replace) {
            self.attributesForMode[mode] = self.allAttributesDict;
        }else{
            NSDictionary *attributes = self.allAttributesDict;
            for (NSString *key in attributes.allKeys) {
                if (currDict[key] == nil) {
                    currDict[key] = attributes[key];
                }
            }
            self.attributesForMode[mode] = currDict;
        }
    }else{
        self.attributesForMode[mode] = self.allAttributesDict;
    }
}

@end

