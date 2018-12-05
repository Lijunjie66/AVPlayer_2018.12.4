//
//  ControlView.m
//  AVPlayer_2018.12.4
//
//  Created by Geraint on 2018/12/4.
//  Copyright © 2018 kilolumen. All rights reserved.
//



#import "ControlView.h"


#define Font(CGFloat) [UIFont systemFontOfSize:(CGFloat)]
#define LXCommonViewH 60
#define ProgressH 4         // 进度
#define DragSpeed 300       // 拖动速度
#define DelaySeconds 4      // 延迟 秒
#define playBtnH 32

// 播放器的几种状态 (创建类族)
typedef NS_ENUM(NSInteger, LIPlayerState)
{
    LIPlayerStateFailed,        // 播放失败
    LIPlayerStateBuffering,     // 缓冲中
    LIPlayerStatePlaying,       // 播放中
    LIPlayerStateStopping,      // 停止播放
    LIPlayerStatePause          // 暂停播放
};
typedef NS_ENUM(NSInteger, ViewTapState)
{
    viewTapShow,        // 显示
    ViewTapHide         // 隐藏
};

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection)
{
    PanDirectionHorizontalMoved,    // 水平移动
    PanDirectionVerticalMoved       // 垂直移动
};

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
@interface ControlView ()<UIGestureRecognizerDelegate>
/** 顶部视图 */
@property (nonatomic, strong) UIView *topView;              // 停止播放时的view
@property (nonatomic, strong) LxButton *backBtn;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) LxButton *startBtn;
@property (nonatomic, strong) LxButton *gotoNextVideo;      // 下一集
@property (nonatomic, assign) NSInteger playIndex;
@property (nonatomic, strong) NSArray *videoModelArray;

/** 底部视图 */
@property (nonatomic, strong) UIView *downView;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *gangLabel;           // 斜杠label
@property (nonatomic, strong) UILabel *sumTimeLabel;
@property (nonatomic, strong) UIView *progressView;         // 播放进度
@property (nonatomic, strong) UIView *progressCache;        // 缓冲进度
@property (nonatomic, strong) UIView *progressShadow;       // 进度阴影
@property (nonatomic, strong) UIView *progressContainer;    // 进度条 容器
@property (nonatomic, strong) UIImageView *progressBar;     // 进度按钮
@property (nonatomic, strong) UISlider *volumeSlider;       // 接受系统音量
@property (nonatomic, strong) UISlider *volume;             // 展示系统音量的
@property (nonatomic, strong) LxButton *fullScreenBtn;      // 全屏按钮
@property (nonatomic, strong) UIPanGestureRecognizer *barPan; // 平移手势
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UIPanGestureRecognizer *viewPan;

/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL isPauseByUser;   // 暂停
@property (nonatomic, assign) BOOL isDragged;       // 平移手势 正在拖动
@property (nonatomic, assign) BOOL isFullScreen;    // 全屏

/** 播放器的几种状态 */
@property (nonatomic, assign) LIPlayerState state;  // 类族
/** 定时观察者 */
@property (nonatomic, strong) id timeObserve;

/** 播放器层 */
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, assign) ViewTapState viewTapstate;

/** 暂停动画 */
@property (nonatomic, strong) UIImageView *animationView;
/** 从xx秒开始播放视频 */
@property (nonatomic, assign) NSInteger seekTime;
/** 字符串属性 */
@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, copy) NSString *videoTitle;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection panDirection;
@property (nonatomic, assign) BOOL enterPlayground;

@end

@implementation ControlView
{
    CGFloat viewWidth;
    CGFloat viewHeight;
    CGFloat progressY;
    CGFloat progressBarSize;
    CGFloat timeX;
    CGFloat timeY;
    CGFloat sumTime;
    CGFloat oldVolume;      // 记录上次音量
}
// 【最后】实现这个方法
- (void)dealloc {
    NSLog(@"%@释放了", self.class);
}

- (instancetype)initWithFrame:(CGRect)frame videoModelArray:(NSArray *)videoModelArray {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.frame = frame;
        self.playIndex = 0;
        self.videoModelArray = videoModelArray;
        PlayerModel *model = self.videoModelArray[self.playIndex];
        self.videoUrl = model.videoURL;
        self.videoTitle = model.videotitle;
        viewWidth = self.frame.size.width;
        viewHeight = self.frame.size.height;
        progressBarSize = 15;
        progressY = (40 - ProgressH) / 2;
        _viewTapstate = viewTapShow;
        
        [self setUpUI];
        // 调用 创建播放器对象 的方法
        [self configPlayer];
        
    }
    return self;
}

- (void)setUpUI {
    
    // 顶部视图
    [self addSubview:self.topView];
    [self.topView addSubview:self.backBtn];
    [self.topView addSubview:self.titleLabel];
    
    // 底部视图
    [self addSubview:self.downView];
    [self.downView addSubview:self.startBtn];
    [self.downView addSubview:self.gotoNextVideo];
    [self.downView addSubview:self.progressContainer];
    
    [self.progressContainer addSubview:self.progressShadow];
    [self.progressContainer addSubview:self.progressCache];
    [self.progressContainer addSubview:self.progressView];
    
    [self.progressContainer addSubview:self.progressBar];
    [self.downView addSubview:self.currentTimeLabel];
    [self.downView addSubview:self.gangLabel];
    [self.downView addSubview:self.sumTimeLabel];
    [self.downView addSubview:self.fullScreenBtn];
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.volume];
    [self addSubview:self.volumeSlider];
    
    [self addSubview:self.animationView];
    self.barPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(barPanAction:)];
    [self.progressContainer addGestureRecognizer:self.barPan];
    
    __weak ControlView *weakSelf = self;
    [_startBtn addClickBlock:^(UIButton *button) {
        button.selected = !button.selected;
        if (!button.selected) {
            [weakSelf videoPause];
            weakSelf.isPauseByUser = YES;
        } else {
            [weakSelf videoPlay];
            weakSelf.isPauseByUser = NO;
        }
    }];
    
    // 添加点击手势
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapAction:)];
    [self addGestureRecognizer:self.tap];
    [self performSelector:@selector(hideView) withObject:nil afterDelay:DelaySeconds];
    
}

- (void)fullScreenBtnAction:(LxButton *)fullScreenBtn {
    
    fullScreenBtn.selected = !fullScreenBtn.selected;
    self.isFullScreen = fullScreenBtn.selected;
    if (fullScreenBtn.selected) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            
            SEL selector = NSSelectorFromString(@"setOrientation:");
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:@selector(selector)]];
            
            [invocation setSelector:selector];
            
            [invocation setTarget:[UIDevice currentDevice]];
            
            int val = UIInterfaceOrientationLandscapeRight;
            
            [invocation setArgument:&val atIndex:2];
            
            [invocation invoke];
            
            
            // 设置 横屏
            self.frame = CGRectMake(0, 0, Device_Width, Device_Height);
            viewWidth = Device_Width;
            viewHeight = Device_Height;
            [self layoutSubviews];
        }
    } else {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            
            SEL selector = NSSelectorFromString(@"setOrientation:");
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:@selector(selector)]];
            
            [invocation setSelector:selector];
            
            [invocation setTarget:[UIDevice currentDevice]];
            
            int val = UIInterfaceOrientationPortrait;
            
            [invocation setArgument:&val atIndex:2];
            
            [invocation invoke];
            
            
            // 设置 横屏
            self.frame = CGRectMake(0, 0, Device_Width, Device_Height * 9 / 16);
            viewWidth = Device_Width;
            viewHeight = Device_Height * 9 / 16;
            [self layoutSubviews];
        }
    }
    
}

#pragma mark -- 点击隐藏或者显示
- (void)viewTapAction:(UITapGestureRecognizer *)tap {
    
    if (self.isPauseByUser) {
        
        self.topView.hidden = self.downView.hidden = self.volume.hidden = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideView) object:nil];
        return;
    }
    
    if (_viewTapstate == viewTapShow) {
        _viewTapstate = viewTapShow;
        
        self.topView.hidden = self.downView.hidden = self.volume.hidden = NO;
        
        [self performSelector:@selector(hideView) withObject:nil afterDelay:DelaySeconds];
        
    } else {
        _viewTapstate = viewTapShow;
        self.topView.hidden = self.downView.hidden = self.volume.hidden = YES;
    }
}

- (void)hideView {
    
    self.topView.hidden = self.downView.hidden = self.volume.hidden = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideView) object:nil];
}

// 创建播放器对象
- (void)configPlayer {
    
    self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.videoUrl]];
    // playerItem 添加观察者
    [self addNotifications];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    self.playerLayer.frame = self.bounds;
    
    // 初始化playerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    // 此处为默认视频填充模式
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    // 添加playerLayer到self.layer
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    
    
    // 添加播放进度计时器
    [self createTimer];
    // 开始播放
//    [self.player play];
    
    // 强制让系统调用layoutSubviews 的两个方法，必须同时写
    [self setNeedsLayout]; // 是标记 ，异步刷新 会调用，但是较慢
    [self layoutIfNeeded]; // 加上此代码 立刻刷新
    
}

- (void)createTimer {
    
    CGFloat _progressY = progressY;
    CGFloat _progressBarSize = progressBarSize;
    
    __weak typeof(self) weakSelf = self;
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time) {
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            NSInteger currentTime = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            CGFloat totalTime = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            CGFloat value = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            
            if (!weakSelf.isDragged) {
                
                weakSelf.currentTimeLabel.text = [ControlView durationStringWithTime:(NSInteger)currentTime];
                weakSelf.sumTimeLabel.text = [ControlView durationStringWithTime:(NSInteger)totalTime];
                CGFloat changeValur = value *CGRectGetWidth(weakSelf.progressContainer.frame);
                [UIView animateWithDuration:0.1 animations:^{
                    weakSelf.progressBar.frame = CGRectMake(changeValur - progressBarSize/2, _progressY - 5.5, _progressBarSize, _progressBarSize);
                    weakSelf.progressView.frame = CGRectMake(0, _progressY, changeValur, ProgressH);
                }];
            }
        }
    }];
    
}

#pragma mark -- 移除通知
- (void)removeObserverOrNotifiactions {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
}

- (void)videoPlay {
    self.animationView.hidden = YES;
    self.startBtn.selected = YES;  // 指示控件是否处在选定状态
    [self.player play];
    self.alpha = 1;
}

- (void)videoPause {
    self.animationView.hidden = NO;
    self.startBtn.selected = NO;
    [self.player pause];
    self.alpha = 0.5;
}

- (void)beginForPlay {
    [self videoPlay];
    self.progressContainer.userInteractionEnabled = YES;
    self.startBtn.userInteractionEnabled = YES;
    if (self.viewPan) {
        self.viewPan.enabled = YES;
    }
}

- (void)noEnableForPlay {
    [self videoPause];
    self.progressContainer.userInteractionEnabled = NO;
    self.startBtn.userInteractionEnabled = NO;
    if (self.viewPan) {
        self.viewPan.enabled = NO;
    }
}

#pragma mark -- KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:@"status"]) {
            
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                // 获取系统音量
                self.volume.value = self.volumeSlider.value;
                oldVolume = self.volume.value;
                self.state = LIPlayerStatePlaying;
                // 播放前的准备
                [self beginForPlay];
                // 加载完成后，再添加平移手势
                // 添加平移手势，用来控制音量、亮度、快进快推
                self.viewPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDirection:)];
                self.viewPan.delegate = self;
                [self.viewPan setMaximumNumberOfTouches:1];
                [self.viewPan setDelaysTouchesBegan:YES];
                [self.viewPan setDelaysTouchesEnded:YES];
                [self.viewPan setCancelsTouchesInView:YES];
                [self addGestureRecognizer:self.viewPan];
                
            } else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
                self.state = LIPlayerStateFailed;
            }
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            // 计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            CMTime duration = self.playerItem.duration;
            CGFloat totalDuration = CMTimeGetSeconds(duration);
            
            [UIView animateWithDuration:0.1 animations:^{
                // 更新当前缓存条
                self.progressCache.frame = CGRectMake(0, progressY, timeInterval * _progressContainer.frame.size.width / totalDuration, ProgressH);
            }];
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
            // 当缓冲是空的时候
            if (self.playerItem.playbackBufferEmpty) {
                self.state = LIPlayerStateBuffering;
                [self bufferingSomeSecond];
            }
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            // 当缓冲好的时候
            if (self.playerItem.playbackLikelyToKeepUp && self.state == LIPlayerStateBuffering) {
                self.state = LIPlayerStatePlaying;
            }
        }
    }
}

#pragma mark -- UIPanGestureRecognizer 手势方法
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    UIView *view = touch.view;
    if ([view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

/**
    Pan 手势事件
    @Param pan UIPanGestureRecognizer
 */
- (void)panDirection:(UIPanGestureRecognizer *)pan {
    
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.isDragged = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideView) object:nil];
        self.downView.hidden = self.topView.hidden = self.volume.hidden = NO;
        // 使用绝对值来判断移动的方向
        CGFloat x = fabs(veloctyPoint.x);
        CGFloat y = fabs(veloctyPoint.y);
        if (x > y) {
            // 给sumTime初值
            CMTime time = self.player.currentTime;
            sumTime = time.value / time.timescale;
            self.panDirection = PanDirectionHorizontalMoved;
        }
    }
    
    if (pan.state == UIGestureRecognizerStateChanged) {
        
        self.isDragged = YES;
        switch (self.panDirection) {
            case PanDirectionHorizontalMoved:
                // 每次滑动需要叠加时间
                sumTime += veloctyPoint.x / DragSpeed;
                // 需要限定sumTime的范围
                CMTime totalTime = self.playerItem.duration;
                CGFloat totalMovieDuration = (CGFloat)totalTime.value / totalTime.timescale;
                if (sumTime > totalMovieDuration) {sumTime = totalMovieDuration;}
                if (sumTime < 0) {sumTime = 0;}
                BOOL style = false;
                if (veloctyPoint.x > 0 ) {style = YES;}
                if (veloctyPoint.x < 0) {style = NO;}
                if (veloctyPoint.x == 0) {return;}
                
                CGFloat draggedValue = (CGFloat)sumTime / (CGFloat)totalMovieDuration;
                
                self.progressBar.frame = CGRectMake(draggedValue * CGRectGetWidth(self.progressContainer.frame) - progressBarSize/2, progressY - 5.5, progressBarSize, progressBarSize);
                
                self.progressView.frame = CGRectMake(0, progressY, draggedValue * CGRectGetWidth(self.progressContainer.frame), ProgressH);
                
                self.currentTimeLabel.text = [ControlView durationStringWithTime:(NSInteger)sumTime];
                self.sumTimeLabel.text = [ControlView durationStringWithTime:(NSInteger)totalMovieDuration];
                break;
            case PanDirectionVerticalMoved:
                break;
            default:
                break;
        }
        
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        // 设置时间
        [self seekToTime:sumTime completionHandler:nil];
    }
}

- (void)barPanAction:(UIPanGestureRecognizer *)pan {
    
    CGPoint touch = [pan locationInView:pan.view];
    if (touch.x <= 0) {
        touch.x = 0;
    }
    if (touch.x >= CGRectGetWidth(self.progressContainer.frame)) {
        touch.x = CGRectGetWidth(self.progressContainer.frame);
    }
    
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.isDragged = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideView) object:nil];
        self.downView.hidden = self.topView.hidden = self.volume.hidden = NO;
    }
    if (pan.state == UIGestureRecognizerStateChanged) {
        self.isDragged = YES;
        self.progressBar.frame = CGRectMake(touch.x - progressBarSize/2, progressY-5.5, progressBarSize, progressBarSize);
        self.progressView.frame = CGRectMake(0, progressY, touch.x, ProgressH);
        
        // 当前frame宽度 * 总时长 / 总frame长度 = 当前时间
        CGFloat duration = CMTimeGetSeconds([self.player.currentItem duration]);
        
        int time = touch.x * duration / CGRectGetWidth(self.progressContainer.frame);
        
        // 更新时间
        self.currentTimeLabel.text = [ControlView durationStringWithTime:(NSInteger)time];
        
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        
        // 当前frame宽度 * 总时长 / 总frame长度 = 当前时间
        CGFloat duration = CMTimeGetSeconds([self.player.currentItem duration]);
        
        int time = touch.x * duration / CGRectGetWidth(self.progressContainer.frame);
        
        // 设置时间
        [self seekToTime:time completionHandler:nil];
        
    }
    
}

/**
    从xx秒开始播放视频跳转
    @param dragedSeconds 视频跳转的秒数
 */
- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(nonnull void (^)(BOOL))completionHandler {
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        // 方法seekTime:completionHandler: 不能精准定位
        // 如果需要精准定位，可以使用seekToTime：toleranceBefore:toleranceAfter:completionHandler:
        // 转换成CMTime才能给player来控制播放进度
        
        [self videoPause];
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1); // kCMTimeZero
        __weak typeof(self) weakSelf = self;
        [self.player seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1, 1) toleranceAfter:CMTimeMake(1, 1) completionHandler:^(BOOL finished) {
            
            // 视频跳转回调
            if (completionHandler) {completionHandler(finished);}
            
            weakSelf.seekTime = 0;
            
            weakSelf.isDragged = NO;
            
            // 开始播放
            if (!weakSelf.isPauseByUser) {
                [weakSelf videoPlay];
            }
            
            if (!weakSelf.playerItem.isPlaybackLikelyToKeepUp) {weakSelf.state = LIPlayerStateBuffering;}
            
            weakSelf.downView.hidden = weakSelf.topView.hidden = weakSelf.volume.hidden = !weakSelf.isPauseByUser;
            sumTime = 0;
        }];
        
    }
}

#pragma mark -- 通知方法 与 观察者实现
- (void)moviePlayDidEnd:(NSNotification *)notification {
    
    [self resetLayer];
    if (++self.playIndex < self.videoModelArray.count) {
        
        ControlView *model = self.videoModelArray[self.playIndex];
        // 接受标题
        self.titleLabel.text = model.videoTitle;
        self.videoUrl = model.videoUrl;
        [self configPlayer];
        
    }
}

- (void)appDidEnterBackground {
    self.enterPlayground = NO;
    [_player pause];
}

- (void)appDidEnterPlayground {
    self.enterPlayground = YES;
    [_player play];
    if (self.isFullScreen) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            
            SEL selector = NSSelectorFromString(@"setOrientation:");
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            
            [invocation setSelector:selector];
            
            [invocation setTarget:[UIDevice currentDevice]];
            
            int val = UIInterfaceOrientationLandscapeRight;
            
            [invocation setArgument:&val atIndex:2];
            
            [invocation invoke];
        }
    }
    
}

#pragma mark -- 观察者、 通知
/**
    添加观察者、通知
 */
- (void)addNotifications {
    
    // app 退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification
                                               object:nil];
    // app 进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    // 检测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange:) name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    
    if (self.playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayDidEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:_playerItem];
        [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区空了，需要等待数据
        [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区有足够数据可以播放了
        [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        
    }
    // 监听系统音量
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
}

- (void)onDeviceOrientationChange:(NSNotification *)notification {
    
    UIDevice *device = notification.object;
    
    if (device.orientation == UIInterfaceOrientationUnknown || device.orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return;
    }
    if (device.orientation == UIInterfaceOrientationLandscapeRight) {
        self.frame = CGRectMake(0, 0, Device_Width, Device_Height);
        viewWidth = Device_Width;
        viewHeight = Device_Height;
        [self layoutSubviews];
        
    } else if (device.orientation == UIInterfaceOrientationPortrait) {
        // 设置竖屏
        self.frame = CGRectMake(0, 0, Device_Width, Device_Width *9 /16);
        viewWidth = Device_Width;
        viewHeight = Device_Width *9 /16;
        [self layoutSubviews];
    }
}

- (void)volumeChanged:(NSNotification *)volume {
    self.volume.value = [volume.userInfo[@"AVSystemController_SystemVolumeDidChangeNotification"] floatValue];
}

#pragma mark -- 清除信息
- (void)resetLayer {
    
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    
    // 移除通知
    [self removeObserverOrNotifiactions];
    self.playerItem = nil;
    
    // 暂停
    [self.player pause];
    // 移除原来的layer
    [self.playerLayer removeFromSuperlayer];
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    // 把player置为nil
    self.player = nil;
    // 其余控件恢复默认设置
//    self allUI
//
    
    self.alpha = 1;
}

/**
    缓冲较差时候回调这里
 */
- (void)bufferingSomeSecond {
    
    self.state = LIPlayerStateBuffering;
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前在调用bufferingSecondf都忽略
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候 时间在走，声音播放不出来
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            isBuffering = NO;
            return;
        }
        
        [self.player play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
    
}

#pragma mark -- 计算缓冲进度
/**
    计算缓冲进度
    @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds            = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds; // 计算缓冲总进度
    return result;
}

#pragma mark -- 其余控件回到默认位置
- (void)allUIBackOriginalInfo {
    self.progressBar.frame = CGRectMake(-progressBarSize/2, progressY - 5.5, progressBarSize, progressBarSize);
    self.progressView.frame = CGRectMake(0, progressY, 0, ProgressH);
    
    self.progressShadow.frame = CGRectMake(0, progressY, viewWidth - CGRectGetMaxX(self.gotoNextVideo.frame) - 200, ProgressH);
    self.progressCache.frame = CGRectMake(0, progressY, 0, ProgressH);
    self.currentTimeLabel.text = @"00:00";
    self.sumTimeLabel.text = @"00:00";
    self.titleLabel.text = @"";
    self.seekTime = 0;
    [self noEnableForPlay];
}

// 音量方法
- (void)volumeAction:(UISlider *)volume {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideView) object:nil];
    self.downView.hidden = self.topView.hidden = self.volume.hidden = NO;
    
    // 更改系统的音量
    self.volumeSlider.value = volume.value;
    oldVolume = volume.value;
    
}

#pragma mark -- 当前时间换算
+ (NSString *)durationStringWithTime:(NSInteger)time {
    
    // 获取 分
    NSString *m = [NSString stringWithFormat:@"%02ld", (long)(time/60)];
    // 获取 秒
    NSString *s = [NSString stringWithFormat:@"%02ld", (long)(time%60)];
    
    return [NSString stringWithFormat:@"%@:%@", m, s];
}

- (UIView *)topView {
    
    if (!_topView) {
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, LXCommonViewH)];
        _topView.backgroundColor = [UIColor blackColor];
    }
    return _topView;
}

- (UIView *)downView {
    
    if (!_downView) {
        _downView = [[UIView alloc] initWithFrame:CGRectMake(0, viewHeight - LXCommonViewH, viewWidth, LXCommonViewH)];
        _downView.backgroundColor = [UIColor blackColor];
    }
    return _downView;
}

- (LxButton *)backBtn {
    
    if (!_backBtn) {
        _backBtn = [LxButton LXButtonWithTitle:@"返回"
                                     titleFont:Font(16.0)
                                         Image:nil
                               backgroundImage:nil
                               backgroundColor:[UIColor blackColor]
                                    titleColor:[UIColor whiteColor]
                                         frame:CGRectMake(0, 10, 80, 40)];
        __weak ControlView *weakSelf = self;
        [_backBtn addClickBlock:^(UIButton *button) {
            [weakSelf resetLayer];
            [weakSelf.fullScreenBtn setSelected:NO];
            [weakSelf.delegate dismissVC];
            if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
                
                SEL  selector = NSSelectorFromString(@"setOrientation");
                
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
                
                [invocation setSelector:selector];
                
                [invocation setTarget:[UIDevice currentDevice]];
                
                int val = UIInterfaceOrientationPortrait;
                
                [invocation setArgument:&val atIndex:2];
                
                [invocation invoke];
            }
            
        }];
    }
    return _backBtn;
}

- (UILabel *)titleLabel {
    
    if (!_titleLabel) {
        _titleLabel = [UILabel LXLabelWithText:self.videoTitle
                                     textColor:[UIColor whiteColor]
                               backgroundColor:[UIColor blackColor]
                                         frame:CGRectMake(100, (LXCommonViewH - 40)/2, viewWidth - 200, 40)
                                          font:Font(16.0)
                                 textAlignment:NSTextAlignmentCenter];
    }
    return _titleLabel;
}

- (LxButton *)startBtn {
    
    if (!_startBtn) {
        _startBtn = [LxButton LXButtonWithTitle:nil
                                      titleFont:nil
                                          Image:[UIImage imageNamed:@"playBtn"]
                                backgroundImage:nil
                                backgroundColor:nil
                                     titleColor:nil
                                          frame:CGRectMake(10, (LXCommonViewH - playBtnH)/2, playBtnH, playBtnH)];
        [_startBtn setImage:[UIImage imageNamed:@"pasueBtn"] forState:UIControlStateSelected];
    }
    return _startBtn;
}

- (LxButton *)gotoNextVideo {
    
    if (!_gotoNextVideo) {
        _gotoNextVideo = [LxButton LXButtonWithTitle:nil
                                           titleFont:Font(16.0)
                                               Image:[UIImage imageNamed:@"nextVideo"]
                                     backgroundImage:nil
                                     backgroundColor:nil
                                          titleColor:nil
                                               frame:CGRectMake(CGRectGetMaxX(self.startBtn.frame) + 2, (LXCommonViewH - playBtnH)/2, playBtnH, playBtnH)];
        __weak ControlView *weakSelf = self;
        
        [_gotoNextVideo addClickBlock:^(UIButton *button) {
            [weakSelf resetLayer];
            if (++weakSelf.playIndex < weakSelf.videoModelArray.count) {
                
                PlayerModel *model = weakSelf.videoModelArray[weakSelf.playIndex];
                // 接受标题
                weakSelf.titleLabel.text = model.videotitle;
                weakSelf.videoUrl = model.videoURL;
                [weakSelf configPlayer];
            }
        }];
    }
    return _gotoNextVideo;
}

- (UIView *)progressContainer {
    
    if (!_progressContainer) {
        _progressContainer = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.gotoNextVideo.frame) + 10, (LXCommonViewH - 40)/2, viewWidth - CGRectGetMaxX(self.gotoNextVideo.frame) - 200, 40)];
    }
    return _progressContainer;
}

- (UIView *)progressShadow {
    
    if (!_progressShadow) {
        _progressShadow = [[UIView alloc] initWithFrame:CGRectMake(0, progressY, CGRectGetWidth(self.progressContainer.frame), ProgressH)];
        _progressShadow.backgroundColor = [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1.0];
    }
    return _progressShadow;
}

- (UIView *)progressView {
    
    if (!_progressView) {
        _progressView = [[UIView alloc] initWithFrame:CGRectMake(0, progressY, 0, ProgressH)];
        _progressView.backgroundColor = [UIColor colorWithRed:234/255.0 green:128/255.0 blue:16/255.0 alpha:1.0];
    }
    return _progressView;
}

- (UIView *)progressCache {
    
    if (!_progressCache) {
        _progressCache = [[UIView alloc] initWithFrame:CGRectMake(0, progressY, 0, ProgressH)];
        _progressCache.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1.0];
    }
    return _progressCache;
}

- (UIImageView *)progressBar {
    
    if (!_progressBar) {
        _progressBar = [[UIImageView alloc] initWithFrame:CGRectMake(-progressBarSize/2, progressY-5.5, progressBarSize, progressBarSize)];
        _progressBar.image = [UIImage imageNamed:@"progressVolume"];
        _progressBar.userInteractionEnabled = YES;
    }
    return _progressBar;
}

- (UILabel *)currentTimeLabel {
    
    if (!_currentTimeLabel) {
        timeX = CGRectGetMaxX(self.progressContainer.frame)+5;
        timeY = (LXCommonViewH - 20)/2;
        _currentTimeLabel = [UILabel LXLabelWithText:@"00:00"
                                           textColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1.0]
                                     backgroundColor:nil
                                               frame:CGRectMake(timeX, timeY, 60, 20)
                                                font:Font(16.0)
                                       textAlignment:NSTextAlignmentRight];
        _currentTimeLabel.backgroundColor = [UIColor clearColor];
    }
    return _currentTimeLabel;
}

- (UILabel *)gangLabel {
    
    if (!_gangLabel) {
        _gangLabel = [UILabel LXLabelWithText:@"/"
                                    textColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1.0]
                              backgroundColor:nil
                                        frame:CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame), timeY, 10, 20)
                                         font:Font(16.0)
                                textAlignment:NSTextAlignmentCenter];
        _gangLabel.backgroundColor = [UIColor clearColor];
    }
    return _gangLabel;
}

- (UILabel *)sumTimeLabel {
    
    if (!_sumTimeLabel) {
        _sumTimeLabel = [UILabel LXLabelWithText:@"00:00"
                                       textColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1.0]
                                 backgroundColor:nil
                                           frame:CGRectMake(CGRectGetMaxX(self.gangLabel.frame), timeY, 60, 20)
                                            font:Font(16.0)
                                   textAlignment:NSTextAlignmentLeft];
        _sumTimeLabel.backgroundColor = [UIColor clearColor];
    }
    return _sumTimeLabel;
}

- (UISlider *)volume {
    
    if (!_volume) {
        _volume = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, (viewHeight - LXCommonViewH *2) *2/3, 30)];
        self.volume.transform = CGAffineTransformMakeRotation(M_PI * 1.5);
        self.volume.center = CGPointMake(self.startBtn.center.x, viewHeight / 2);
        [self.volume setMinimumTrackTintColor:[UIColor colorWithRed:234/255.0 green:128/255.0 blue:16/255.0 alpha:1.0]];
        [self.volume addTarget:self action:@selector(volumeAction:) forControlEvents:UIControlEventValueChanged];
        [self.volume setThumbImage:[UIImage imageNamed:@"progressVolume"] forState:UIControlStateNormal];
    }
    return _volume;
}

- (LxButton *)fullScreenBtn {
    
    if (!_fullScreenBtn) {
        _fullScreenBtn = [LxButton LXButtonWithTitle:nil
                                           titleFont:nil
                                               Image:[UIImage imageNamed:@"全屏"]
                                     backgroundImage:nil
                                     backgroundColor:nil
                                          titleColor:nil
                                               frame:CGRectMake(CGRectGetMaxX(self.sumTimeLabel.frame), 14, 32, 32)];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"全屏"] forState:UIControlStateSelected];
    }
    return _fullScreenBtn;
}

- (UISlider *)volumeSlider {
    
    if (!_volumeSlider) {
        MPVolumeView *volumeXT = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, 0, 30, 30)];
        for (UIView *view in volumeXT.subviews) {
            if ([view isKindOfClass:[UISlider class]]) {
                // 接受系统音量
                _volumeSlider = (UISlider *)view;
                // 接受到控件之后，要给我们系统的控件赋一个初始值
                _volume.value = _volumeSlider.value;
            }
            _volumeSlider.hidden = YES;
        }
    }
    return _volumeSlider;
}

- (UIImageView *)animationView {
    
    if (!_animationView) {
        NSArray *Images = [NSArray arrayWithObjects:
                           [UIImage imageNamed:@"马上就来-1"],
                           [UIImage imageNamed:@"马上就来-2"],
                           [UIImage imageNamed:@"马上就来-3"],
                           [UIImage imageNamed:@"马上就来-4"],
                           [UIImage imageNamed:@"马上就来-5"],
                           [UIImage imageNamed:@"马上就来-6"],
                           [UIImage imageNamed:@"马上就来-7"],
                           [UIImage imageNamed:@"马上就来-8"],
                           [UIImage imageNamed:@"马上就来-9"],
                           nil];
        _animationView = [[UIImageView alloc] initWithFrame:CGRectMake((viewWidth - 240)/2, (viewHeight - 144)/2+30, 240, 144)];
        _animationView.animationImages = Images;
        _animationView.animationDuration = 1.0f;
        _animationView.animationRepeatCount = 0;
        [_animationView startAnimating];
        _animationView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.2];
    }
    return _animationView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
    _topView.frame = CGRectMake(0, 0, viewWidth, LXCommonViewH);
    _downView.frame = CGRectMake(0, viewHeight - LXCommonViewH, viewWidth, LXCommonViewH);
    _backBtn.frame = CGRectMake(0, 10, 80, 40);
    _titleLabel.frame = CGRectMake(100, (LXCommonViewH - 40)/2, viewWidth - 200, 40);
    _startBtn.frame = CGRectMake(10, (LXCommonViewH - playBtnH)/2, playBtnH, playBtnH);
    _gotoNextVideo.frame = CGRectMake(CGRectGetMaxX(self.startBtn.frame)+2, (LXCommonViewH - playBtnH)/2, playBtnH, playBtnH);
    _progressContainer.frame = CGRectMake(CGRectGetMaxX(self.gotoNextVideo.frame) + 10, (LXCommonViewH - 40)/2, viewWidth - CGRectGetMaxX(self.gotoNextVideo.frame) - 200, 40);
    _progressShadow.frame = CGRectMake(0, progressY, CGRectGetWidth(self.progressContainer.frame), ProgressH);
    
    _progressView.frame = CGRectMake(0, progressY, 0, ProgressH);
    _progressCache.frame = CGRectMake(0, progressY, 0, ProgressH);
    _progressBar.frame = CGRectMake(progressBarSize/2, progressY - 5.5, progressBarSize, progressBarSize);
    
    timeX = CGRectGetMaxX(self.progressContainer.frame)+5;
    timeY = (LXCommonViewH - 20)/2;
    
    _currentTimeLabel.frame = CGRectMake(timeX, timeY, 60, 20);
    _gangLabel.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame), timeY, 10, 20);
    _sumTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.gangLabel.frame), timeY, 60, 20);
    _volume.frame = CGRectMake(0, 0, 30, (viewHeight - LXCommonViewH *2)*2/3);
    self.volume.transform = CGAffineTransformMakeRotation(M_PI * 1.5);
    self.volume.center = CGPointMake(self.startBtn.center.x, viewHeight / 2);
    _fullScreenBtn.frame = CGRectMake(CGRectGetMaxX(self.sumTimeLabel.frame), 14, 32, 32);
    _animationView.frame = CGRectMake((viewWidth - 240) / 2, (viewHeight - 144) / 2 + 30, 240, 144);
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    [self layoutSubviews];
    
}

@end
