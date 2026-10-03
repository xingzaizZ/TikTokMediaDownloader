#import "TMDMediaManager.h"
#import <Photos/Photos.h>

static NSOperationQueue *downloadQueue = nil;

@implementation TMDMediaManager

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadQueue = [[NSOperationQueue alloc] init];
        downloadQueue.maxConcurrentOperationCount = 2;
    });
}

+ (instancetype)shared {
    static TMDMediaManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TMDMediaManager alloc] init];
    });
    return instance;
}

#pragma mark - 解析方法

+ (NSArray<NSDictionary *> *)videoQualityOptionsFromAweme:(AWEAwemeModel *)aweme {
    NSMutableArray *options = [NSMutableArray array];
    AWEVideoModel *video = aweme.video;
    if (!video) return options;

    // h264 高清
    if (video.h264URL.originURLList.count > 0) {
        [options addObject:@{
            @"label": @"高清 (H.264)",
            @"url": video.h264URL.originURLList.firstObject,
        }];
    }

    // 普通播放地址
    if (video.playURL.originURLList.count > 0) {
        NSString *url = video.playURL.originURLList.firstObject;
        BOOL exists = NO;
        for (NSDictionary *opt in options) {
            if ([opt[@"url"] isEqualToString:url]) { exists = YES; break; }
        }
        if (!exists) {
            [options addObject:@{
                @"label": @"标清",
                @"url": url,
            }];
        }
    }

    return options;
}

+ (NSArray<NSString *> *)imageURLsFromAweme:(AWEAwemeModel *)aweme {
    NSMutableArray *urls = [NSMutableArray array];
    if (aweme.albumImages.count > 0) {
        for (AWEAlbumImageModel *img in aweme.albumImages) {
            if (img.urlList.count > 0) {
                // 取第一个非 .image 后缀的 URL（通常是原图）
                NSString *bestURL = img.urlList.firstObject;
                for (NSString *u in img.urlList) {
                    if (![[u.pathExtension lowercaseString] isEqualToString:@"image"]) {
                        bestURL = u;
                        break;
                    }
                }
                if (bestURL && ![urls containsObject:bestURL]) {
                    [urls addObject:bestURL];
                }
            }
        }
    }
    return urls;
}

+ (NSString *)currentImageURLFromAweme:(AWEAwemeModel *)aweme {
    if (aweme.albumImages.count == 0) return nil;

    NSInteger index = aweme.currentImageIndex;
    if (index < 0 || index >= aweme.albumImages.count) {
        index = 0;
    }

    AWEAlbumImageModel *img = aweme.albumImages[index];
    if (img.urlList.count > 0) {
        for (NSString *u in img.urlList) {
            if (![[u.pathExtension lowercaseString] isEqualToString:@"image"]) {
                return u;
            }
        }
        return img.urlList.firstObject;
    }
    return nil;
}

+ (NSString *)audioURLFromAweme:(AWEAwemeModel *)aweme {
    AWEMusicModel *music = aweme.music;
    if (music && music.playURL.originURLList.count > 0) {
        return music.playURL.originURLList.firstObject;
    }
    return nil;
}

+ (BOOL)isLivePhoto:(AWEAwemeModel *)aweme {
    return aweme.awemeType == 68 || aweme.animatedImageVideoInfo != nil;
}

+ (BOOL)isAlbum:(AWEAwemeModel *)aweme {
    return aweme.albumImages.count > 0;
}

#pragma mark - 下载方法

+ (void)downloadMediaFromURL:(NSString *)urlString
                     mediaType:(TMDMediaType)mediaType
                      progress:(void (^)(float))progressBlock
                    completion:(void (^)(BOOL, NSURL * _Nullable))completion {
    if (!urlString || urlString.length == 0) {
        if (completion) completion(NO, nil);
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) completion(NO, nil);
        return;
    }

    NSString *ext = mediaType == TMDMediaTypeVideo ? @"mp4" :
                    mediaType == TMDMediaTypeImage ? @"jpg" : @"mp3";
    NSString *fileName = [NSString stringWithFormat:@"tmd_%f.%@", [[NSDate date] timeIntervalSince1970], ext];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSURL *destURL = [NSURL fileURLWithPath:tempPath];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:downloadQueue];

    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error || !location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, nil);
            });
            return;
        }

        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtURL:destURL error:nil];
        NSError *moveError = nil;
        [fm moveItemAtURL:location toURL:destURL error:&moveError];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (moveError) {
                if (completion) completion(NO, nil);
            } else {
                if (completion) completion(YES, destURL);
            }
        });
    }];

    // 进度观察
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    [task resume];
}

+ (void)downloadVideoFromURL:(NSString *)videoURL
                     audioURL:(NSString *)audioURL
                     progress:(void (^)(float))progressBlock
                   completion:(void (^)(BOOL, NSURL * _Nullable))completion {
    // 先下载视频
    [self downloadMediaFromURL:videoURL mediaType:TMDMediaTypeVideo progress:^(float p) {
        if (progressBlock) progressBlock(p * 0.7);
    } completion:^(BOOL success, NSURL *videoFileURL) {
        if (!success || !videoFileURL) {
            if (completion) completion(NO, nil);
            return;
        }

        // 如果没有音频，直接返回视频
        if (!audioURL || audioURL.length == 0) {
            if (completion) completion(YES, videoFileURL);
            return;
        }

        // 下载音频并合并
        [self downloadMediaFromURL:audioURL mediaType:TMDMediaTypeAudio progress:^(float p) {
            if (progressBlock) progressBlock(0.7 + p * 0.3);
        } completion:^(BOOL audioSuccess, NSURL *audioFileURL) {
            if (!audioSuccess || !audioFileURL) {
                // 音频下载失败，只用视频
                if (completion) completion(YES, videoFileURL);
                return;
            }

            // 合并音视频
            [self mergeVideo:videoFileURL audio:audioFileURL completion:^(BOOL mergeSuccess, NSURL *mergedURL) {
                if (mergeSuccess && mergedURL) {
                    if (completion) completion(YES, mergedURL);
                } else {
                    if (completion) completion(YES, videoFileURL);
                }
            }];
        }];
    }];
}

+ (void)mergeVideo:(NSURL *)videoURL audio:(NSURL *)audioURL completion:(void (^)(BOOL, NSURL *))completion {
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
    AVURLAsset *audioAsset = [AVURLAsset assetWithURL:audioURL];

    AVMutableComposition *composition = [AVMutableComposition composition];

    // 视频轨道
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (sourceVideoTrack) {
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:sourceVideoTrack atTime:kCMTimeZero error:nil];
    }

    // 音频轨道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (sourceAudioTrack) {
        CMTimeRange audioRange = CMTimeRangeMake(kCMTimeZero, CMTimeMinimum(audioAsset.duration, videoAsset.duration));
        [audioTrack insertTimeRange:audioRange ofTrack:sourceAudioTrack atTime:kCMTimeZero error:nil];
    }

    // 导出
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmd_merged_%f.mp4", [[NSDate date] timeIntervalSince1970]]];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;

    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                if (completion) completion(YES, outputURL);
            } else {
                if (completion) completion(NO, nil);
            }
        });
    }];
}

#pragma mark - 保存方法

+ (void)saveVideoToAlbum:(NSURL *)videoURL completion:(void (^)(BOOL))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO);
            });
            return;
        }

        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(success);
            });
        }];
    }];
}

+ (void)saveImageToAlbum:(NSURL *)imageURL completion:(void (^)(BOOL))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO);
            });
            return;
        }

        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage *image = [UIImage imageWithData:imageData];
        if (!image) {
            if (completion) completion(NO);
            return;
        }

        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(success);
            });
        }];
    }];
}

+ (void)saveLivePhotoWithImageURL:(NSURL *)imageURL videoURL:(NSURL *)videoURL completion:(void (^)(BOOL))completion {
    // 简化版：分别保存图片和视频
    [self saveImageToAlbum:imageURL completion:^(BOOL imgSuccess) {
        [self saveVideoToAlbum:videoURL completion:^(BOOL vidSuccess) {
            if (completion) completion(imgSuccess || vidSuccess);
        }];
    }];
}

+ (void)cancelAllDownloads {
    [downloadQueue cancelAllOperations];
}

@end
