#AWRichText

> 基于CoreText，面向对象，极简，易用，高效，支持精确点击，UIView混排，GIF动图，并不仅仅局限于图文混排的富文本排版神器。
>
> 代码地址：https://github.com/hardman/AWRichText  -- 喜欢的同学可以给个star。
>
> 接下来会在blog中更新一些具体实现细节。
>

##简述
很多app中都有聊天功能，图文混排也是常见的需求。

iOS原生类：NSAttributedString 就是支持图文混排的。很多应用会用它来实现自己的功能。

但是直接使用它会有很多不方便的地方，大概有下面几个：

1. 太难用，属性那么多，而且使用字典构造，每次用都要查一下文档。更不要说大规模使用了
2. 不支持GIF动图
3. 不支持局部精确点击
4. 不支持UIView与文字进行混排

AWRichText完全解决了这些问题，它的特点如下：

1. 基于 NSAttributedString+CoreText 绘制
2. 面向对象+链式操作，不需记忆繁多的属性名即可快速生成各种文本效果
3. 支持GIF 及 任意UIView 的图文混排
4. 支持精确点击

AWRichText是可以让你在项目中大规模使用的，并不仅仅局限于图文混排的工具。

它适合于如下场景：文字+文字，图片+文字，组件（UIView及其子类）+文字。

因此可出现在：**文档排版**，**聊天排版**，**列表展示**，**广告文案** 等各个位置。

##功能演示
![AWRichText演示](http://upload-images.jianshu.io/upload_images/1334370-0cbdba18bf38519e.gif?imageMogr2/auto-orient/strip)

图中的Demo（直接下载github代码运行即可）包含4部分：

* 第一部分展示了长文本图文混排功能。展示了文字样式，UIView(一个无处安放的按钮)混排，精确点击（蓝紫色字体），GIF动图（小龙）。
* 第二部分展示了富文本的更多使用方式。可以在任意头像+昵称这种列表中使用，省去动态建立UIImageView和UILabel的麻烦。
* 第三部分展示了一个简单的的仿斗鱼聊天功能。展示了如何创建复杂的富文本及获取富文本尺寸等功能。
* 第四部分展示了纯UIView单行排版功能：对于按钮横排的需求很实用，另外点击"打开DebugFrame"按钮，会触发线框模式，能够看到每个文字的位置和大小。

Demo中所有元素都是使用AWRichText构造的。

##使用方法

###1.直接引入文件
将代码中的 "RichText" 文件夹直接拖入你的工程。
引入头文件 "AWRichText.h" 即可使用。
###2.使用pod
在Podfile文件中加入：

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

target 'TargetName' do
pod 'AWRichText', '~> 1.0.0'
end
```
然后命令行执行如下命令：

```
pod install
```

##基本用法

```Objective-C
#include "AWRichText.h"

...
...

AWRichText *richText = [[AWRichText alloc] init];

//创建红色文本hello，文本类型 text和font是必须设置的。
AWRTTextComponent *rTextComp = [[AWRTTextComponent alloc] init]
.AWText(@"hello")
.AWColor([UIColor redColor])
.AWFont([UIFont systemFontOfSize:12])
.AWPaddingRight(@1);
[richText addComponent: rTextComp];

//创建蓝色文本world
AWRTTextComponent *bTextComp = [[AWRTTextComponent alloc] init]
.AWText(@" world")
.AWColor([UIColor blueColor ])
.AWFont([UIFont systemFontOfSize:12])
.AWPaddingRight(@1);
[richText addComponent:bTextComp];

//创建图片，图片类型也请设置font，否则可能显示异常
AWRTImageComponent *imgComp = [[AWRTImageComponent alloc] init]
.AWImage([UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fengtimo.jpg" ofType:nil]])
.AWFont([UIFont systemFontOfSize:12])
.AWBoundsDepend(@(AWRTAttchmentBoundsDependFont))
.AWAlignment(@(AWRTAttachmentAlignCenter))
.AWPaddingRight(@1);
[richText addComponent:imgComp];

//创建UIButton
UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 22)];
btn.titleLabel.font = [UIFont systemFontOfSize:12];
[btn setTitle:@"这是一个button" forState:UIControlStateNormal];
[btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
[btn setTitleColor:[UIColor colorWithRed:170.f/255 green:170.f/255 blue:170.f/255 alpha:1] forState:UIControlStateHighlighted];
[btn setBackgroundColor:[UIColor colorWithRed:1 green:184.f/255 blue:0 alpha:1]];
btn.layer.cornerRadius = 5;
btn.layer.borderWidth = 1/[UIScreen mainScreen].scale;
btn.layer.borderColor = [UIColor colorWithRed:201.f/255 green:201.f/255 blue:201.f/255 alpha:1].CGColor;

//根据button创建ViewComponent，View类型也请设置font，否则可能显示异常
//另外 AWRTxxxComponent组件也可以从Pool中取，直接调用addComponentFromPoolWithType:方法。
//此种方法适合AWRichText的components变化频繁的情况。
//正常情况使用 alloc init的方式生成即可。
((AWRTViewComponent *)[richText addComponentFromPoolWithType:AWRTComponentTypeView])
.AWView(btn)
.AWFont([UIFont systemFontOfSize:12])
.AWBoundsDepend(@(AWRTAttchmentBoundsDependContent))
.AWAlignment(@(AWRTAttachmentAlignCenter));

//创建label，AWRichTextLabel是UILabel的子类
AWRichTextLabel *awLabel = [richText createRichTextLabel];
//请务必设置rtFrame属性，设置后会自动计算frame的尺寸
//宽度为非0，高度为0表示高度自适应。另外若宽度设置特别大，超出文字内容，最终生成的宽度仍然是以文字内容宽度为准。
//宽度为0表示单行。
//系统属性numberOfLines无效
awLabel.rtFrame = CGRectMake(100, 100, 100, 0);

awLabel.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1];

[superView addSubview:awLabel];
...
...

```

上述代码效果：

1 . 当rtFrame为 CGRectMake(100,100,100,0)时：

![宽度为100](http://upload-images.jianshu.io/upload_images/1334370-719d4960d69c6173.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

2 . 当rtFrame为 CGRectMake(100,100,1000,0)时：

![宽度为1000](http://upload-images.jianshu.io/upload_images/1334370-8fca69d2fdcd4035.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

其他用法及效果实现，详见github中的demo。


