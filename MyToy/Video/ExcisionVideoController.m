//
//  ExcisionVideoController.m
//  MyToy
//
//  Created by dym on 2017/12/5.
//  Copyright © 2017年 dym. All rights reserved.
//

#import "ExcisionVideoController.h"
#import <AVFoundation/AVFoundation.h>

//输出文件夹路径
static NSString *outPath = @"/Users/dym/Desktop/";
// 视频路径
static NSString *path = @"/Users/dym/Desktop/";

@interface ExcisionVideoController ()
{
    int _index; //数据索引
    double _startTime; //开始时间
    double _lengTime; //截取的时间长度，秒为单位
}
@end

@implementation ExcisionVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"1.mp4" ofType:@""];
    
    _index = 1;
    _lengTime = 10.0;
    _startTime = 0.0;
    
    AVAsset *seet = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:seet];
    if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality]) {
        [self changeVideoSecitonsWithAvseet:seet];
    }else{
        NSLog(@"没有视频数据");
    }
    
}

- (void)changeVideoSecitonsWithAvseet:(AVAsset*)seet{
    double length = _startTime + _lengTime;
    BOOL isOver = NO;
    if (_startTime + _lengTime > floor(seet.duration.value / seet.duration.timescale)){
        length = floor(seet.duration.value / seet.duration.timescale) - (_startTime -  floor(seet.duration.value / seet.duration.timescale));
        isOver = YES;
    }
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:seet presetName:AVAssetExportPresetLowQuality];
    
    exportSession.outputURL = [NSURL  fileURLWithPath:[outPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.mp4",_index]]];
    [self removePath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.mp4",_index]]];
    
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    CMTime start= CMTimeMakeWithSeconds(_startTime, 600);
    CMTime duration = CMTimeMakeWithSeconds(length, 600);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exportSession.timeRange = range;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
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
                _startTime += _lengTime;
                if (isOver) {
                    NSLog(@" ---  视频裁剪完成  ---");
                    return;
                }
                _index++;
                [self changeVideoSecitonsWithAvseet:seet];
                break;
        }
    }];
}


// 获取路径
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

//移除文件
- (void)removePath:(NSString*)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:path];
    if (blHave) {
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
