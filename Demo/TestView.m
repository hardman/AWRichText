/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "TestView.h"

#import "AWRichText.h"

#import "AWDemoTool.h"

#import "UIImage+AWGif.h"

#import "ChatView.h"

///是否打开DebugFrame
static BOOL sAWTestAlwaysShowDebugFrame = NO;

#pragma mark - 面向对象的富文本排版，远离令人头疼的NSAttributedString

#pragma mark - 长文本图文混排cell 演示诸多基本功能（自定义UIView，精确点击，mode切换）
/// 展示功能：
/// 富文本创建
/// 文本样式
/// 图片样式
/// 自定义UIView样式
/// gif样式
/// 文字截断样式
/// 计算富文本高度
/// 同一个Component存在多种可自由切换Mode
/// 精确点击事件
/// 段落属性
@interface TestLongRTTableCell: UITableViewCell
@property (nonatomic, strong) AWRichTextLabel *rtLabel;
@property (nonatomic, weak) AWRichText *richText;
@property (nonatomic, unsafe_unretained) CGFloat cellHei;
@end

@implementation TestLongRTTableCell

-(void)createWithMaxWid:(CGFloat) maxWid{
    if (!_rtLabel) {
        ///构造richtext
        AWRichText *rt = [[AWRichText alloc] init];
        _richText = rt;
        [self createRichText];
        
        ///创建label
        _rtLabel = rt.createRichTextLabel;
        [self addSubview:_rtLabel];
        
        ///计算cell（富文本）高度
        [_richText attributedString];
        _richText.truncatingTokenComp = [[AWRTTextComponent alloc] init].AWText(@"~~~").AWFont([UIFont systemFontOfSize:12]).AWColor(colorWithRgbCode(@"#00f"));
        ///注意，autolayout中可使用rtMaxWidth这个属性，也可以使用rtFrame
        ///若此处将rtFrame的高度改成一个非零较小的值如60，会有截断效果。
        ///截断字符由truncatingTokenComp决定，如不传，默认为 "..."。
        _rtLabel.rtFrame = CGRectMake(10, 5, maxWid - 20, 0);
        _cellHei = _rtLabel.frame.size.height + 10;
    }
    
    ///启动动画
    [_richText letAnimStartOrStop:YES];
}

-(AWRTTextComponent *)addTextCompWithText:(NSString *)text{
    AWRTTextComponent *textComp = ((AWRTTextComponent *)[self.richText addComponentFromPoolWithType:AWRTComponentTypeText])
    .AWText(text)
    .AWColor(colorWithRgbCode(@"#222"))
    .AWShadowColor(colorWithRgbCode(@"#555"))
    .AWShadowOffset([NSValue valueWithCGSize:CGSizeMake(0, 2)])
    .AWShadowBlurRadius(@(3));
    
    if (@available(iOS 8.2, *)) {
        textComp.AWFont([UIFont systemFontOfSize:14 weight:UIFontWeightBold]);
    } else {
        textComp.AWFont([UIFont systemFontOfSize:14]);
    }
    
    return textComp;
}

-(AWRTTextComponent *)addLinkCompWithText:(NSString *)text onClick:(void (^)(void))onClick{
    AWRTTextComponent *linkComp = [self addTextCompWithText:text]
    .AWColor(colorWithRgbCode(@"#55F"));
    
#define TOUCHING_MODE (@"touchingLinkMode")
#define DEFAULT_MODE ((NSString *)AWRTComponentDefaultMode)
    
    [linkComp storeAllAttributesToMode:DEFAULT_MODE replace:YES];
    
    [linkComp beginUpdateMode:TOUCHING_MODE block:^{
        linkComp.AWUnderlineStyle(@(NSUnderlineStyleSingle))
        .AWUnderlineColor(colorWithRgbCode(@"#55F"));
    }];
    
    linkComp.touchable = YES;
    linkComp.touchCallback = ^(AWRTComponent *comp, AWRTLabelTouchEvent touchEvent) {
        if (awIsTouchingIn(touchEvent)) {
            comp.currentMode = TOUCHING_MODE;
        }else{
            comp.currentMode = DEFAULT_MODE;
        }
        
        if (touchEvent == AWRTLabelTouchEventEndedIn) {
            if (onClick) {
                onClick();
            }
        }
    };
    
    return linkComp;
}

-(AWRTImageComponent *)addImgCompWithImageName:(NSString *)name{
    AWRTImageComponent *imgComponent = ((AWRTImageComponent *) [self.richText addComponentFromPoolWithType:AWRTComponentTypeImage])
    .AWImage([UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:nil]])
    .AWBoundsDepend(@(AWRTAttchmentBoundsDependFont))
    .AWFont([UIFont systemFontOfSize:12]);
    return imgComponent;
}

-(AWRTViewComponent *)addGifCompWithImageName:(NSString *)name{
    UIImage *gifImg = [UIImage animatedGIFWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:nil]]];
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, gifImg.size.width * 0.3f, gifImg.size.height * 0.3f);
    imageView.animationImages = gifImg.images;
    imageView.animationDuration = gifImg.duration;
    imageView.image = gifImg.images.firstObject;
    
    AWRTViewComponent *viewComp = ((AWRTViewComponent *)[self.richText addComponentFromPoolWithType:AWRTComponentTypeView])
    .AWView(imageView)
    .AWFont([UIFont systemFontOfSize:20])
    .AWBoundsDepend(@(AWRTAttchmentBoundsDependContent))
    .AWAlignment(@(AWRTAttachmentAlignCenter))
    .AWPaddingRight(@1);
    
    return viewComp;
}

-(AWRTViewComponent *)addButtonCompWithBtnTitle:(NSString *)title font:(UIFont *)font color:(UIColor *)color target:(id)target action:(SEL)action{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 22)];
    btn.titleLabel.font = font;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn setTitleColor:colorWithRgbCode(@"#aaa") forState:UIControlStateHighlighted];
    [btn setBackgroundColor:colorWithRgbCode(@"#FFB800")];
    btn.layer.cornerRadius = 5;
    btn.layer.borderWidth = 1/[UIScreen mainScreen].scale;
    btn.layer.borderColor = colorWithRgbCode(@"#C9C9C9").CGColor;
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    AWRTViewComponent *viewComp = ((AWRTViewComponent *)[self.richText addComponentFromPoolWithType:AWRTComponentTypeView])
    .AWView(btn)
    .AWFont([UIFont systemFontOfSize:12])
    .AWBoundsDepend(@(AWRTAttchmentBoundsDependContent))
    .AWAlignment(@(AWRTAttachmentAlignCenter))
    .AWPaddingRight(@1);
    
    return viewComp;
    
}

-(void) createRichText{
    [self addTextCompWithText:@"曲曲折折的荷塘"];
    [self addImgCompWithImageName:@"hetang.png"];
    [self addTextCompWithText:@"上面，"];
    [self addTextCompWithText:@"弥望的是田田的叶子"];
    [self addImgCompWithImageName:@"yezi.png"];
    [self addTextCompWithText:@"。叶子出水"];
    [self addImgCompWithImageName:@"shui.png"];
    [self addTextCompWithText:@"很高，像亭亭舞女"];
    [self addImgCompWithImageName:@"tiaowu.png"];
    [self addTextCompWithText:@"的裙。层层的叶子"];
    [self addImgCompWithImageName:@"yezi.png"];
    [self addTextCompWithText:@"中间，零星地点缀着些白花"];
    [self addImgCompWithImageName:@"hua.png"];
    [self addTextCompWithText:@"，有袅娜地开着的，有羞涩地打着朵儿"];
    [self addImgCompWithImageName:@"guduo.png"];
    [self addTextCompWithText:@"的；"];
    UIFont *btnFont = nil;
    if (@available(iOS 8.2, *)) {
        btnFont = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    } else {
        btnFont = [UIFont systemFontOfSize:12];
    }
    [self addButtonCompWithBtnTitle:@"一个无处安放的按钮" font:btnFont color:colorWithRgbCode(@"#000") target:self action:@selector(clickBtn:)];
    [self addTextCompWithText:@"正如一粒粒的明珠"];
    [self addImgCompWithImageName:@"mingzhu.png"];
    [self addTextCompWithText:@"，又如碧天里的星星"];
    [self addImgCompWithImageName:@"xingxing.png"];
    [self addTextCompWithText:@"，又如刚出浴的美人"];
    [self addImgCompWithImageName:@"meiren.png"];
    [self addTextCompWithText:@"。"];
    [self addLinkCompWithText:@"微风过处，送来缕缕清香，仿佛远处高楼" onClick:^{
        NSLog(@"点击到了一个链接");
    }];
    [self addImgCompWithImageName:@"gaolou.png"];
    [self addTextCompWithText:@"上渺茫的歌声"];
    [self addGifCompWithImageName:@"wa.gif"];
    [self addTextCompWithText:@"似的。"];
    
    self.richText.lineSpace = 5;
}

-(void) clickBtn:(UIButton *)btn{
    NSLog(@"点击到了一个按钮：[%@]", btn.titleLabel.text);
}

-(void) resetShowDebugFrame{
    _richText.alwaysShowDebugFrames = sAWTestAlwaysShowDebugFrame;
}

@end

#pragma mark - 列表类控件杀手锏，极大简化列表类UI的创建 可方便处理：【头像+前缀icon x N +昵称】这种排版
/// 列表类图文混排杀手锏
/// 可方便处理：【头像+前缀icon x N +昵称】这种排版
@interface TestHeaderIconRTTableCell:UITableViewCell
@property (nonatomic, strong) AWRichTextLabel *rtLabel;
@property (nonatomic, weak) AWRichText *richText;
@end

@implementation TestHeaderIconRTTableCell

-(void) createRtLabelWithMaxWid:(CGFloat) maxWid{
    if (!_rtLabel) {
        ///创建richtext
        AWRichText *richText = [[AWRichText alloc] init];
        _richText = richText;
        [self createRichText];
        
        ///创建label
        _rtLabel = richText.createRichTextLabel;
        [self addSubview:_rtLabel];
        ///注意，autolayout中可使用rtMaxWidth这个属性，也可以使用rtFrame
        _rtLabel.rtFrame = CGRectMake(10, 5, maxWid - 20, 0);
    }
}

-(void) createRichText{
    UIImageView *headerImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    headerImgView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fengtimo.jpg" ofType:nil]];
    headerImgView.layer.borderWidth = 3;
    headerImgView.layer.borderColor = colorWithRgbCode(@"#FF5722").CGColor;
    headerImgView.layer.cornerRadius = 30;
    headerImgView.layer.masksToBounds = YES;
    
    /// 看似代码很长，但是同一类 component 初始化都是类似的。
    /// 可以很容易地封装成函数调用，如TestLongRTTableCell中Component的创建过程
    AWRTViewComponent *viewComp = [[AWRTViewComponent alloc] init]
    .AWView(headerImgView)
    .AWFont([UIFont systemFontOfSize:14])
    .AWBoundsDepend(@(AWRTAttchmentBoundsDependContent))
    .AWAlignment(@(AWRTAttachmentAlignCenter));
    [self.richText addComponent:viewComp];
    
    AWRTImageComponent *imgComp = [[AWRTImageComponent alloc] init]
    .AWImage([UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"roomadmin.png" ofType:nil]])
    .AWFont([UIFont systemFontOfSize:14])
    .AWBoundsDepend(@(AWRTAttchmentBoundsDependFont))
    .AWAlignment(@(AWRTAttachmentAlignCenter))
    .AWPaddingLeft(@1);
    [self.richText addComponent:imgComp];
    
    AWRTTextComponent *aliasComp = [[AWRTTextComponent alloc] init];
    aliasComp.AWText(@"中了提莫的毒无药可救").AWColor(@"#797f89").AWFont([UIFont systemFontOfSize:14]).AWPaddingLeft(@1);
    [self.richText addComponent:aliasComp];
}

-(void) resetShowDebugFrame{
    _richText.alwaysShowDebugFrames = sAWTestAlwaysShowDebugFrame;
}

@end

#pragma mark - ChatView 一个聊天列表的例子
/// 一个聊天列表的例子
@interface TestChatViewCell:UITableViewCell
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, weak) ChatView *chatView;
@end

@implementation TestChatViewCell

-(void)createContainerViewWithMaxWid:(CGFloat)maxWid{
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, maxWid - 20, 200)];
        [self addSubview:_containerView];
        
        [ChatView testWithSuperView:_containerView];
        _chatView = _containerView.subviews.firstObject;
    }
}

-(void) resetShowDebugFrame{
    _chatView.alwaysShowDebugFrame = sAWTestAlwaysShowDebugFrame;
}

@end

#pragma mark - 控制按钮排版演示，用AWRichText很容易做到重复元素横向排版

typedef enum : NSUInteger {
    TestControlCellBtnTypeShowDebugFrame,
} TestControlCellBtnType;

@class TestControlCell;
@protocol TestControlCellDelegate<NSObject>
@optional
-(void) cell:(TestControlCell *)cell onClickBtnType:(TestControlCellBtnType)type;
@end

@interface TestControlCell: UITableViewCell
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) AWRichTextLabel *rtLabel;
@property (nonatomic, weak) AWRichText *richText;

@property (nonatomic, weak) id<TestControlCellDelegate> delegate;
@end

@implementation TestControlCell

-(void) createRtLabelWithMaxWid:(CGFloat) maxWid{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 5, maxWid - 20, 50)];
        [self addSubview:_scrollView];
    }
    if (!_rtLabel) {
        ///创建richtext
        AWRichText *richText = [[AWRichText alloc] init];
        _richText = richText;
        [self createRichText];
        
        ///创建label
        _rtLabel = richText.createRichTextLabel;
        [_scrollView addSubview:_rtLabel];
        ///注意，autolayout中可使用rtMaxWidth这个属性，也可以使用rtFrame
        [_richText attributedString];
        
        [_rtLabel sizeToFit];
        
        _scrollView.contentSize = _rtLabel.frame.size;
    }
}

-(AWRTViewComponent *)addBtnCompWithView:(UIView *)view{
    AWRTViewComponent *viewComp = [[AWRTViewComponent alloc] init]
    .AWView(view)
    .AWFont([UIFont systemFontOfSize:14])
    .AWBoundsDepend(@(AWRTAttchmentBoundsDependContent))
    .AWAlignment(@(AWRTAttachmentAlignCenter))
    .AWPaddingLeft(@1)
    ;
    [self.richText addComponent:viewComp];
    return viewComp;
}

-(UIButton *)btnWithTitle:(NSString *)title titleColor:(UIColor *)titleColor titleHighlightColor:(UIColor *)titleHighlightColor size:(CGSize)size target:(id)target action:(SEL)action{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:titleColor forState:UIControlStateNormal];
    [btn setTitleColor:titleHighlightColor forState:UIControlStateHighlighted];
    [btn setBackgroundColor:colorWithRgbCode(@"#009688")];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    btn.layer.cornerRadius = 5;
    return btn;
}

-(void) createRichText{
    ///debugFrame按钮
    UIButton *debugFrameBtn = [self btnWithTitle:sAWTestAlwaysShowDebugFrame ? @"关闭DebugFrame": @"打开DebugFrame" titleColor:colorWithRgbCode(@"#fff") titleHighlightColor:colorWithRgbCode(@"#aaa") size:CGSizeMake(160, 40) target:self action:@selector(onClickDebugFrameBtn:)];
    [self addBtnCompWithView:debugFrameBtn];
    
    ///一些演示按钮
    for (NSInteger i = 0; i < 3; i++) {
        UIButton *otherBtn = [self btnWithTitle:@"一些演示按钮" titleColor:colorWithRgbCode(@"#fff") titleHighlightColor:colorWithRgbCode(@"#aaa") size:CGSizeMake(160, 40) target:nil action:nil];
        [self addBtnCompWithView:otherBtn];
    }
}

-(void) onClickDebugFrameBtn:(UIButton *)btn{
    sAWTestAlwaysShowDebugFrame = !sAWTestAlwaysShowDebugFrame;
    if (sAWTestAlwaysShowDebugFrame) {
        [btn setTitle:@"关闭DebugFrame" forState: UIControlStateNormal];
    }else{
        [btn setTitle:@"打开DebugFrame" forState: UIControlStateNormal];
    }
    [self.delegate cell:self onClickBtnType:TestControlCellBtnTypeShowDebugFrame];
}

-(void) resetShowDebugFrame{
    _richText.alwaysShowDebugFrames = sAWTestAlwaysShowDebugFrame;
}

@end

@interface TestTableHeaderView: UITableViewHeaderFooterView
@property (nonatomic, strong) AWRichTextLabel *label;
@property (nonatomic, weak) AWRichText *richText;
@end

@implementation TestTableHeaderView

-(void)createLabelWithMaxWid:(CGFloat)maxWid{
    if (!_label) {
        _label = [[AWRichTextLabel alloc] init];
        _label.rtFrame = CGRectMake(10, 0, maxWid, 0);
        [self addSubview:_label];
    }
}

-(void)setRichText:(AWRichText *)richText{
    if (_richText == richText) {
        return;
    }
    _richText = richText;
    self.label.richText = richText;
}

@end

@interface TestView()<UITableViewDelegate, UITableViewDataSource, TestControlCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation TestView

-(void) initView{
    CGFloat safeTop = 20;
    if (@available(iOS 11.0, *)) {
        safeTop = 44;
    }
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, safeTop, self.bounds.size.width, self.bounds.size.height - safeTop) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[TestLongRTTableCell class] forCellReuseIdentifier:@"TestLongRTTableCell"];
    [tableView registerClass:[TestHeaderIconRTTableCell class] forCellReuseIdentifier:@"TestHeaderIconRTTableCell"];
    [tableView registerClass:[TestControlCell class] forCellReuseIdentifier:@"TestControlCell"];
    [tableView registerClass:[TestTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"TestTableHeaderView"];
    [tableView registerClass:[TestChatViewCell class] forCellReuseIdentifier:@"TestChatViewCell"];
    [self addSubview:tableView];
    _tableView = tableView;
}

#pragma mark - tableview delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return 1;
    }else if(section == 1){
        return 3;
    }else if(section == 2){
        return 1;
    }else if(section == 3){
        return 1;
    }
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        TestLongRTTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TestLongRTTableCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell createWithMaxWid:tableView.bounds.size.width];
        [cell resetShowDebugFrame];
        return cell;
    }else if(indexPath.section == 1){
        TestHeaderIconRTTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TestHeaderIconRTTableCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell createRtLabelWithMaxWid:tableView.bounds.size.width];
        [cell resetShowDebugFrame];
        return cell;
    }else if(indexPath.section == 2){
        TestChatViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TestChatViewCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell resetShowDebugFrame];
        [cell createContainerViewWithMaxWid:tableView.bounds.size.width];
        return cell;
    }else if(indexPath.section == 3){
        TestControlCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TestControlCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell createRtLabelWithMaxWid:tableView.bounds.size.width];
        [cell resetShowDebugFrame];
        cell.delegate = self;
        return cell;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        TestLongRTTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TestLongRTTableCell"];
        [cell createWithMaxWid:tableView.bounds.size.width];
        return cell.cellHei;
    }else if(indexPath.section == 1){
        return 70.f;
    }else if(indexPath.section == 2){
        return 220.f;
    }else if(indexPath.section == 3){
        return 60.f;
    }
    return 0.1f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.1f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 20.f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    TestTableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"TestTableHeaderView"];
    AWRichText *rtText = [[AWRichText alloc] init];
    
    AWRTImageComponent *imgComp = [[AWRTImageComponent alloc] init]
    .AWImage([UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%ld.png", section + 1] ofType:nil]])
    .AWBoundsDepend(@(AWRTAttchmentBoundsDependFont))
    .AWFont([UIFont systemFontOfSize:16]);
    ;
    
    [rtText addComponent:imgComp];
    
    AWRTTextComponent *textComp = [[AWRTTextComponent alloc] init];
    textComp.AWText([NSString stringWithFormat:@"第%ld个section", section + 1]);
    
    if (@available(iOS 8.2, *)) {
        textComp.AWFont([UIFont systemFontOfSize:16 weight:UIFontWeightBold]);
    } else {
        textComp.AWFont([UIFont systemFontOfSize:16]);
    }
    [rtText addComponent:textComp];
    
    rtText.alwaysShowDebugFrames = sAWTestAlwaysShowDebugFrame;
    
    [headerView createLabelWithMaxWid:tableView.bounds.size.width];
    [headerView setRichText:rtText];
    return headerView;
}

-(void)cell:(TestControlCell *)cell onClickBtnType:(TestControlCellBtnType)type{
    if (type == TestControlCellBtnTypeShowDebugFrame) {
        [self.tableView reloadData];
    }
}

+(void) testWithSuperView:(UIView *)superView{
    TestView *tv = [[TestView alloc] initWithFrame:superView.bounds];
    [superView addSubview:tv];
    [tv initView];
}

@end
