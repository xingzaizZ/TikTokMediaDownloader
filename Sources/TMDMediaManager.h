#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TikTokHeaders.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TMDMediaType) {
    TMDMediaTypeVideo,
    TMDMediaTypeImage,
    TMDMediaTypeAudio,
};

@interface TMDMediaManager : NSObject

+ (instancetype)shared;

#pragma mark - 解析方法

/** 从作品模型获取所有视频清晰度选项 */
+ (NSArray<NSDictionary *> *)videoQualityOptionsFromAweme:(AWEAwemeModel *)aweme;

/** 从作品模型获取所有图片 URL */
+ (NSArray<NSString *> *)imageURLsFromAweme:(AWEAwemeModel *)aweme;

/** 获取当前查看的图片 URL */
+ (NSString *)currentImageURLFromAweme:(AWEAwemeModel *)aweme;

/** 获取音频 URL */
+ (nullable NSString *)audioURLFromAweme:(AWEAwemeModel *)aweme;

/** 是否是实况照片 */
+ (BOOL)isLivePhoto:(AWEAwemeModel *)aweme;

/** 是否是图集（多图） */
+ (BOOL)isAlbum:(AWEAwemeModel *)aweme;

#pragma mark - 下载方法

/** 下载媒体文件到临时目录 */
+ (void)downloadMediaFromURL:(NSString *)urlString
                     mediaType:(TMDMediaType)mediaType
                      progress:(void (^)(float progress))progressBlock
                    completion:(void (^)(BOOL success, NSURL *_Nullable fileURL))completion;

/** 下载视频（自动合并音频如果提供） */
+ (void)downloadVideoFromURL:(NSString *)videoURL
                     audioURL:(nullable NSString *)audioURL
                     progress:(void (^)(float progress))progressBlock
                   completion:(void (^)(BOOL success, NSURL *_Nullable fileURL))completion;

#pragma mark - 保存方法

/** 保存视频到相册 */
+ (void)saveVideoToAlbum:(NSURL *)videoURL completion:(void (^)(BOOL success))completion;

/** 保存图片到相册 */
+ (void)saveImageToAlbum:(NSURL *)imageURL completion:(void (^)(BOOL success))completion;

/** 保存实况照片到相册 */
+ (void)saveLivePhotoWithImageURL:(NSURL *)imageURL videoURL:(NSURL *)videoURL completion:(void (^)(BOOL success))completion;

/** 取消所有下载 */
+ (void)cancelAllDownloads;

@end

NS_ASSUME_NONNULL_END
