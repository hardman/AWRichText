/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWRichText
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    AWRTLabelTouchEventBegan,
    AWRTLabelTouchEventMoved,
    AWRTLabelTouchEventMovedIn,
    AWRTLabelTouchEventMovedOut,
    AWRTLabelTouchEventEndedIn,
    AWRTLabelTouchEventEndedOut,
    AWRTLabelTouchEventCancelled
} AWRTLabelTouchEvent;

static inline BOOL awIsTouchingIn(AWRTLabelTouchEvent touchEvent){
    return touchEvent == AWRTLabelTouchEventBegan || touchEvent == AWRTLabelTouchEventMoved || touchEvent == AWRTLabelTouchEventMovedIn;
}

static inline BOOL awIsTouchingOut(AWRTLabelTouchEvent touchEvent){
    return touchEvent == AWRTLabelTouchEventMovedOut;
}

static inline BOOL awIsTouching(AWRTLabelTouchEvent touchEvent){
    return awIsTouchingIn(touchEvent) || awIsTouchingOut(touchEvent);
}

static inline BOOL awIsTouchEnd(AWRTLabelTouchEvent touchEvent){
    return !awIsTouching(touchEvent);
}

@protocol AWRTComponentUpdateDelegate<NSObject>
#pragma mark - build
-(void) setNeedsBuild;
-(void) updateIfNeed;
-(BOOL) checkIfBuildingState;
-(BOOL) checkIfInitingState;
@end

extern const NSString *AWRTComponentDefaultMode;

typedef id (^AWRTComponentChain)(id);

@interface AWRTComponent : NSObject<NSCopying, NSCoding, AWRTComponentUpdateDelegate>

/// 一般是对应的AWRichText
@property (nonatomic, weak) id<AWRTComponentUpdateDelegate> parent;

/// 标识符
@property (nonatomic, copy) NSString *tag;

#pragma mark - 属性
/// 调试线
@property (nonatomic, unsafe_unretained) BOOL debugFrame;

/// 字体，所有的AWRTComponent及其子类对象都应该设置font，因为Attachment对象计算位置时仍然需要参考font。
@property (nonatomic, strong) UIFont *font;

/// 左右有几个空格，如需要给某个Component添加左右填充空白，单位是空格。
/// 如paddingleft为1则表示此Component输出的富文本会在左侧添加1个空格。
@property (nonatomic, unsafe_unretained) NSInteger paddingLeft;
@property (nonatomic, unsafe_unretained) NSInteger paddingRight;

#pragma mark - 更新模式
/// 所有AWRTComponent的属性更新都应在beginUpdate～endUpdate之间。
/// 下面带block的函数不需要endUpdate，内部已经调用了。
-(BOOL) beginUpdate;
-(BOOL) beginUpdateWithSaveExistsAttributes:(BOOL)saveExistsAttributes;

-(BOOL) endUpdate;
-(BOOL) endUpdateWithSaveExistsAttributes:(BOOL)saveExistsAttributes;

-(BOOL) beginUpdateWithMode:(NSString *)updateMode updateBlock:(void(^)(void))updateBlock;
-(BOOL) beginUpdateWithMode:(NSString *)updateMode updateBlock:(void(^)(void))updateBlock saveExistsAttributes:(BOOL)saveExistsAttributes;

-(BOOL) beginUpdateCurrentModeWithUpdateBlock:(void(^)(void))updateBlock;
-(BOOL) beginUpdateCurrentModeWithUpdateBlock:(void(^)(void))updateBlock saveExistsAttributes:(BOOL)saveExistsAttributes;

@property (nonatomic, copy) NSString *currentMode;

@property (nonatomic, readonly, copy) NSString *updatingMode;

-(NSArray *)allModes;

///清除当前设置的所有属性
-(void) emptyComponentAttributes;

#pragma mark - touchable
@property (nonatomic, unsafe_unretained) BOOL touchable;
@property (nonatomic, unsafe_unretained) NSRange range;
@property (nonatomic, strong) void (^touchCallback)(AWRTComponent *comp, AWRTLabelTouchEvent touchEvent);
@property (nonatomic, strong) NSMutableArray *touchRects;

#pragma mark - 获取attributedString
//生成attributedString，调用会触发build
@property (nonatomic, readonly, strong) NSAttributedString *attributedString;

#pragma mark - 子类需重载的函数
-(void) onInit;
-(NSSet *) editableAttributes;
-(NSAttributedString *) build;

#pragma mark - 链式操作
-(AWRTComponentChain) AWPaddingRight;
-(AWRTComponentChain) AWPaddingLeft;
-(AWRTComponentChain) AWDebugFrame;
-(AWRTComponentChain) AWFont;
@end
