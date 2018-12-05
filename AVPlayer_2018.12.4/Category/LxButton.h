//
//  LxButton.h
//  XinkangPatient
//
//  Created by Geraint on 2018/12/3.
//  Copyright © 2018 kilolumen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ButtonBlock)(UIButton *button);

@interface LxButton : UIButton
@property (nonatomic, copy) ButtonBlock block;
@property (nonatomic, assign) NSInteger buttonID;
- (void)addClickBlock:(ButtonBlock)block;

+ (LxButton *)LXButtonWithTitle:(NSString *)title
                      titleFont:(UIFont *)titleLabelFont
                          Image:(UIImage *)image
                backgroundImage:(UIImage *)backgroundImage
                backgroundColor:(UIColor *)backgroundColor
                     titleColor:(UIColor *)titleLabelColor
                          frame:(CGRect)frame;

+ (LxButton *)LXButtonNoFrameWithTitle:(NSString *)title
                             titleFont:(UIFont *)titleLabelFont
                                 Image:(UIImage *)image
                       backgroundImage:(UIImage *)backgroundImage
                       backgroundColor:(UIColor *)backgroundColor
                            titleColor:(UIColor *)titleLabelColor;

@end
