/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <UIKit/UIKit.h>
#import "ChatView.h"

#import "AWDemoTool.h"

///随机颜色
static inline UIColor *fakeRandomColor(){
    return [UIColor colorWithRed: (arc4random() % 255) / 510.f green:(arc4random() % 255) / 510.f blue:(arc4random() % 255) / 510.f alpha:1];
}

///随机名字
static inline NSString *fakeRandomName(){
    NSArray *names = @[@"了不起的盖茨比", @"超级花美男", @"marsll", @"起点hck", @"星辰变", @"不喜人潮", @"阿门阿啊阿啊阿啊阿"];
    return names[arc4random() % names.count];
}

///随机聊天文字
static inline NSString *fakeRandomSayWords(){
    NSArray *contents = @[@"杨幂在唱歌？？？柳岩在唱歌？？？傻傻分不清楚，天呀！！！这是谁？",
                       @"大神太厉害了～",
                       @"主播不玩炫测了吗？？？？？",
                       @"炫测这英雄废了。。。。",
                       @"星辰变有人看过吗",
                       @"玩啥游戏的都有啊阿啊 枪火游侠",
                       @"80过图 200开商店 加V 56234442"];
    return contents[arc4random() % contents.count];
}

///随机礼物名 对应gif
static inline NSString *fakeRandomGiftName(){
    NSArray *giftNames = @[@"bangbangda", @"yufan", @"zan"];
    return giftNames[arc4random() % giftNames.count];
}

@interface FakeChatUserModel: NSObject
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) UIColor *nameColor;
@property (nonatomic, unsafe_unretained) BOOL isVip;
@property (nonatomic, unsafe_unretained) BOOL isFemal;
@property (nonatomic, unsafe_unretained) NSInteger level;
@property (nonatomic, unsafe_unretained) NSInteger juewei;
@property (nonatomic, copy) NSString *familyName;
@property (nonatomic, unsafe_unretained) NSInteger familyLevel;
@property (nonatomic, unsafe_unretained) BOOL isAdmin;

+(FakeChatUserModel *) randomModel;
@end

@interface FakeChatModel : NSObject
///普通聊天
+(ChatViewModel *)chatModelWithUserModel:(FakeChatUserModel *)userModel content:(NSString *)content contentColor:(UIColor *)contentColor toUserModel:(FakeChatUserModel *)toUserModel maxWid:(CGFloat)maxWid;
+(ChatViewModel *)randomChatModelWithMaxWid:(CGFloat)maxWid;
///送礼
+(ChatViewModel *)chatModelWithUserModel:(FakeChatUserModel *)userModel toUserModel:(FakeChatUserModel *)toUserModel giftName:(NSString *) giftName count:(NSInteger) count countColor:(UIColor *)countColor maxWid:(CGFloat)maxWid;
+(ChatViewModel *)randomGiftModelWithMaxWid:(CGFloat)maxWid;


//获取家族
+(UIView *)viewWithFamilyName:(NSString *)familyName familyLevel:(NSInteger)familyLevel;
///获取等级view
+(UIView *)imageViewWithLevel:(NSInteger) level;
@end
