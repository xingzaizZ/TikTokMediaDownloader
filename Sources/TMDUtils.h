#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMDUtils : NSObject

+ (void)showToast:(NSString *)message;
+ (void)showToast:(NSString *)message duration:(NSTimeInterval)duration;
+ (UIWindow *)keyWindow;
+ (UIButton *)createButtonWithTitle:(NSString *)title frame:(CGRect)frame;

@end

// 按钮 block 点击辅助
@interface TMDButtonHandler : NSObject
+ (instancetype)shared;
- (void)handleTap:(UIButton *)sender;
@end

#ifdef __cplusplus
extern "C" {
#endif

void TMDAddButtonAction(UIButton *btn, void (^action)(UIButton *));

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
