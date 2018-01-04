//
//  AWRTWeekRefrence.h
//  AWRichText
//
//  Created by kaso on 3/11/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

#import <Foundation/Foundation.h>

///弱引用实现
@interface AWRTWeekRefrence : NSObject

@property (nonatomic, readonly, weak) id ref;

-(instancetype) initWithRef:(id)ref;

+(void)test;
@end
