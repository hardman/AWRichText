//
//  FakeChatModel.m
//  AWRichText
//
//  Created by kaso on 27/12/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

#import "FakeChatModel.h"
#import "UIImage+AWGif.h"

#define CHAT_FONT [UIFont systemFontOfSize:14]

#define CHAT_COMMON_COLOR colorWithRgbCode(@"#888888")

@implementation FakeChatUserModel

+(FakeChatUserModel *)randomModel{
    FakeChatUserModel *model = [[FakeChatUserModel alloc] init];
    model.name = fakeRandomName();
    model.nameColor = colorWithRgbCode(@"#2b94ff"); //fakeRandomColor();
    model.isVip = randomBool();
    model.isFemal = randomBool();
    model.level = randomInteger(0, 199);
    model.juewei = randomBool();
    model.familyName = fakeRandomName();
    model.familyLevel = randomInteger(1, 99);
    model.isAdmin = randomBool();
    return model;
}

@end

@interface FakeChatModel()
@property (nonatomic, strong) NSOperationQueue *mainQueue;
@end

@implementation FakeChatModel

-(NSOperationQueue *)mainQueue{
    if (!_mainQueue) {
        _mainQueue = [NSOperationQueue mainQueue];
    }
    return _mainQueue;
}

#pragma mark - 聊天

+(NSString *)pathWithName:(NSString *)name{
    return [[NSBundle mainBundle] pathForResource:name ofType:nil];
}

///获取等级view
+(UIView *)imageViewWithLevel:(NSInteger) level{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.layer.contents = (__bridge id _Nullable)([[UIImage imageWithContentsOfFile:[self pathWithName:@"level.png"]] CGImage]);
    static CGFloat wid = 40, hei = 16, off = 3, totalHei = 3588;
    imageView.layer.contentsRect = CGRectMake(0, level * (hei + off) / totalHei, 1, hei/totalHei);
    imageView.layer.contentsGravity = kCAGravityBottom;
    imageView.frame = CGRectMake(0, 0, wid, hei);
    return imageView;
}

///获取vip图片
+(UIImage *)imageForVip{
    return [UIImage imageWithContentsOfFile:[self pathWithName:@"vip.png"]];
}

///爵位图片
+(UIImage *)imageWithJuewei:(NSInteger) juewei{
    NSString *path = nil;
    if (juewei == 0) {
        path = [self pathWithName:@"qishi.png"];
    }else if(juewei == 1){
        path = [self pathWithName:@"zijue.png"];
    }else{
        return nil;
    }
    
    return [UIImage imageWithContentsOfFile:path];
}

///获取femal图片
+(UIImage *)imageForFemal{
    return [UIImage imageWithContentsOfFile:[self pathWithName:@"femal.png"]];
}

///获取房管图片
+(UIImage *)imageForAdmin{
    return [UIImage imageWithContentsOfFile:[self pathWithName:@"roomadmin.png"]];
}

///family
+(UIView *)viewWithFamilyName:(NSString *)familyName familyLevel:(NSInteger)familyLevel{
    ///UIView
    UIView *familyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 65, 24)];
    ///背景
    UIImageView *bgImgView = [[UIImageView alloc] init];
    bgImgView.image = [UIImage imageWithContentsOfFile:[self pathWithName:@"familyBg.png"]];
    [familyView addSubview:bgImgView];
    [bgImgView sizeToFit];
    CGRect bgImgViewFrame = bgImgView.frame;
    bgImgView.frame = CGRectMake(0, 5, bgImgViewFrame.size.width, bgImgViewFrame.size.height);
    
    ///familyName
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = [familyName substringToIndex:3];
    nameLabel.font = [UIFont systemFontOfSize:12];
    nameLabel.textColor = [UIColor whiteColor];
    [familyView addSubview:nameLabel];
    [nameLabel sizeToFit];
    CGRect nameLabelFrame = nameLabel.frame;
    nameLabel.frame = CGRectMake((bgImgViewFrame.size.width - nameLabelFrame.size.width) / 2, 5, nameLabelFrame.size.width, nameLabelFrame.size.height);
    
    ///levelBg
    UIImageView *levelBgImgView = [[UIImageView alloc] init];
    levelBgImgView.image = [UIImage imageWithContentsOfFile:[self pathWithName:@"familyLevel.png"]];
    [familyView addSubview:levelBgImgView];
    [levelBgImgView sizeToFit];
    CGRect levelBgImgFrame = levelBgImgView.frame;
    levelBgImgView.frame = CGRectMake(42, 0, levelBgImgFrame.size.width, levelBgImgFrame.size.height);
    
    ///levelLabel
    UILabel *levelLabel = [[UILabel alloc] init];
    levelLabel.text = [NSString stringWithFormat:@"%ld", familyLevel];
    levelLabel.font = [UIFont boldSystemFontOfSize:12];
    levelLabel.textColor = [UIColor whiteColor];
    [familyView addSubview:levelLabel];
    [levelLabel sizeToFit];
    CGRect levelLabelFrame = levelLabel.frame;
    levelLabel.frame = CGRectMake(42 + (levelBgImgFrame.size.width - levelLabelFrame.size.width) / 2, 5, levelLabelFrame.size.width, levelLabelFrame.size.height);
    
    return familyView;
}

+(UIImage *)giftImageWithName:(NSString *)name{
    return [UIImage animatedGIFWithData:[NSData dataWithContentsOfFile:[self pathWithName:[NSString stringWithFormat:@"%@.gif", name]]]];
}

///用户名+前缀图片
+(void) addUserNameToChatModelWithUserModel:(FakeChatUserModel *)userModel
                               toArray:(NSMutableArray *)toArray{
    ///房管
    if (userModel.isAdmin) {
        ChatViewComponentModel *adminCompModel = [ChatViewComponentModel imageComponentModelWithFont:CHAT_FONT image:[self.class imageForAdmin]];
        [toArray addObject:adminCompModel];
    }
    
    ///femal
    if (userModel.isFemal) {
        ChatViewComponentModel *femalCompModel = [ChatViewComponentModel imageComponentModelWithFont:CHAT_FONT image:[self.class imageForFemal]];
        [toArray addObject:femalCompModel];
    }
    
    ///等级
    if (userModel.level >= 0 && userModel.level <= 119) {
        __block UIView *levelView = nil;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            levelView = [self.class imageViewWithLevel: userModel.level];
        }];
        
        [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
        
        ChatViewComponentModel *levelCompModel = [ChatViewComponentModel viewComponentModelWithFont:CHAT_FONT view:levelView];
        [toArray addObject:levelCompModel];
    }
    
    ///vip
    if (userModel.isVip) {
        ChatViewComponentModel *vipCompModel = [ChatViewComponentModel imageComponentModelWithFont:CHAT_FONT image:[self.class imageForVip]];
        [toArray addObject:vipCompModel];
    }
    
    ///爵位
    if (userModel.juewei == 0 || userModel.juewei == 1) {
        ChatViewComponentModel * jueweiCompModel = [ChatViewComponentModel imageComponentModelWithFont:CHAT_FONT image:[self.class imageWithJuewei:userModel.juewei]];
        [toArray addObject:jueweiCompModel];
    }
    
    ///family
    if ([userModel.familyName isKindOfClass:[NSString class]] && userModel.familyName.length > 0 && userModel.familyLevel > 0) {
        __block UIView *familyView = nil;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            familyView = [self.class viewWithFamilyName:userModel.familyName familyLevel:userModel.familyLevel];
        }];
        
        [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
        
        ChatViewComponentModel *familyCompModel = [ChatViewComponentModel viewComponentModelWithFont:CHAT_FONT view:familyView];
        [toArray addObject:familyCompModel];
    }
    
    ///name
    ChatViewComponentModel *usernameCompModel = [ChatViewComponentModel textComponentModelWithFont:CHAT_FONT text:userModel.name color:userModel.nameColor];
    
    [toArray addObject:usernameCompModel];
}

///普通聊天
+(ChatViewModel *)chatModelWithUserModel:(FakeChatUserModel *)userModel content:(NSString *)content contentColor:(UIColor *)contentColor toUserModel:(FakeChatUserModel *)toUserModel maxWid:(CGFloat)maxWid{
    NSMutableArray *compModelsArray = [[NSMutableArray alloc] init];
    
    ///name
    [self addUserNameToChatModelWithUserModel:userModel toArray:compModelsArray];
    
    ///对 xxx 说
    if (toUserModel) {
        /// 对
        ChatViewComponentModel *toCompModel = [ChatViewComponentModel textComponentModelWithFont:CHAT_FONT text:@"对" color:CHAT_COMMON_COLOR];
        [compModelsArray addObject:toCompModel];
        
        /// toUser
        [self addUserNameToChatModelWithUserModel:toUserModel toArray:compModelsArray];
    }
    
    /// 说
    ChatViewComponentModel *sayCompModel = [ChatViewComponentModel textComponentModelWithFont:CHAT_FONT text:@"说:" color:CHAT_COMMON_COLOR];
    [compModelsArray addObject:sayCompModel];
    
    ///content
    ChatViewComponentModel *contentCompModel = [ChatViewComponentModel textComponentModelWithFont:CHAT_FONT text:content color:contentColor];
    [compModelsArray addObject:contentCompModel];
    
    return [ChatViewModel modelWithCompModels:compModelsArray maxWid:maxWid];
}

///随机聊天model
+(ChatViewModel *)randomChatModelWithMaxWid:(CGFloat)maxWid{
    return [self chatModelWithUserModel:[FakeChatUserModel randomModel] content:fakeRandomSayWords() contentColor:colorWithRgbCode(@"#000000") toUserModel: randomBool() ? [FakeChatUserModel randomModel] : nil maxWid:maxWid];
}

///送礼
+(ChatViewModel *)chatModelWithUserModel:(FakeChatUserModel *)userModel toUserModel:(FakeChatUserModel *)toUserModel giftName:(NSString *) giftName count:(NSInteger) count countColor:(UIColor *)countColor maxWid:(CGFloat)maxWid{
    
    NSMutableArray *compModelsArray = [[NSMutableArray alloc] init];
    ///name
    [self addUserNameToChatModelWithUserModel:userModel toArray:compModelsArray];
    
    ///送给 xxx
    if (toUserModel) {
        /// 送给
        ChatViewComponentModel *toCompModel = [ChatViewComponentModel textComponentModelWithFont:CHAT_FONT text:@"送给" color:CHAT_COMMON_COLOR];
        [compModelsArray addObject:toCompModel];
        
        /// toUser
        [self addUserNameToChatModelWithUserModel:toUserModel toArray:compModelsArray];
    }
    
    /// 礼物
    ChatViewComponentModel *giftCompModel = [ChatViewComponentModel gifComponentModelWithFont:CHAT_FONT image:[self.class giftImageWithName:giftName]];
    [compModelsArray addObject:giftCompModel];
    
    /// x N
    ChatViewComponentModel *countCompModel = [ChatViewComponentModel textComponentModelWithFont:CHAT_FONT text:[NSString stringWithFormat:@"x%ld", count] color:countColor];
    [compModelsArray addObject:countCompModel];
    
    return [ChatViewModel modelWithCompModels:compModelsArray maxWid:maxWid];
}

+(ChatViewModel *)randomGiftModelWithMaxWid:(CGFloat)maxWid{
    return [self chatModelWithUserModel:[FakeChatUserModel randomModel] toUserModel:[FakeChatUserModel randomModel] giftName:fakeRandomGiftName() count:randomInteger(1, 10000) countColor:colorWithRgbCode(@"#eb6100") maxWid:maxWid];
}

@end
