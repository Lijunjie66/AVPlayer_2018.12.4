//
//  ControlView.h
//  AVPlayer_2018.12.4
//
//  Created by Geraint on 2018/12/4.
//  Copyright © 2018 kilolumen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerModel.h"

@protocol LiControlViewDelegate <NSObject>
- (void)dismissVC;
- (void)playEnd;
@end

@interface ControlView : UIView

@property (nonatomic, assign) id<LiControlViewDelegate>delegate;

- (instancetype)initWithFrame:(CGRect)frame videoModelArray:(NSArray *)videoModelArray;

@end
