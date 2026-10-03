#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMDUtils : NSObject

+ (void)showToast:(NSString *)message;
+ (void)showToast:(NSString *)message duration:(NSTimeInterval)duration;
+ (UIWindow *)keyWindow;
+ (UIButton *)createButtonWithTitle:(NSString *)title frame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
