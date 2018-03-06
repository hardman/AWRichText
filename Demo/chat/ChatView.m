/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "ChatView.h"
#import "AWRichText.h"

#include "FakeChatModel.h"

#define CHAT_VIEW_CELL_FONT [UIFont systemFontOfSize:14]

@implementation ChatViewComponentModel

///任意文本
+(ChatViewComponentModel *)textComponentModelWithFont:(UIFont *)font text:(NSString *)text color:(UIColor *)color{
    ChatViewComponentModel *textCompModel = [[ChatViewComponentModel alloc] init];
    textCompModel.type = ChatViewCellRTCompTypeText;
    textCompModel.font = font;
    textCompModel.text = text;
    textCompModel.color = color;
    return textCompModel;
}

///任意图片
+(ChatViewComponentModel *)imageComponentModelWithFont:(UIFont *)font image:(UIImage *)image{
    ChatViewComponentModel *imageCompModel = [[ChatViewComponentModel alloc] init];
    imageCompModel.type = ChatViewCellRTCompTypeImage;
    imageCompModel.depend = AWRTAttchmentBoundsDependFont;
    imageCompModel.image = image;
    return imageCompModel;
}

///任意view
+(ChatViewComponentModel *)viewComponentModelWithFont:(UIFont *)font view:(UIView *)view{
    ChatViewComponentModel *viewCompModel = [[ChatViewComponentModel alloc] init];
    viewCompModel.type = ChatViewCellRTCompTypeUIView;
    viewCompModel.depend = AWRTAttchmentBoundsDependFont;
    viewCompModel.view = view;
    return viewCompModel;
}

///任意gif
+(ChatViewComponentModel *)gifComponentModelWithFont:(UIFont *)font image:(UIImage *)image{
    ChatViewComponentModel *imageCompModel = [[ChatViewComponentModel alloc] init];
    imageCompModel.type = ChatViewCellRTCompTypeGif;
    imageCompModel.depend = AWRTAttchmentBoundsDependFont;
    imageCompModel.image = image;
    return imageCompModel;
}
@end

@interface ChatViewModel()
@property (nonatomic, strong) ChatCellRichTextBuilder *builder;
@end

@implementation ChatViewModel

+(instancetype) modelWithCompModels:(NSArray *)array maxWid:(CGFloat) maxWid{
    ChatViewModel *model = [[ChatViewModel alloc] init];
    model.compModels = array;
    model.maxWid = maxWid;
    model.builder = [ChatCellRichTextBuilder builderWithModel:model maxWid:maxWid];
    return model;
}

-(ChatCellRichTextBuilder *)richtextBuilder{
    return _builder;
}

@end

///构造richtext 并计算cell高度
@interface ChatCellRichTextBuilder()
@property (nonatomic, weak) ChatViewModel *model;
@property (nonatomic, unsafe_unretained) CGFloat maxWid;
@property (nonatomic, unsafe_unretained) CGFloat cellHeight;
@property (nonatomic, strong) AWRichText *richtext;
@end

@implementation ChatCellRichTextBuilder

+(instancetype)builderWithModel:(ChatViewModel *)model maxWid:(CGFloat) maxWid{
    if (![model isKindOfClass:[ChatViewModel class]] || maxWid <= 0) {
        return nil;
    }
    ChatCellRichTextBuilder *builder = [[ChatCellRichTextBuilder alloc] init];
    builder.model = model;
    builder.maxWid = maxWid;
    [builder build];
    return builder;
}

-(void) build{
    AWRichText *richText = [[AWRichText alloc] init];
    for (NSInteger i = 0; i < _model.compModels.count; i++) {
        ChatViewComponentModel *compModel = _model.compModels[i];
        switch (compModel.type) {
            case ChatViewCellRTCompTypeGif:{
                AWRTViewComponent *comp = (AWRTViewComponent *)[richText addComponentFromPoolWithType:AWRTComponentTypeView];
                __block UIImageView *imageView = nil;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    imageView = [[UIImageView alloc] init];
                    imageView.frame = CGRectMake(0, 0, compModel.image.size.width, compModel.image.size.height);
                    
                    imageView.animationImages = compModel.image.images;
                    imageView.animationDuration = compModel.image.duration;
                    imageView.image = compModel.image.images.firstObject;
                }];
                
                [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
                
                comp.AWView(imageView)
                .AWFont(CHAT_VIEW_CELL_FONT)
                .AWBoundsDepend(@(AWRTAttchmentBoundsDependContent))
                .AWAlignment(@(AWRTAttachmentAlignCenter))
                .AWPaddingRight(@1);
                
                if (compModel.onTouchComp) {
                    comp.touchable = YES;
                    comp.touchCallback = compModel.onTouchComp;
                }
            }
                break;
            case ChatViewCellRTCompTypeText:{
                AWRTTextComponent *comp = (AWRTTextComponent *)[richText addComponentFromPoolWithType:AWRTComponentTypeText];
                comp.AWText(compModel.text)
                .AWFont(CHAT_VIEW_CELL_FONT)
                .AWColor(compModel.color)
                .AWBackgroundColor(compModel.backgroundColor)
                .AWShadowColor(compModel.shadowColor)
                .AWShadowOffset([NSValue valueWithCGSize:compModel.shadowOffset])
                .AWShadowBlurRadius(@(compModel.shadowBlurRadius))
                .AWPaddingRight(@1)
                ;
                
                if (compModel.onTouchComp) {
                    comp.touchable = YES;
                    comp.touchCallback = compModel.onTouchComp;
                }
            }
                break;
            case ChatViewCellRTCompTypeImage:{
                AWRTImageComponent *comp = (AWRTImageComponent *)[richText addComponentFromPoolWithType:AWRTComponentTypeImage];
                comp.AWImage(compModel.image)
                .AWFont(CHAT_VIEW_CELL_FONT)
                .AWBoundsDepend(@(AWRTAttchmentBoundsDependFont))
                .AWAlignment(@(AWRTAttachmentAlignBottom))
                .AWPaddingRight(@1);
                
                if (compModel.onTouchComp) {
                    comp.touchable = YES;
                    comp.touchCallback = compModel.onTouchComp;
                }
            }
                break;
            case ChatViewCellRTCompTypeUIView:{
                AWRTViewComponent *comp = (AWRTViewComponent *)[richText addComponentFromPoolWithType:AWRTComponentTypeView];
                comp.AWView(compModel.view)
                .AWFont(CHAT_VIEW_CELL_FONT)
                .AWBoundsDepend(@(AWRTAttchmentBoundsDependContent))
                .AWAlignment(@(AWRTAttachmentAlignCenter))
                .AWPaddingRight(@1);
                
                if (compModel.onTouchComp) {
                    comp.touchable = YES;
                    comp.touchCallback = compModel.onTouchComp;
                }
            }
                break;
        }
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [richText attributedString];
    }];
    
    [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
    
    _cellHeight = [richText sizeThatFits:CGSizeMake(_maxWid, 0)].height;
    _richtext = richText;
}

@end

static NSString *sChatViewTableCellId = @"ChatViewTableCell";
@interface ChatViewTableCell: UITableViewCell
@property (nonatomic, unsafe_unretained) CGFloat height;
@property (nonatomic, strong) AWRichTextLabel *rtLabel;
@property (nonatomic, weak) AWRichText *richText;
@end

@implementation ChatViewTableCell

-(void)setRichText:(AWRichText *)richText maxWid:(CGFloat)maxWid{
    if ([_richText isEqual:richText]) {
        return;
    }
    _richText = richText;
    if (_rtLabel) {
        _rtLabel.richText = richText;
    }else{
        _rtLabel = richText.createRichTextLabel;
        _rtLabel.rtFrame = CGRectMake(0, 5, maxWid, 0);
        [self addSubview:_rtLabel];
    }
}

-(void) startAnimating{
    [_richText letAnimStartOrStop:YES];
}

@end

@interface ChatView()<UITableViewDelegate, UITableViewDataSource>
@end

@implementation ChatView{
    UITableView *_tableView;
    NSMutableArray *_tableDataArray;
    BOOL _autoScrollToBtm;
    
    UIButton *_moreMsgBtn;
}

-(void)setAlwaysShowDebugFrame:(BOOL)alwaysShowDebugFrame{
    if (_alwaysShowDebugFrame == alwaysShowDebugFrame) {
        return;
    }
    _alwaysShowDebugFrame = alwaysShowDebugFrame;
    
    [_tableView reloadData];
}

-(void) addModel:(ChatViewModel *)model{
    ///最多展示100条
    while (_tableDataArray.count >= 100) {
        [_tableDataArray removeObjectAtIndex:0];
    }
    [_tableDataArray addObject:model];
    [_tableView reloadData];
    
    if (_autoScrollToBtm) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToBtm];
        });
    }else{
        if (!self.isTableViewAtBottom) {
            [self showMoreMsgBtn];
        }
    }
}

-(void) scrollToBtm{
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_tableDataArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    [self hideMoreMsgBtn];
    _autoScrollToBtm = YES;
}

-(void) openAutoScrollToBtn{
    _autoScrollToBtm = YES;
}

-(void) closeAutoScrollToBtn{
    _autoScrollToBtm = NO;
}

-(BOOL) isTableViewAtBottom{
    return _tableView.contentOffset.y + _tableView.frame.size.height >= _tableView.contentSize.height;
}

-(void) showMoreMsgBtn{
    _moreMsgBtn.hidden = NO;
}

-(void) hideMoreMsgBtn{
    _moreMsgBtn.hidden = YES;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    [self initView];
    return self;
}

-(void) initView{
    [self initTableView];
}

#pragma mark - UITableView
-(void) initTableView{
    _tableDataArray = [[NSMutableArray alloc] init];
    
    _tableView = [[UITableView alloc] initWithFrame:self.bounds];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[ChatViewTableCell class] forCellReuseIdentifier:sChatViewTableCellId];
    [self addSubview:_tableView];
    
    _autoScrollToBtm = YES;
    
    CGFloat moreMsgWid = 80, moreMsgHei = 26;
    _moreMsgBtn = [[UIButton alloc] initWithFrame:CGRectMake(_tableView.frame.size.width / 2 - moreMsgWid / 2, _tableView.frame.size.height - moreMsgHei, moreMsgWid, moreMsgHei)];
    [_moreMsgBtn setBackgroundColor:colorWithRgbCode(@"#ff6600")];
    [_moreMsgBtn setTitle:@"有更多消息" forState:UIControlStateNormal];
    [_moreMsgBtn setTitleColor:colorWithRgbCode(@"#ffffff") forState:UIControlStateNormal];
    [_moreMsgBtn setTitleColor:colorWithRgbCode(@"#aaaaaa") forState:UIControlStateHighlighted];
    _moreMsgBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    _moreMsgBtn.layer.cornerRadius = 5;
    _moreMsgBtn.layer.masksToBounds = YES;
    [_moreMsgBtn addTarget:self action:@selector(onClickMoreMsgBtn) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_moreMsgBtn];
    
    _moreMsgBtn.hidden = YES;
}

-(void) onClickMoreMsgBtn{
    [self scrollToBtm];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _tableDataArray.count;
}

-(ChatViewTableCell *) cellWithTableView:(UITableView *)tableView row:(NSInteger)row{
    ChatViewTableCell *cell = [tableView dequeueReusableCellWithIdentifier:sChatViewTableCellId];
    if (row < _tableDataArray.count) {
        ChatViewModel *model = _tableDataArray[row];
        [cell setRichText:model.richtextBuilder.richtext maxWid:model.maxWid];
        
        cell.richText.alwaysShowDebugFrames = self.alwaysShowDebugFrame;
        
        [cell startAnimating];
        
        cell.backgroundColor = colorWithRgbCode(@"#f7f7f7");
    }else{
        [cell setRichText:nil maxWid:0];
    }
    
    return cell;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self cellWithTableView:tableView row:indexPath.row];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < _tableDataArray.count) {
        ChatViewModel *model = _tableDataArray[indexPath.row];
        return model.richtextBuilder.cellHeight + 10;
    }else{
        return 0.1;
    }
}

#pragma mark - scrollview delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _autoScrollToBtm = NO;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate && self.isTableViewAtBottom) {
        _autoScrollToBtm = YES;
        [self hideMoreMsgBtn];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (self.isTableViewAtBottom) {
        _autoScrollToBtm = YES;
        [self hideMoreMsgBtn];
    }
}

#pragma mark - test
+(void) testWithSuperView:(UIView *)view{
    ChatView *chatView = [[ChatView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
    [view addSubview:chatView];
    
    [self addChatViewModelWithChatView:chatView];
}

+(void) pollChatViewModelWithChatView:(ChatView *)chatView{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf addChatViewModelWithChatView:chatView];
    });
}

+(void) addChatViewModelWithChatView:(ChatView *)chatView{
    static NSInteger count = 0;
    CGFloat maxWid = chatView.bounds.size.width;
    static dispatch_queue_t squeue = nil;
    if(squeue == nil) squeue = dispatch_queue_create("test.chatview.squeue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(squeue, ^{
        ChatViewModel *model = nil;
        if (randomBool()) {
            model = [FakeChatModel randomChatModelWithMaxWid:maxWid];
        }else{
            model = [FakeChatModel randomGiftModelWithMaxWid:maxWid];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [chatView addModel:model];
            if (count++ < NSIntegerMax) {
                [self pollChatViewModelWithChatView:chatView];
            }
        });
    });
}
@end
