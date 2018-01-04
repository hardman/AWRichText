/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <UIKit/UIKit.h>

/// 根据颜色代码#rrggbbaa创建UIColor对象
static inline UIColor *colorWithRgbaCode(NSString *code){
    NSString *cCode = code;
    
    if (![cCode hasPrefix:@"#"]) {
        return nil;
    }
    
    if (cCode.length == 5) {
        NSString *first = [cCode substringWithRange:NSMakeRange(1, 1)];
        NSString *second = [cCode substringWithRange:NSMakeRange(2, 1)];
        NSString *third = [cCode substringWithRange:NSMakeRange(3, 1)];
        NSString *four = [cCode substringWithRange:NSMakeRange(4, 1)];
        cCode = [NSString stringWithFormat:@"#%@%@%@%@%@%@%@%@", first, first, second, second, third, third, four, four];
    }
    
    if (cCode.length != 9) {
        return nil;
    }
    
    static NSDictionary * convertDict = nil;
    if (!convertDict) {
        convertDict = @{@"0":@0,@"1":@1,@"2":@2,@"3":@3,@"4":@4,@"5":@5,@"6":@6,@"7":@7,@"8":@8,@"9":@9,@"a":@10,@"b":@11,@"c":@12,@"d":@13,@"e":@14,@"f":@15};
    }
    
    NSString *lowerCode = [cCode lowercaseString];
    
    CGFloat colors[4] = {0};
    
    for (NSInteger i = 1; i < code.length; i += 2) {
        NSString *onePart = [lowerCode substringWithRange:NSMakeRange(i, 1)];
        if (convertDict[onePart] == nil) {
            return nil;
        }
        NSString *twoPart = [lowerCode substringWithRange:NSMakeRange(i + 1, 1)];
        if (convertDict[twoPart] == nil) {
            return nil;
        }
        NSUInteger cvalue = [convertDict[onePart] unsignedCharValue] * 16;
        cvalue += [convertDict[twoPart] unsignedCharValue];
        colors[i / 2] = cvalue / 255.f;
    }
    
    return [UIColor colorWithRed:colors[0] green:colors[1] blue:colors[2] alpha:colors[3]];
}

/// 根据颜色代码#rrggbb创建UIColor对象
static inline UIColor *colorWithRgbCode(NSString *code){
    NSString *cCode = code;
    
    if (![cCode hasPrefix:@"#"]) {
        return nil;
    }
    
    if (cCode.length == 4) {
        NSString *first = [cCode substringWithRange:NSMakeRange(1, 1)];
        NSString *second = [cCode substringWithRange:NSMakeRange(2, 1)];
        NSString *third = [cCode substringWithRange:NSMakeRange(3, 1)];
        cCode = [NSString stringWithFormat:@"#%@%@%@%@%@%@", first, first, second, second, third, third];
    }
    
    if (cCode.length != 7) {
        return nil;
    }
    return colorWithRgbaCode([NSString stringWithFormat:@"%@ff", cCode]);
}

///随机integer闭区间
static inline NSInteger randomInteger(NSInteger start, NSInteger end){
    return start + arc4random() % (end - start + 1);
}

///随机bool
static inline BOOL randomBool(){
    return randomInteger(0, 1) == 0;
}

@interface AWDemoTool : NSObject

@end
