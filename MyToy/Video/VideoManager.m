//
//  VideoManager.m
//  MyToy
//
//  Created by dym on 2017/12/5.
//  Copyright © 2017年 dym. All rights reserved.
//

#import "VideoManager.h"
#import <ftw.h>

@implementation VideoManager
/*
 转换格式
 /Users/dym/Desktop/17998454.flv :来源
 /Users/dym/Desktop/2.mp4        : 转换后文件夹
 system :在iOS11 已经不能使用了
 */
- (void)changeVideoFormat{
    NSString * shell1 = [NSString stringWithFormat:@"ffmpeg -i /Users/dym/Desktop/17998454.flv -b:v 3.6MB /Users/dym/Desktop/2.mp4"];
    // 完全不知道这句话对不对，等于说是调用命令行
    ftw([shell1 cStringUsingEncoding:NSUTF8StringEncoding], nil, 1);
//    system([shell1 cStringUsingEncoding:NSUTF8StringEncoding]);
}
@end
