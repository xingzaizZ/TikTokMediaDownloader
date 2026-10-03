#import "TikTokHeaders.h"
#import "TMDMediaManager.h"
#import "TMDUtils.h"

#pragma mark - 背景关闭辅助类

@interface TMDOverlayDismisser : NSObject
+ (instancetype)shared;
- (void)dismiss:(UIButton *)sender;
@end

@implementation TMDOverlayDismisser
+ (instancetype)shared {
    static TMDOverlayDismisser *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[TMDOverlayDismisser alloc] init]; });
    return instance;
}
- (void)dismiss:(UIButton *)sender {
    [sender.superview removeFromSuperview];
}
@end

#pragma mark - 下载选项弹窗

static NSObject *tmd_lock = nil;

void TMDShowDownloadSheet(AWEAwemeModel *aweme) {
    if (!aweme) {
        [TMDUtils showToast:@"无法获取作品信息"];
        return;
    }
    if (!tmd_lock) tmd_lock = [[NSObject alloc] init];

    UIWindow *window = [TMDUtils keyWindow];
    if (!window) return;

    // 半透明背景
    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    overlay.tag = 998878;
    [window addSubview:overlay];

    // 弹窗
    CGFloat sheetWidth = MIN(window.bounds.size.width - 40, 320);
    UIView *sheet = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sheetWidth, 0)];
    sheet.backgroundColor = [UIColor whiteColor];
    sheet.layer.cornerRadius = 14;
    sheet.clipsToBounds = YES;
    [overlay addSubview:sheet];

    CGFloat yOffset = 16;

    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, yOffset, sheetWidth - 32, 20)];
    titleLabel.text = @"选择下载内容";
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [sheet addSubview:titleLabel];
    yOffset += 32;

    // 视频下载选项
    NSArray *videoOptions = [TMDMediaManager videoQualityOptionsFromAweme:aweme];
    BOOL isLivePhoto = [TMDMediaManager isLivePhoto:aweme];
    BOOL isAlbum = [TMDMediaManager isAlbum:aweme];

    if (videoOptions.count > 0 && !isAlbum) {
        for (NSDictionary *opt in videoOptions) {
            UIButton *btn = [TMDUtils createButtonWithTitle:opt[@"label"] frame:CGRectMake(16, yOffset, sheetWidth - 32, 44)];
            TMDAddButtonAction(btn, ^(UIButton *sender) {
                [overlay removeFromSuperview];
                [TMDUtils showToast:@"开始下载视频..."];
                [TMDMediaManager downloadVideoFromURL:opt[@"url"]
                                              audioURL:[TMDMediaManager audioURLFromAweme:aweme]
                                              progress:^(float p) {}
                                            completion:^(BOOL success, NSURL *fileURL) {
                    if (success && fileURL) {
                        [TMDMediaManager saveVideoToAlbum:fileURL completion:^(BOOL saved) {
                            [TMDUtils showToast:saved ? @"视频已保存到相册" : @"保存失败"];
                        }];
                    } else {
                        [TMDUtils showToast:@"下载失败"];
                    }
                }];
            });
            [sheet addSubview:btn];
            yOffset += 52;
        }
    }

    // 图集下载
    if (isAlbum) {
        NSArray *imageURLs = [TMDMediaManager imageURLsFromAweme:aweme];
        if (imageURLs.count > 0) {
            UIButton *btn = [TMDUtils createButtonWithTitle:[NSString stringWithFormat:@"保存全部图片 (%lu张)", (unsigned long)imageURLs.count]
                                                        frame:CGRectMake(16, yOffset, sheetWidth - 32, 44)];
            TMDAddButtonAction(btn, ^(UIButton *sender) {
                [overlay removeFromSuperview];
                [TMDUtils showToast:[NSString stringWithFormat:@"开始下载 %lu 张图片...", (unsigned long)imageURLs.count]];
                __block NSInteger successCount = 0;
                __block NSInteger total = imageURLs.count;
                for (NSString *url in imageURLs) {
                    [TMDMediaManager downloadMediaFromURL:url mediaType:TMDMediaTypeImage progress:nil completion:^(BOOL s, NSURL *f) {
                        if (s && f) {
                            [TMDMediaManager saveImageToAlbum:f completion:^(BOOL saved) {
                                @synchronized(tmd_lock) {
                                    if (saved) successCount++;
                                    if (successCount + (total - successCount) >= total) {
                                        [TMDUtils showToast:[NSString stringWithFormat:@"已保存 %ld/%ld 张图片", (long)successCount, (long)total]];
                                    }
                                }
                            }];
                        }
                    }];
                }
            });
            [sheet addSubview:btn];
            yOffset += 52;
        }

        // 当前图片
        NSString *currentURL = [TMDMediaManager currentImageURLFromAweme:aweme];
        if (currentURL) {
            UIButton *btn = [TMDUtils createButtonWithTitle:@"保存当前图片" frame:CGRectMake(16, yOffset, sheetWidth - 32, 44)];
            TMDAddButtonAction(btn, ^(UIButton *sender) {
                [overlay removeFromSuperview];
                [TMDUtils showToast:@"开始下载图片..."];
                [TMDMediaManager downloadMediaFromURL:currentURL mediaType:TMDMediaTypeImage progress:nil completion:^(BOOL s, NSURL *f) {
                    if (s && f) {
                        [TMDMediaManager saveImageToAlbum:f completion:^(BOOL saved) {
                            [TMDUtils showToast:saved ? @"图片已保存到相册" : @"保存失败"];
                        }];
                    } else {
                        [TMDUtils showToast:@"下载失败"];
                    }
                }];
            });
            [sheet addSubview:btn];
            yOffset += 52;
        }
    }

    // 实况照片
    if (isLivePhoto) {
        UIButton *btn = [TMDUtils createButtonWithTitle:@"保存实况照片" frame:CGRectMake(16, yOffset, sheetWidth - 32, 44)];
        TMDAddButtonAction(btn, ^(UIButton *sender) {
            [overlay removeFromSuperview];
            [TMDUtils showToast:@"实况照片保存功能开发中"];
        });
        [sheet addSubview:btn];
        yOffset += 52;
    }

    // 音频下载
    NSString *audioURL = [TMDMediaManager audioURLFromAweme:aweme];
    if (audioURL && !isAlbum) {
        UIButton *btn = [TMDUtils createButtonWithTitle:@"保存音频 (MP3)" frame:CGRectMake(16, yOffset, sheetWidth - 32, 44)];
        TMDAddButtonAction(btn, ^(UIButton *sender) {
            [overlay removeFromSuperview];
            [TMDUtils showToast:@"开始下载音频..."];
            [TMDMediaManager downloadMediaFromURL:audioURL mediaType:TMDMediaTypeAudio progress:nil completion:^(BOOL s, NSURL *f) {
                if (s && f) {
                    [TMDMediaManager saveVideoToAlbum:f completion:^(BOOL saved) {
                        [TMDUtils showToast:saved ? @"音频已保存" : @"保存失败"];
                    }];
                } else {
                    [TMDUtils showToast:@"下载失败"];
                }
            }];
        });
        [sheet addSubview:btn];
        yOffset += 52;
    }

    // 取消按钮
    yOffset += 8;
    UIButton *cancelBtn = [TMDUtils createButtonWithTitle:@"取消" frame:CGRectMake(16, yOffset, sheetWidth - 32, 44)];
    cancelBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    [cancelBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    TMDAddButtonAction(cancelBtn, ^(UIButton *sender) {
        [overlay removeFromSuperview];
    });
    [sheet addSubview:cancelBtn];
    yOffset += 52;

    // 设置弹窗大小和位置
    sheet.frame = CGRectMake(0, 0, sheetWidth, yOffset + 16);
    sheet.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);

    // 点击背景关闭
    UIButton *bgButton = [UIButton buttonWithType:UIButtonTypeCustom];
    bgButton.frame = overlay.bounds;
    bgButton.backgroundColor = [UIColor clearColor];
    [bgButton addTarget:[TMDOverlayDismisser shared] action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [overlay insertSubview:bgButton atIndex:0];
}

#pragma mark - 通用长按面板注入逻辑

static NSArray *TMDInjectDownloadToLongPressPanel(id self, NSArray *original) {
    AWEAwemeModel *aweme = nil;
    if ([self respondsToSelector:@selector(awemeModel)]) {
        aweme = [self valueForKey:@"awemeModel"];
    }
    if (!aweme) return original;

    NSMutableArray *result = [original mutableCopy];

    AWELongPressPanelBaseViewModel *downloadVM = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
    if ([downloadVM respondsToSelector:@selector(setAwemeModel:)]) {
        downloadVM.awemeModel = aweme;
    }
    if ([downloadVM respondsToSelector:@selector(setActionType:)]) {
        downloadVM.actionType = 9999;
    }
    if ([downloadVM respondsToSelector:@selector(setDescribeString:)]) {
        downloadVM.describeString = @"无损下载";
    }
    if ([downloadVM respondsToSelector:@selector(setAction:)]) {
        downloadVM.action = ^{
            AWELongPressPanelManager *mgr = [%c(AWELongPressPanelManager) shareInstance];
            if (mgr && [mgr respondsToSelector:@selector(dismissWithAnimation:completion:)]) {
                [mgr dismissWithAnimation:YES completion:^{
                    TMDShowDownloadSheet(aweme);
                }];
            } else {
                TMDShowDownloadSheet(aweme);
            }
        };
    }

    [result addObject:downloadVM];
    return result;
}

#pragma mark - 构造函数：注入成功提示

__attribute__((constructor))
static void TMDConstructor() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [TMDUtils showToast:@"TikTokMediaDownloader 已注入成功"];
    });
}

#pragma mark - 辅助：查找当前显示的 viewController

static UIViewController *TMDTopViewController() {
    UIViewController *vc = [TMDUtils keyWindow].rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}

static AWEAwemeModel *TMDCurrentAweme() {
    UIViewController *top = TMDTopViewController();
    UIViewController *check = top;
    NSInteger depth = 0;
    while (check && depth < 10) {
        if ([check respondsToSelector:NSSelectorFromString(@"currentAweme")]) {
            id aweme = [check valueForKey:@"currentAweme"];
            if (aweme) return aweme;
        }
        if ([check respondsToSelector:NSSelectorFromString(@"currentAwemeModel")]) {
            id aweme = [check valueForKey:@"currentAwemeModel"];
            if (aweme) return aweme;
        }
        for (UIViewController *child in check.childViewControllers) {
            if ([child respondsToSelector:NSSelectorFromString(@"currentAweme")]) {
                id aweme = [child valueForKey:@"currentAweme"];
                if (aweme) return aweme;
            }
        }
        check = check.parentViewController;
        depth++;
    }
    return nil;
}

#pragma mark - Hook BDImageView 长按（参考 NA9TikTok 方式）

%hook BDImageView
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    %orig;
    if (sender.state == UIGestureRecognizerStateEnded) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AWEAwemeModel *aweme = TMDCurrentAweme();
            if (aweme) {
                TMDShowDownloadSheet(aweme);
            } else {
                [TMDUtils showToast:@"未获取到视频信息"];
            }
        });
    }
}
%end
