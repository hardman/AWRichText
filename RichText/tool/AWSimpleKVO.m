/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */


#import "AWSimpleKVO.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import <UIKit/UIKit.h>

@interface AWSimpleKVOCounterItem: NSObject
@property (nonatomic, copy) NSString *className;
@property (nonatomic, unsafe_unretained) NSInteger count;
@end

@implementation AWSimpleKVOCounterItem
@end

@interface AWSimpleKVOCounter: NSObject
@property (nonatomic, strong) NSMutableDictionary * items;
@end

@implementation AWSimpleKVOCounter

-(NSMutableDictionary *)items{
    if (!_items) {
        _items = [[NSMutableDictionary alloc] init];
    }
    return _items;
}

-(void) increaceForClassName:(NSString *)name{
    @synchronized(self){
        AWSimpleKVOCounterItem *item = self.items[name];
        if(!item){
            item = [[AWSimpleKVOCounterItem alloc] init];
            item.className = name;
            self.items[name] = item;
        }
        item.count++;
    }
}

-(void) reduceForClassName:(NSString *)name{
    @synchronized(self){
        AWSimpleKVOCounterItem *item = self.items[name];
        NSAssert(item != nil, @"错误");
        item.count --;
        if (item.count <= 0) {
            objc_disposeClassPair(NSClassFromString(name));
            self.items[name] = nil;
        }
    }
}

@end

static AWSimpleKVOCounter *sSimpleKVOCounter = nil;

static AWSimpleKVOCounter *awGetSimpleKVOCounter(){
    if (sSimpleKVOCounter == nil) {
        sSimpleKVOCounter = [[AWSimpleKVOCounter alloc] init];
    }
    return sSimpleKVOCounter;
}

typedef enum : NSUInteger {
    AWSimpleKVOSupporedIvarTypeUnknown,
    AWSimpleKVOSupporedIvarTypeChar,
    AWSimpleKVOSupporedIvarTypeInt,
    AWSimpleKVOSupporedIvarTypeShort,
    AWSimpleKVOSupporedIvarTypeLong,
    AWSimpleKVOSupporedIvarTypeLongLong,
    AWSimpleKVOSupporedIvarTypeUChar,
    AWSimpleKVOSupporedIvarTypeUInt,
    AWSimpleKVOSupporedIvarTypeUShort,
    AWSimpleKVOSupporedIvarTypeULong,
    AWSimpleKVOSupporedIvarTypeULongLong,
    AWSimpleKVOSupporedIvarTypeFloat,
    AWSimpleKVOSupporedIvarTypeDouble,
    AWSimpleKVOSupporedIvarTypeBool,
    AWSimpleKVOSupporedIvarTypeObject,
    
    AWSimpleKVOSupporedIvarTypeCGSize,
    AWSimpleKVOSupporedIvarTypeCGPoint,
    AWSimpleKVOSupporedIvarTypeCGRect,
    AWSimpleKVOSupporedIvarTypeCGVector,
    AWSimpleKVOSupporedIvarTypeCGAffineTransform,
    AWSimpleKVOSupporedIvarTypeUIEdgeInsets,
    AWSimpleKVOSupporedIvarTypeUIOffset,
} AWSimpleKVOSupporedIvarType;

@interface AWSimpleKVOItem: NSObject
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, unsafe_unretained) void *context;
@property (nonatomic, strong) void (^block)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context);

@property (nonatomic, strong) id oldValue;

@property (nonatomic, unsafe_unretained) AWSimpleKVOSupporedIvarType ivarType;
@property (nonatomic, copy) NSString *ivarTypeCode;

#pragma inner
@property (nonatomic, unsafe_unretained) IMP _localMethod;
@property (nonatomic, unsafe_unretained) IMP _superMethod;
@property (nonatomic, unsafe_unretained) SEL _setSel;
@property (nonatomic, copy) NSString *_localMethodTypeCoding;
@end

@implementation AWSimpleKVOItem
-(BOOL) isValid {
    return self.block && [self.keyPath isKindOfClass:[NSString class]];
}

-(BOOL) invokeBlockWithChange:(NSDictionary *)change obj:(NSObject *)obj{
    if ([self isValid]){
        self.block(obj, self.keyPath, change, self.context);
        return YES;
    }
    ///执行失败
    return NO;
}
@end

@interface AWSimpleKVO()
@property (nonatomic, weak) NSObject *obj;
@property (nonatomic, strong) NSMutableDictionary *observerDict;
@property (nonatomic, copy) NSString *simpleKVOClassName;
@property (nonatomic, weak) Class simpleKVOClass;
@property (nonatomic, weak) Class simpleKVOOriClass;

@property (nonatomic, unsafe_unretained) BOOL isCounted;
@end

static NSString *_getSelWithKeyPath(NSString *keyPath){
    if(keyPath.length == 0){
        return nil;
    }else{
        NSString *uppercase = [[[keyPath substringToIndex:1] uppercaseString] stringByAppendingString:[keyPath substringFromIndex:1]];
        return [NSString stringWithFormat:@"set%@:",uppercase];
    }
}

static NSString *_getKeyPathWithSel(NSString *sel){
    if (sel.length <= 4) {
        return nil;
    }else{
        NSString *uppercase = [sel substringWithRange:NSMakeRange(3, sel.length - 4)];
        return [[[uppercase substringToIndex:1] lowercaseString] stringByAppendingString:[uppercase substringFromIndex:1]];
    }
}

static NSString *_getStructTypeWithTypeEncode(NSString *typeEncode){
    if (typeEncode.length < 3) {
        return nil;
    }
    NSRange locate = [typeEncode rangeOfString:@"="];
    if (locate.length == 0) {
        return nil;
    }
    return [typeEncode substringWithRange: NSMakeRange(1, locate.location - 1)];
}

static AWSimpleKVOItem * _localSetterReady(id obj, SEL sel) {
    NSString *str = NSStringFromSelector(sel);
    NSString *keyPath = _getKeyPathWithSel(str);
    AWSimpleKVO *simpleKVO = [obj awSimpleKVO];
    AWSimpleKVOItem *item = simpleKVO.observerDict[keyPath];
    return item;
}

static void _localSetterNotify(AWSimpleKVOItem *item, id obj, NSString *keyPath, id valueNew){
    if (item) {
        NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
        change[@"old"] = item.oldValue;
        change[@"new"] = valueNew;
        item.oldValue = valueNew;
        item.block(obj, keyPath, change, nil);
    }
}

static void _localSetterObj(id obj, SEL sel, id v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    if(item.oldValue == v) {
        return;
    }
    
    ((void (*)(id, SEL, id))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, v);
}

static void _localSetterNumber(id obj, SEL sel, long long v){
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    //忽略相同赋值
    if([item.oldValue longLongValue] == v) {
        return;
    }
    id number = nil;
    switch (item.ivarType) {
        case AWSimpleKVOSupporedIvarTypeChar:
            ((void (*)(id, SEL, char))item._superMethod)(obj, sel, (char)v);
            break;
        case AWSimpleKVOSupporedIvarTypeInt:
            ((void (*)(id, SEL, int))item._superMethod)(obj, sel, (int)v);
            break;
        case AWSimpleKVOSupporedIvarTypeShort:
            ((void (*)(id, SEL, short))item._superMethod)(obj, sel, (short)v);
            break;
        case AWSimpleKVOSupporedIvarTypeLong:
            ((void (*)(id, SEL, long))item._superMethod)(obj, sel, (long)v);
            break;
        case AWSimpleKVOSupporedIvarTypeLongLong:
            ((void (*)(id, SEL, long long))item._superMethod)(obj, sel, (long long)v);
            break;
        case AWSimpleKVOSupporedIvarTypeUChar:
            ((void (*)(id, SEL, unsigned char))item._superMethod)(obj, sel, (unsigned char)v);
            break;
        case AWSimpleKVOSupporedIvarTypeUInt:
            ((void (*)(id, SEL, unsigned int))item._superMethod)(obj, sel, (unsigned int)v);
            break;
        case AWSimpleKVOSupporedIvarTypeUShort:
            ((void (*)(id, SEL, unsigned short))item._superMethod)(obj, sel, (unsigned short)v);
            break;
        case AWSimpleKVOSupporedIvarTypeULong:
            ((void (*)(id, SEL, unsigned long))item._superMethod)(obj, sel, (unsigned long)v);
            break;
        case AWSimpleKVOSupporedIvarTypeULongLong:
            ((void (*)(id, SEL, unsigned long long))item._superMethod)(obj, sel, (unsigned long long)v);
            break;
        case AWSimpleKVOSupporedIvarTypeFloat:
            ((void (*)(id, SEL, float))item._superMethod)(obj, sel, (float)v);
            break;
        case AWSimpleKVOSupporedIvarTypeDouble:
            ((void (*)(id, SEL, double))item._superMethod)(obj, sel, (double)v);
            break;
        case AWSimpleKVOSupporedIvarTypeBool:
            ((void (*)(id, SEL, bool))item._superMethod)(obj, sel, (bool)v);
            break;
        default:
            return;
    }
    _localSetterNotify(item, obj, item.keyPath, number);
}

static void _localSetterCGPoint(id obj, SEL sel, CGPoint v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    
    if(CGPointEqualToPoint([item.oldValue CGPointValue], v)){
        return;
    }
    
    ((void (*)(id, SEL, CGPoint))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWithCGPoint: v]);
}

static void _localSetterCGSize(id obj, SEL sel, CGSize v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    
    if(CGSizeEqualToSize([item.oldValue CGSizeValue], v)){
        return;
    }
    
    ((void (*)(id, SEL, CGSize))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWithCGSize: v]);
}

static void _localSetterCGRect(id obj, SEL sel, CGRect v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    
    if(CGRectEqualToRect([item.oldValue CGRectValue], v)){
        return;
    }
    
    ((void (*)(id, SEL, CGRect))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWithCGRect: v]);
}

static void _localSetterCGVector(id obj, SEL sel, CGVector v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    
    CGVector oldV = [item.oldValue CGVectorValue];
    
    if(oldV.dx == v.dx && oldV.dy == v.dy){
        return;
    }
    
    ((void (*)(id, SEL, CGVector))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWithCGVector: v]);
}

static void _localSetterCGAffineTransform(id obj, SEL sel, CGAffineTransform v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    
    if(CGAffineTransformEqualToTransform([item.oldValue affineTransform], v)){
        return;
    }
    
    ((void (*)(id, SEL, CGAffineTransform))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWithCGAffineTransform: v]);
}

static void _localSetterUIEdgeInsets(id obj, SEL sel, UIEdgeInsets v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    
    if(UIEdgeInsetsEqualToEdgeInsets([item.oldValue UIEdgeInsetsValue], v)){
        return;
    }
    
    ((void (*)(id, SEL, UIEdgeInsets))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWithUIEdgeInsets: v]);
}

static void _localSetterUIOffset(id obj, SEL sel, UIOffset v) {
    AWSimpleKVOItem *item = _localSetterReady(obj, sel);
    
    if(UIOffsetEqualToOffset([item.oldValue UIOffsetValue], v)){
        return;
    }
    
    ((void (*)(id, SEL, UIOffset))item._superMethod)(obj, sel, v);
    
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWithUIOffset: v]);
}

@implementation AWSimpleKVO

-(instancetype)initWithObj:(NSObject *)obj{
    if (!obj) {
        return nil;
    }
    
    if(self = [super init]) {
        self.obj = obj;
        self.observerDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)awSetValue:(id)value forKey:(NSString*)key{
    if ([self.obj awIsObserving]) {
        NSString *selStr = _getSelWithKeyPath(key);
        SEL selector = NSSelectorFromString(selStr);
        IMP method = class_getMethodImplementation(self.simpleKVOOriClass, selector);
        ((void (*)(id, SEL, id))method)(self.obj, selector, value);
    }else{
        [self.obj setValue:value forKey:key];
    }
}

-(void)awAddObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    NSAssert(self.obj != nil, @"observer is nil");
    NSAssert([keyPath isKindOfClass:[NSString class]], @"keyPath is invalid");
    NSAssert(block != nil, @"block is invalid");
    
    AWSimpleKVOSupporedIvarType ivarType = AWSimpleKVOSupporedIvarTypeUnknown;
    const char * ivTypeCode = method_getTypeEncoding(class_getInstanceMethod([self.obj class], NSSelectorFromString(keyPath)));
    if (!ivTypeCode) {
        //NSAssert(NO, @"不支持的ivar类型");
        return;
    }
    
    SEL setSel = NSSelectorFromString(_getSelWithKeyPath(keyPath));
    IMP localMethod = NULL;
    IMP superMethod = class_getMethodImplementation(self.obj.awIsObserving ? self.simpleKVOOriClass: self.obj.class, setSel);
    NSString *localMethodTypeCoding = nil;
    
    switch (*ivTypeCode) {
        case 'c':
            ivarType = AWSimpleKVOSupporedIvarTypeChar;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'i':
            ivarType = AWSimpleKVOSupporedIvarTypeInt;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 's':
            ivarType = AWSimpleKVOSupporedIvarTypeShort;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'l':
            ivarType = AWSimpleKVOSupporedIvarTypeLong;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'q':
            ivarType = AWSimpleKVOSupporedIvarTypeLongLong;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'C':
            ivarType = AWSimpleKVOSupporedIvarTypeUChar;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'I':
            ivarType = AWSimpleKVOSupporedIvarTypeUInt;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'S':
            ivarType = AWSimpleKVOSupporedIvarTypeUShort;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'L':
            ivarType = AWSimpleKVOSupporedIvarTypeULong;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'Q':
            ivarType = AWSimpleKVOSupporedIvarTypeULongLong;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'f':
            ivarType = AWSimpleKVOSupporedIvarTypeFloat;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'd':
            ivarType = AWSimpleKVOSupporedIvarTypeDouble;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'B':
            ivarType = AWSimpleKVOSupporedIvarTypeBool;
            localMethod = (IMP)_localSetterNumber;
            localMethodTypeCoding = @"v@:q";
            break;
        case '@':
            ivarType = AWSimpleKVOSupporedIvarTypeObject;
            localMethod = (IMP)_localSetterObj;
            localMethodTypeCoding = @"v@:@";
            break;
        case '{':{
            NSString *typeEncode = [NSString stringWithUTF8String:ivTypeCode];
            NSString *structType = _getStructTypeWithTypeEncode(typeEncode);
            if ([structType isEqualToString: @"CGSize"]) {
                ivarType = AWSimpleKVOSupporedIvarTypeCGSize;
                localMethod = (IMP)_localSetterCGSize;
                localMethodTypeCoding = @"v@:{CGSize=dd}";
            }else if([structType isEqualToString: @"CGPoint" ]) {
                ivarType = AWSimpleKVOSupporedIvarTypeCGPoint;
                localMethod = (IMP)_localSetterCGPoint;
                localMethodTypeCoding = @"v@:{CGPoint=dd}";
            }else if([structType isEqualToString: @"CGRect" ]) {
                ivarType = AWSimpleKVOSupporedIvarTypeCGRect;
                localMethod = (IMP)_localSetterCGRect;
                localMethodTypeCoding = @"v@:{CGRect={CGPoint=dd}{CGSize=dd}}";
            }else if([structType isEqualToString: @"CGVector"]) {
                ivarType = AWSimpleKVOSupporedIvarTypeCGVector;
                localMethod = (IMP)_localSetterCGVector;
                localMethodTypeCoding = @"v@:{CGVector=dd}";
            }else if([structType isEqualToString: @"CGAffineTransform"]) {
                ivarType = AWSimpleKVOSupporedIvarTypeCGAffineTransform;
                localMethod = (IMP)_localSetterCGAffineTransform;
                localMethodTypeCoding = @"v@:{CGAffineTransform=dddddd}";
            }else if([structType isEqualToString: @"UIEdgeInsets"]) {
                ivarType = AWSimpleKVOSupporedIvarTypeUIEdgeInsets;
                localMethod = (IMP)_localSetterUIEdgeInsets;
                localMethodTypeCoding = @"v@:{UIEdgeInsets=dddd}";
            }else if([structType isEqualToString: @"UIOffset"]) {
                ivarType = AWSimpleKVOSupporedIvarTypeUIOffset;
                localMethod = (IMP)_localSetterUIOffset;
                localMethodTypeCoding = @"v@:{UIOffset=dd}";
            }
        }
            break;
        default:
            break;
    }
    
    if (ivarType == AWSimpleKVOSupporedIvarTypeUnknown){
        //NSAssert(NO, @"不支持的ivar类型");
        return;
    }
    
    AWSimpleKVOItem *item = self.observerDict[keyPath];
    if (item) {
        NSAssert(NO, @"重复监听");
        return;
    }
    item = [[AWSimpleKVOItem alloc] init];
    item.keyPath = keyPath;
    item.context = context;
    item.block = block;
    item.ivarType = ivarType;
    item.ivarTypeCode = [[NSString stringWithFormat:@"%s", ivTypeCode] substringToIndex: 1];
    
    item._setSel = setSel;
    item._localMethod = localMethod;
    item._superMethod = superMethod;
    item._localMethodTypeCoding = localMethodTypeCoding;
    
    self.observerDict[keyPath] = item;
    
    Class classNew = [self addNewClassObserverClass:self.obj.class keyPath:keyPath item:item];
    NSAssert(classNew != nil, @"replce method failed");
    
    object_setClass(self.obj, classNew);
}

-(NSString *)simpleKVOClassName{
    if (!_simpleKVOClassName) {
        _simpleKVOClassName = [AWSIMPLEKVOPREFIX stringByAppendingString:NSStringFromClass(self.obj.class)];
    }
    return _simpleKVOClassName;
}

-(Class) simpleKVOClass{
    if (!_simpleKVOClass) {
        _simpleKVOClass = NSClassFromString(self.simpleKVOClassName);
    }
    return _simpleKVOClass;
}

-(Class) simpleKVOOriClass{
    if (!_simpleKVOOriClass) {
        _simpleKVOOriClass = class_getSuperclass(self.simpleKVOClass);
    }
    return _simpleKVOOriClass;
}

-(Class) currObjClass{
    if ([self.obj awIsObserving]) {
        return self.simpleKVOClass;
    }else{
        return self.obj.class;
    }
}

-(Class) addNewClassObserverClass:(Class) c keyPath:(NSString *)keyPath item:(AWSimpleKVOItem *)item {
    Class classNew = self.simpleKVOClass;
    if (!classNew) {
        NSString *classNewName = self.simpleKVOClassName;
        classNew = objc_allocateClassPair(c, classNewName.UTF8String, 0);
        objc_registerClassPair(classNew);
        self.simpleKVOClass = classNew;
        self.simpleKVOOriClass = c;
    }
    
    class_addMethod(classNew, item._setSel, item._localMethod, item._localMethodTypeCoding.UTF8String);
    
    if (!self.isCounted) {
        [awGetSimpleKVOCounter() increaceForClassName: self.simpleKVOClassName];
        self.isCounted = YES;
    }
    return classNew;
}

-(void)awRemoveObserverForKeyPath:(NSString *)keyPath context:(void *)context{
    self.observerDict[keyPath] = nil;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AWSimpleKVOItem *item = self.observerDict[keyPath];
    if(![item invokeBlockWithChange:change obj:self.obj]){
        [self awRemoveObserverForKeyPath:item.keyPath context:item.context];
    }
}

-(void) removeAllObservers {
    [self.observerDict removeAllObjects];
}

-(void)dealloc{
    [self removeAllObservers];
    if (_simpleKVOClassName) {
        [awGetSimpleKVOCounter() reduceForClassName: _simpleKVOClassName];
    }
}

@end

static char awAWSimpleKVOKey = 0;

@implementation NSObject(AWSimpleKVO)

///属性
-(void)setAwSimpleKVO:(AWSimpleKVO *)awSimpleKVO{
    objc_setAssociatedObject(self, &awAWSimpleKVOKey, awSimpleKVO, OBJC_ASSOCIATION_RETAIN);
}

-(AWSimpleKVO *)awSimpleKVO{
    AWSimpleKVO *simpleKVO = objc_getAssociatedObject(self, &awAWSimpleKVOKey);
    if (!simpleKVO) {
        simpleKVO = [[AWSimpleKVO alloc] initWithObj:self];
        self.awSimpleKVO = simpleKVO;
    }
    return simpleKVO;
}

-(void)awAddObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    [self.awSimpleKVO awAddObserverForKeyPath:keyPath options:options context:context block:block];
}

-(void)awRemoveObserverForKeyPath:(NSString *)keyPath context:(void *)context{
    [self.awSimpleKVO awRemoveObserverForKeyPath:keyPath context:context];
}

-(void) awSetValue:(id) value forKey:(NSString *)key{
    if([self awIsObserving]){
        [self.awSimpleKVO awSetValue:value forKey:key];
    }else{
        [self setValue:value forKey:key];
    }
}

-(BOOL)awIsObserving{
    return [NSStringFromClass(self.class) hasPrefix:AWSIMPLEKVOPREFIX];
}
@end
