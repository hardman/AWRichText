//
//  AWRTWeekRefrence.m
//  AWRichText
//
//  Created by kaso on 3/11/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

#import "AWRTWeekRefrence.h"

@interface TestAWWeakRef: NSObject
@property (nonatomic, unsafe_unretained) int i;
@end

@implementation TestAWWeakRef

+(instancetype) instanceWithI:(int) i{
    return [[self alloc] initWithI:i];
}

- (instancetype)initWithI:(int) i
{
    self = [super init];
    if (self) {
        self.i = i;
    }
    return self;
}

@end

@interface AWRTWeekRefrence()
@property (nonatomic, weak) id ref;
@end

@implementation AWRTWeekRefrence

-(instancetype)initWithRef:(id)ref{
    _ref = ref;
    return self;
}

-(void)forwardInvocation:(NSInvocation *)invocation{
    if (_ref) {
        [invocation invokeWithTarget:_ref];
    }else{
        void *ret = NULL;
        [invocation setReturnValue:&ret];
    }
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)sel{
    if(_ref){
        return [_ref methodSignatureForSelector:sel];
    }else{
        return [NSObject methodSignatureForSelector:@selector(init)];
    }
}

-(BOOL)respondsToSelector:(SEL)aSelector{
    return [_ref respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object{
    return [_ref isEqual:object];
}

-(NSUInteger)hash{
    return [_ref hash];
}

-(Class)superclass{
    return [_ref superclass];
}

-(Class)class{
    return [_ref class];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (id)performSelector:(SEL)aSelector{
    if ([_ref respondsToSelector:aSelector]) {
        return [_ref performSelector:aSelector];
    }
    return nil;
}
- (id)performSelector:(SEL)aSelector withObject:(id)object{
    if ([_ref respondsToSelector:aSelector]) {
        return [_ref performSelector:aSelector withObject:object];
    }
    return nil;
}
- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2{
    if ([_ref respondsToSelector:aSelector]) {
        return [_ref performSelector:aSelector withObject:object1 withObject:object2];
    }
    return nil;
}
#pragma clang diagnostic pop

- (BOOL)isProxy{
    return YES;
}

- (BOOL)isKindOfClass:(Class)aClass{
    return [_ref isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass{
    return [_ref isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol{
    return [_ref conformsToProtocol:aProtocol];
}

+(void) test{
    NSMutableArray *testObjArr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        [testObjArr addObject:[TestAWWeakRef instanceWithI:i]];
    }
    
    NSMutableArray *testWeakArr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        [testWeakArr addObject:[[AWRTWeekRefrence alloc]initWithRef:testObjArr[i]]];
    }
    
    for (int i = 0; i < 10; i++) {
        NSLog(@"weak[%d]=%d", i, [testWeakArr[i] i]);
    }
    
    NSLog(@" ---- ");
    testObjArr = nil;
    
    for (int i = 0; i < 10; i++) {
        NSLog(@"weak[%d]=%d", i, [testWeakArr[i] i]);
    }
    
}

@end
