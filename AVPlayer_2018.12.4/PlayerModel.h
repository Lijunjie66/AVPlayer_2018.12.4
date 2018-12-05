//
//  PlayerModel.h
//  AVPlayer_2018.12.4
//
//  Created by Geraint on 2018/12/4.
//  Copyright © 2018 kilolumen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PlayerModel : NSObject
/** 视频标题 */
@property (nonatomic, copy) NSString *videotitle;
/** 视频URL */
@property (nonatomic, copy) NSString *videoURL;
@end
