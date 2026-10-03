#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - URL 模型

@interface AWEURLModel : NSObject
@property (nonatomic, copy) NSArray<NSString *> *originURLList;
@property (nonatomic, copy) NSArray<NSString *> *urlList;
@end

#pragma mark - 视频模型

@interface AWEVideoModel : NSObject
@property (nonatomic, strong) AWEURLModel *playURL;
@property (nonatomic, strong) AWEURLModel *h264URL;
@property (nonatomic, strong) AWEURLModel *coverURL;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@end

#pragma mark - 音乐模型

@interface AWEMusicModel : NSObject
@property (nonatomic, strong) AWEURLModel *playURL;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@end

#pragma mark - 图片模型（图集）

@interface AWEAlbumImageModel : NSObject
@property (nonatomic, copy) NSArray<NSString *> *urlList;
@property (nonatomic, strong) AWEVideoModel *clipVideo;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@end

#pragma mark - 用户模型

@interface AWEUserModel : NSObject
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *shortID;
@property (nonatomic, copy) NSString *nickname;
@end

#pragma mark - 作品模型（核心）

@interface AWEAwemeModel : NSObject
@property (nonatomic, strong) AWEVideoModel *video;
@property (nonatomic, strong) AWEMusicModel *music;
@property (nonatomic, strong) AWEUserModel *author;
@property (nonatomic, copy) NSArray<AWEAlbumImageModel *> *albumImages;
@property (nonatomic, assign) NSInteger currentImageIndex;
@property (nonatomic, assign) NSInteger awemeType; // 68 = 实况照片
@property (nonatomic, strong) id animatedImageVideoInfo;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *awemeID;
@end

#pragma mark - 长按面板

@interface AWELongPressPanelBaseViewModel : NSObject
@property (nonatomic, strong) AWEAwemeModel *awemeModel;
@property (nonatomic, assign) NSInteger actionType;
@property (nonatomic, copy) NSString *duxIconName;
@property (nonatomic, copy) NSString *describeString;
@property (nonatomic, copy) void (^action)(void);
@end

@interface AWELongPressPanelManager : NSObject
+ (instancetype)shareInstance;
- (void)dismissWithAnimation:(BOOL)animation completion:(void (^)(void))completion;
@end

NS_ASSUME_NONNULL_END
