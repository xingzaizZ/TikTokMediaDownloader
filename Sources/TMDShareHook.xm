#import "TikTokHeaders.h"
#import "TMDMediaManager.h"
#import "TMDUtils.h"

#pragma mark - 下载选项弹窗（复用长按面板的实现）
extern void TMDShowDownloadSheet(AWEAwemeModel *aweme);

#pragma mark - 通用分享面板注入逻辑

static void TMDInjectDownloadButtonToSharePanel(UIViewController *self) {
    // 尝试获取当前作品
    __block AWEAwemeModel *aweme = nil;
    if ([self respondsToSelector:@selector(awemeModel)]) {
        aweme = [self valueForKey:@"awemeModel"];
    } else if ([self respondsToSelector:@selector(aweme)]) {
        aweme = [self valueForKey:@"aweme"];
    } else if ([self respondsToSelector:@selector(awemeDetail)]) {
        aweme = [self valueForKey:@"awemeDetail"];
    }

    if (!aweme) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIButton *downloadBtn = [TMDUtils createButtonWithTitle:@"无损下载"
                                                             frame:CGRectMake(0, 0, 80, 30)];
        downloadBtn.titleLabel.font = [UIFont systemFontOfSize:13];

        if (@available(iOS 14.0, *)) {
            [downloadBtn addAction:[UIAction actionWithHandler:^(UIAction *action) {
                [self dismissViewControllerAnimated:YES completion:^{
                    TMDShowDownloadSheet(aweme);
                }];
            }] forControlEvents:UIControlEventTouchUpInside];
        }

        // 尝试添加到导航栏
        if ([self.navigationItem respondsToSelector:@selector(setRightBarButtonItem:)]) {
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:downloadBtn];
            self.navigationItem.rightBarButtonItem = item;
        } else {
            // 备选：添加到 view 上
            downloadBtn.frame = CGRectMake(self.view.bounds.size.width - 100, 20, 80, 30);
            downloadBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            [self.view addSubview:downloadBtn];
        }
    });
}

#pragma mark - Hook 多个可能的分享面板类名
// TikTok 45.7.0 可能使用以下类名之一，全部 Hook 以确保兼容

%hook AWESharePanelViewController
- (void)viewDidLoad {
    %orig;
    TMDInjectDownloadButtonToSharePanel(self);
}
%end

%hook AWEModernSharePanelViewController
- (void)viewDidLoad {
    %orig;
    TMDInjectDownloadButtonToSharePanel(self);
}
%end
