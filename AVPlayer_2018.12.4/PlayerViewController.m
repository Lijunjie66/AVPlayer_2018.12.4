//
//  PlayerViewController.m
//  AVPlayer_2018.12.4
//
//  Created by Geraint on 2018/12/4.
//  Copyright © 2018 kilolumen. All rights reserved.
//

#import "PlayerViewController.h"
#import "ControlView.h"

@interface PlayerViewController ()<LiControlViewDelegate>
@property (nonatomic, strong) ControlView *controlView;
@end

static NSString *string = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";
//@"http://baobab.cdn.wandoujia.com/14464539635131446103741576t_x264.mp4"

@implementation PlayerViewController

- (void)dealloc {
    NSLog(@"%@😁", self.class);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:YES];
    NSMutableArray *array = [NSMutableArray array];
    PlayerModel *model = [[PlayerModel alloc] init];
    model.videotitle = @"啦啦啦😝";
    model.videoURL = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";
    [array addObject:model];
    
    
    PlayerModel *modelOne = [[PlayerModel alloc] init];
    modelOne.videotitle = @"哈哈哈😆";
    modelOne.videoURL = @"http://baobab.cdn.wandoujia.com/14464539635131446103741576t_x264.mp4";
    [array addObject:modelOne];
    
    self.controlView = [[ControlView alloc] initWithFrame:CGRectMake(0, 0, Device_Width, Device_Height *9/16) videoModelArray:array];
    self.controlView.delegate = self;
    [self.view addSubview:self.controlView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)playEnd {
    
}

// 只支持两个方向旋转
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
