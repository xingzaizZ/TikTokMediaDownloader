#import "TMDUtils.h"

@implementation TMDUtils

+ (UIWindow *)keyWindow {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
        }
    }
    if (!window) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    return window;
}

+ (void)showToast:(NSString *)message {
    [self showToast:message duration:2.0];
}

+ (void)showToast:(NSString *)message duration:(NSTimeInterval)duration {
    if (!message || message.length == 0) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self keyWindow];
        if (!window) return;

        // 移除旧的 toast
        for (UIView *v in window.subviews) {
            if (v.tag == 998877) {
                [v removeFromSuperview];
            }
        }

        UILabel *label = [[UILabel alloc] init];
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.tag = 998877;
        label.layer.cornerRadius = 8;
        label.clipsToBounds = YES;

        CGSize size = [message boundingRectWithSize:CGSizeMake(window.bounds.size.width - 80, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName: label.font}
                                              context:nil].size;

        label.frame = CGRectMake(0, 0, size.width + 30, size.height + 16);
        label.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height - 120);

        [window addSubview:label];
        label.alpha = 0;

        [UIView animateWithDuration:0.25 animations:^{
            label.alpha = 1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25 delay:duration options:0 animations:^{
                label.alpha = 0;
            } completion:^(BOOL done) {
                [label removeFromSuperview];
            }];
        }];
    });
}

+ (UIButton *)createButtonWithTitle:(NSString *)title frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.layer.cornerRadius = 10;
    btn.clipsToBounds = YES;
    return btn;
}

@end
