/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <Foundation/Foundation.h>

///弱引用实现
@interface AWRTWeekRefrence : NSObject

@property (nonatomic, readonly, weak) id ref;

-(instancetype) initWithRef:(id)ref;

+(void)test;
@end
