//
//  AWRichTextLabel.h
//  AWRichText
//
//  Created by kaso on 1/11/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

/*
 自检：
 1. component update mode ✅
 2. coding ✅
 3. copy ✅
 4. 完整性，补全可操作属性 ✅
 5. editableAttributes ✅
 6. Label size 获取，autolayout ✅
 7. 注释 & Log
 */

#import <UIKit/UIKit.h>

@class AWRichText;
@interface AWRichTextLabel: UILabel

+(instancetype) labelWithRichText:(AWRichText *)richText rtFrame:(CGRect)rtFrame;
+(instancetype) labelWithRichText:(AWRichText *)richText;

-(instancetype) initWithRichText:(AWRichText *)richText rtFrame:(CGRect)rtFrame;
-(instancetype) initWithRichText:(AWRichText *)richText;

@property (nonatomic, strong) AWRichText *richText;

@property (nonatomic, unsafe_unretained) CGRect rtFrame;

@property (nonatomic, unsafe_unretained) CGFloat rtMaxWidth;

@end
