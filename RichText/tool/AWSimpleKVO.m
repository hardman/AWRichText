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

#define LOCAL_SETTER_NUMBER(type, TypeSet, typeGet) \
static void _localSetter##TypeSet(id obj, SEL sel, type v){ \
    AWSimpleKVOItem *item = _localSetterReady(obj, sel); \
    if([item.oldValue typeGet##Value] == v) {\
        return;\
    }\
    ((void (*)(id, SEL, type))item._superMethod)(obj, sel, v); \
    _localSetterNotify(item, obj, item.keyPath, [NSNumber numberWith##TypeSet:v]); \
}

LOCAL_SETTER_NUMBER(char, Char, char)
LOCAL_SETTER_NUMBER(int, Int, int)
LOCAL_SETTER_NUMBER(short, Short, short)
LOCAL_SETTER_NUMBER(long, Long, long)
LOCAL_SETTER_NUMBER(long long, LongLong, longLong)
LOCAL_SETTER_NUMBER(unsigned char, UnsignedChar, unsignedChar)
LOCAL_SETTER_NUMBER(unsigned int, UnsignedInt, unsignedInt)
LOCAL_SETTER_NUMBER(unsigned short, UnsignedShort, unsignedShort)
LOCAL_SETTER_NUMBER(unsigned long, UnsignedLong, unsignedLong)
LOCAL_SETTER_NUMBER(unsigned long long, UnsignedLongLong, unsignedLongLong)
LOCAL_SETTER_NUMBER(float, Float, float)
LOCAL_SETTER_NUMBER(double, Double, double)
LOCAL_SETTER_NUMBER(bool, Bool, bool)

#define LOCAL_SETTER_STRUCTURE(type, equalMethod) \
static void _localSetter##type(id obj, SEL sel, type v) { \
    AWSimpleKVOItem *item = _localSetterReady(obj, sel); \
    \
    if(equalMethod([item.oldValue type##Value], v)){ \
        return; \
    } \
    \
    ((void (*)(id, SEL, type))item._superMethod)(obj, sel, v); \
    \
    _localSetterNotify(item, obj, item.keyPath, [NSValue valueWith##type: v]); \
}

LOCAL_SETTER_STRUCTURE(CGPoint, CGPointEqualToPoint)
LOCAL_SETTER_STRUCTURE(CGSize, CGSizeEqualToSize)
LOCAL_SETTER_STRUCTURE(CGRect, CGRectEqualToRect)

static BOOL _CGVectorIsEqualToVector(CGVector vector, CGVector vector1) {
    return vector.dx == vector1.dx && vector.dy == vector1.dy;
}
LOCAL_SETTER_STRUCTURE(CGVector, _CGVectorIsEqualToVector)
LOCAL_SETTER_STRUCTURE(CGAffineTransform, CGAffineTransformEqualToTransform)
LOCAL_SETTER_STRUCTURE(UIEdgeInsets, UIEdgeInsetsEqualToEdgeInsets)
LOCAL_SETTER_STRUCTURE(UIOffset, UIOffsetEqualToOffset)

@implementation AWSimpleKVO

-(instancetype)initWithObj:(NSObject *)obj{
    if (!obj) {
        return nil;
    }
    
    if(self = [super init]) {
        @synchronized(self) {
            self.obj = obj;
            self.observerDict = [[NSMutableDictionary alloc] init];
            self.simpleKVOClassName = [AWSIMPLEKVOPREFIX stringByAppendingString:NSStringFromClass(obj.class)];
        }
    }
    return self;
}

-(void)awSetValue:(id)value forKey:(NSString*)key{
    if ([self.obj awIsObserving]) {
        object_setClass(self.obj, self.simpleKVOOriClass);
        [self.obj setValue:value forKey:key];
        object_setClass(self.obj, self.simpleKVOClass);
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
            localMethod = (IMP)_localSetterChar;
            localMethodTypeCoding = @"v@:c";
            break;
        case 'i':
            ivarType = AWSimpleKVOSupporedIvarTypeInt;
            localMethod = (IMP)_localSetterInt;
            localMethodTypeCoding = @"v@:i";
            break;
        case 's':
            ivarType = AWSimpleKVOSupporedIvarTypeShort;
            localMethod = (IMP)_localSetterShort;
            localMethodTypeCoding = @"v@:s";
            break;
        case 'l':
            ivarType = AWSimpleKVOSupporedIvarTypeLong;
            localMethod = (IMP)_localSetterLong;
            localMethodTypeCoding = @"v@:l";
            break;
        case 'q':
            ivarType = AWSimpleKVOSupporedIvarTypeLongLong;
            localMethod = (IMP)_localSetterLongLong;
            localMethodTypeCoding = @"v@:q";
            break;
        case 'C':
            ivarType = AWSimpleKVOSupporedIvarTypeUChar;
            localMethod = (IMP)_localSetterUnsignedChar;
            localMethodTypeCoding = @"v@:C";
            break;
        case 'I':
            ivarType = AWSimpleKVOSupporedIvarTypeUInt;
            localMethod = (IMP)_localSetterUnsignedInt;
            localMethodTypeCoding = @"v@:I";
            break;
        case 'S':
            ivarType = AWSimpleKVOSupporedIvarTypeUShort;
            localMethod = (IMP)_localSetterUnsignedShort;
            localMethodTypeCoding = @"v@:S";
            break;
        case 'L':
            ivarType = AWSimpleKVOSupporedIvarTypeULong;
            localMethod = (IMP)_localSetterUnsignedLong;
            localMethodTypeCoding = @"v@:L";
            break;
        case 'Q':
            ivarType = AWSimpleKVOSupporedIvarTypeULongLong;
            localMethod = (IMP)_localSetterUnsignedLongLong;
            localMethodTypeCoding = @"v@:Q";
            break;
        case 'f':
            ivarType = AWSimpleKVOSupporedIvarTypeFloat;
            localMethod = (IMP)_localSetterFloat;
            localMethodTypeCoding = @"v@:f";
            break;
        case 'd':
            ivarType = AWSimpleKVOSupporedIvarTypeDouble;
            localMethod = (IMP)_localSetterDouble;
            localMethodTypeCoding = @"v@:d";
            break;
        case 'B':
            ivarType = AWSimpleKVOSupporedIvarTypeBool;
            localMethod = (IMP)_localSetterBool;
            localMethodTypeCoding = @"v@:B";
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
    
    AWSimpleKVOItem *item = nil;
    @synchronized(self){
        item = self.observerDict[keyPath];
    }
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
    
    @synchronized(self){
        self.observerDict[keyPath] = item;
    }
    
    Class classNew = [self addNewClassObserverClass:self.obj.class keyPath:keyPath item:item];
    NSAssert(classNew != nil, @"replce method failed");
    
    object_setClass(self.obj, classNew);
}

-(Class) simpleKVOClass{
    if (!_simpleKVOClass) {
        @synchronized(self) {
            if (!_simpleKVOClass) {
                _simpleKVOClass = NSClassFromString(self.simpleKVOClassName);
            }
        }
    }
    return _simpleKVOClass;
}

-(Class) simpleKVOOriClass{
    if (!_simpleKVOOriClass) {
        @synchronized(self) {
            if (!_simpleKVOOriClass) {
                _simpleKVOOriClass = class_getSuperclass(self.simpleKVOClass);
            }
        }
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
    @synchronized(self){
        self.observerDict[keyPath] = nil;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AWSimpleKVOItem *item = nil;
    @synchronized(self){
        item = self.observerDict[keyPath];
    }
    if(![item invokeBlockWithChange:change obj:self.obj]){
        [self awRemoveObserverForKeyPath:item.keyPath context:item.context];
    }
}

-(void) removeAllObservers {
    @synchronized(self){
        [self.observerDict removeAllObjects];
    }
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
