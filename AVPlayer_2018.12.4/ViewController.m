//
//  ViewController.m
//  AVPlayer_2018.12.4
//
//  Created by Geraint on 2018/12/4.
//  Copyright © 2018 kilolumen. All rights reserved.
//

// 源码：https://github.com/liuxinixn/LXAVPlayerDemo

#import "ViewController.h"
#import "PlayerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LxButton *button = [LxButton LXButtonWithTitle:@"点我" titleFont:[UIFont systemFontOfSize:17.0] Image:nil backgroundImage:nil backgroundColor:[UIColor redColor] titleColor:[UIColor blackColor] frame:CGRectMake(50, 100, 150, 50)];
    
    [self.view addSubview:button];
    __weak ViewController *weakSelf = self;
    [button addClickBlock:^(UIButton *button) {
        
        // push 到PlayerViewController
        [weakSelf.navigationController pushViewController:[[PlayerViewController alloc] init] animated:YES];
    }];
    
}

// 返回竖屏格式
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait; // 视频控制器支持纵向接口方向
}



@end
