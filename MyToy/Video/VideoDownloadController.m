//
//  VideoDownloadController.m
//  MyToy
//
//  Created by dym on 2017/12/5.
//  Copyright © 2017年 dym. All rights reserved.
//

#import "VideoDownloadController.h"
#import "AFNetworking.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

// 合并视频的地址
#define DownloadPath @"/Users/dym/Desktop/Video/快手/二次元-224950410/2017-9-1  Video"

//合并视频的个数
#define margeVideoNumber (10)

@interface VideoDownloadController ()<UIImagePickerControllerDelegate>
{
    AFURLSessionManager * _manager;
    NSString *_downPath; //下载路径
    NSArray *_downVideoList;  //下载的视频列表
    int _index; //合并视频索引
}

@end

@implementation VideoDownloadController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置屏幕常亮
    [ [ UIApplication sharedApplication] setIdleTimerDisabled:YES ] ;
    
    [self removeDocumentFinoler];
    
    //    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    //    NSString *path = [document stringByAppendingPathComponent:@"downVideo"];
    [self margeVideo:DownloadPath];
    
    _index = 0;
}

#pragma mark --  开始下载视频
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
        NSMutableArray *jsonArray = [NSMutableArray array];
        for (int i = 1 ; i < 50; i++) {
            NSString *path = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"%d.json",i] ofType:@""];
            if (!path) break;
            NSData *data = [NSData dataWithContentsOfFile:path];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSArray *jsons = dict[@"feeds"];
            for (NSDictionary *dict1 in jsons) {
                NSArray *array1 = dict1[@"main_mv_urls"];
                if (array1.count > 1) {
                    NSDictionary *dict2 = array1[0];
                    NSString *url = dict2[@"url"];
                    [jsonArray addObject:url];
                }
            }
        }
    
        NSMutableArray *categoryArray = [[NSMutableArray alloc] init];
        for (unsigned i = 0; i < [jsonArray count]; i++){
            if ([categoryArray containsObject:[jsonArray objectAtIndex:i]] == NO){
                [categoryArray addObject:[jsonArray objectAtIndex:i]];
            }
    
        }
        NSString *path = [self getVideoPath:@"downVideo"];
        _downPath = path;
    
        dispatch_queue_t queue = dispatch_queue_create("com.lai.www", DISPATCH_QUEUE_CONCURRENT);
        for (int i = 0; i < categoryArray.count; i++) {
            dispatch_async(queue, ^{
                [self downLoad:categoryArray[i]];
            });
            sleep(15);
            NSLog(@"当前下载进度：%d ---当前总的视频量：%ld",i,categoryArray.count);
            if (i == categoryArray.count - 1) {
                [self clickSaveBtn:_downPath];
            }
        }
}

//下载视频
- (void)downLoad:(NSString*)url{
    NSURLSessionConfiguration * configuration = [ NSURLSessionConfiguration  defaultSessionConfiguration ];
    _manager = [[AFURLSessionManager alloc ] initWithSessionConfiguration: configuration];
    
    NSURL * URL = [ NSURL  URLWithString:url];
    NSURLRequest * request = [ NSURLRequest  requestWithURL: URL];
    
    NSURLSessionDownloadTask * downloadTask = [_manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSURL *documentsDirectoryURL = [[NSURL alloc]initFileURLWithPath:_downPath];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"全部视频下载完成：\n%@ ---\n error:%@",filePath,error);
        
    }];
    [downloadTask resume ];
    
}

//保存视频到相册
- (void)clickSaveBtn:(NSString*)filePath{
    // 获取沙盒里面的视频内容
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *fileList = [manager contentsOfDirectoryAtPath:filePath error:nil];
    NSLog(@"所有视频文件%@  ----",fileList);
    NSMutableArray *mp4s = [NSMutableArray array];
    for (NSString *name in fileList) {
        if ([name hasSuffix:@".mp4"]) {
            [mp4s addObject:[filePath stringByAppendingPathComponent:name]];
        }
    }
    
    for (int i = 0; i < mp4s.count; i++) {
        NSString *path = mp4s[i];
        NSLog(@" -- %@",path);
        NSURL *url = [NSURL fileURLWithPath:path];
        
        [self saveVideoToAssetsLibrary:url];
        sleep(5);
        
    }
}

- (void)saveVideoToAssetsLibrary:(NSURL *)url {
        ALAssetsLibrary *libraty = [[ALAssetsLibrary alloc]init];
    if ([libraty videoAtPathIsCompatibleWithSavedPhotosAlbum:url]) {
        
        ALAssetsLibraryWriteImageCompletionBlock completionBlock;
        completionBlock = ^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"%@",[error localizedDescription]);
            }else {
                //根据视频流第一帧图片生成一张展示图
                //                [self generateIamgeForViodeWithURL:url];
            }
        };
        
        [libraty writeVideoAtPathToSavedPhotosAlbum:url completionBlock:completionBlock];
        NSLog(@"保存方法");
    }
}

#pragma mark --  获取视频列表数组
- (void)margeVideo:(NSString*)filePath{
    // 获取沙盒里面的视频内容
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *fileList = [manager contentsOfDirectoryAtPath:filePath error:nil];
    NSLog(@"所有视频文件%@  ----",fileList);
    NSMutableArray *mp4s = [NSMutableArray array];
    for (NSString *name in fileList) {
        if ([name hasSuffix:@".mp4"]) {
            [mp4s addObject:[filePath stringByAppendingPathComponent:name]];
        }
    }
    NSMutableArray *array = [NSMutableArray array];
    NSUInteger itensRemaining = mp4s.count;
    int j = 0;
    while (itensRemaining) {
        NSRange range = NSMakeRange(j, MIN(margeVideoNumber, itensRemaining));
        NSArray *sublogArr = [mp4s subarrayWithRange:range];
        [array addObject:sublogArr];
        itensRemaining -= range.length;
        j += range.length;
    }
    
    _downVideoList = array;
    
    [self morgeMoreVideo];
}

#pragma mark -- 合并视频完成
- (void)morgeMoreVideo{
    if (_index == _downVideoList.count) {
        NSLog(@" --------- 全部视频合并完成 ----------  ");
        return;
    }
    [self beginMargeVideo:_downVideoList[_index]];
    _index++;
}

#pragma mark -- 合并没有声音的视频
- (void)addNOAudioVideo:(NSArray*)array{
    //合并视频后的路径
    NSString *path = [self getVideoPath:@"margeVideo"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTime totalDuration = kCMTimeZero;
        
        for (int i = 0; i < array.count; i++) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:array[i]]];
            
            NSError *errorVideo = nil;
            AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
            
            //视频
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:assetVideoTrack
                                 atTime:totalDuration
                                  error:&errorVideo];
            
            //        NSLog(@"errorVideo:%@%d",errorVideo,bl);
            totalDuration = CMTimeAdd(totalDuration, asset.duration);
            
            videoComposition.frameDuration = CMTimeMake(1, 30);
            //视频输出尺寸
            videoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
            
            AVMutableVideoCompositionInstruction * avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            
            [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [mixComposition duration])];
            
            AVMutableVideoCompositionLayerInstruction * avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
            
            [avMutableVideoCompositionLayerInstruction setTransform:assetVideoTrack.preferredTransform atTime:kCMTimeZero];
            
            avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
            
            videoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
            
        }
        
        NSURL *merageFileURL = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.mp4",_index + 1]]];
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
        exporter.outputURL = merageFileURL;
        exporter.videoComposition = videoComposition;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"exporter Unknow");
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"exporter Canceled");
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"exporter Failed");
                    break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"exporter Waiting");
                    break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"exporter Exporting");
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"exporter Completed");
                    [self morgeMoreVideo];
                    break;
            }
        }];
        
    });
}

#pragma mark --  合并有声音的视频
- (void)beginMargeVideo:(NSArray*)array{
    
    //合并视频后的路径
    NSString *path = [self getVideoPath:@"margeVideo"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime totalDuration = kCMTimeZero;
        for (int i = 0; i < array.count; i++) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:array[i]]];
            NSError *erroraudio = nil;//获取AVAsset中的音频 或者视频
            AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//向通道内加入音频或者视频
            
            //音频
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:assetAudioTrack
                                 atTime:totalDuration
                                  error:&erroraudio];
            
            //        NSLog(@"erroraudio:%@%d",erroraudio,ba);
            NSError *errorVideo = nil;
            AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
            
            //视频
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:assetVideoTrack
                                 atTime:totalDuration
                                  error:&errorVideo];
            
            //        NSLog(@"errorVideo:%@%d",errorVideo,bl);
            totalDuration = CMTimeAdd(totalDuration, asset.duration);
            
            videoComposition.frameDuration = CMTimeMake(1, 30);
            //视频输出尺寸
            videoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
            
            
            AVMutableVideoCompositionInstruction * avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            
            [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [mixComposition duration])];
            
            AVMutableVideoCompositionLayerInstruction * avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetAudioTrack];
            
            
            [avMutableVideoCompositionLayerInstruction setTransform:assetVideoTrack.preferredTransform atTime:kCMTimeZero];
            
            avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
            
            videoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
            
        }
        
        NSURL *merageFileURL = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.mp4",_index + 1]]];
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
        exporter.outputURL = merageFileURL;
        exporter.videoComposition = videoComposition;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"exporter Unknow");
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"exporter Canceled");
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"exporter Failed");
                    break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"exporter Waiting");
                    break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"exporter Exporting");
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"exporter Completed");
                    [self morgeMoreVideo];
                    break;
            }
        }];
        
    });
}

/*
 
 folderName: 文件夹名称
 */
- (NSString*)getVideoPath:(NSString*)folderName{
    //合并后的路径
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [document stringByAppendingPathComponent:folderName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断是否有文件夹
    //    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:path];
    //    if (blHave) {
    //        [fileManager removeItemAtPath:path error:nil];
    //    }
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    NSLog(@"沙盒文件路径 -- %@",path);
    return path;
}

#pragma mark --   移除document文件夹所有内容
- (void)removeDocumentFinoler{
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:document error:nil];
    NSMutableArray *array = [fileList copy];
    for (NSString *path in array) {
        [fileManager removeItemAtPath:path error:nil];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
