//
//  LxButton.m
//  XinkangPatient
//
//  Created by Geraint on 2018/12/3.
//  Copyright © 2018 kilolumen. All rights reserved.
//

#import "LxButton.h"

@implementation LxButton

+ (LxButton *)LXButtonWithTitle:(NSString *)title
                      titleFont:(UIFont *)titleLabelFont
                          Image:(UIImage *)image
                backgroundImage:(UIImage *)backgroundImage
                backgroundColor:(UIColor *)backgroundColor
                     titleColor:(UIColor *)titleLabelColor
                          frame:(CGRect)frame {
    
    LxButton *button = [LxButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleLabelColor forState:UIControlStateNormal];
    button.backgroundColor = backgroundColor;
    button.frame = frame;
    button.titleLabel.font = titleLabelFont;
    return button;
}

+ (LxButton *)LXButtonNoFrameWithTitle:(NSString *)title
                             titleFont:(UIFont *)titleLabelFont
                                 Image:(UIImage *)image
                       backgroundImage:(UIImage *)backgroundImage
                       backgroundColor:(UIColor *)backgroundColor
                            titleColor:(UIColor *)titleLabelColor {
    
    LxButton *button = [LxButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleLabelColor forState:UIControlStateNormal];
    button.backgroundColor = backgroundColor;
    button.titleLabel.font = titleLabelFont;
    return button;
}

- (void)addClickBlock:(ButtonBlock)block {
    _block = block;
    [self addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonAction:(UIButton *)button {
    _block(button);
}

-(void)setButtonID:(NSInteger)buttonID {
    _buttonID = buttonID;
    self.tag = buttonID;
}

@end
