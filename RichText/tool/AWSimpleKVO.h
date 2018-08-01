/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <Foundation/Foundation.h>

@interface AWSimpleKVO : NSObject

-(instancetype) initWithObj:(NSObject *)obj;

-(void)awAddObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block;

-(void)awRemoveObserverForKeyPath:(NSString *)keyPath context:(void *)context;

-(void)awSetValue:(id)value forKey:(NSString*)key;

@end

#define AWSIMPLEKVOPREFIX @"AWSimpleKVO_"

@class AWSimpleKVO;
@interface NSObject(AWSimpleKVO)
-(AWSimpleKVO *)awSimpleKVO;
-(void)awAddObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block;
-(void)awRemoveObserverForKeyPath:(NSString *)keyPath context:(void *)context;
-(BOOL)awIsObserving;
-(void)awSetValue:(id) value forKey:(NSString *)key;
@end
