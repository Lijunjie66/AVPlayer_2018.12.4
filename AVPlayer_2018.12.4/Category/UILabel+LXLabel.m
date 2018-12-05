//
//  UILabel+LXLabel.m
//  XinkangPatient
//
//  Created by Geraint on 2018/12/3.
//  Copyright © 2018 kilolumen. All rights reserved.
//

#import "UILabel+LXLabel.h"

@implementation UILabel (LXLabel)

+ (UILabel *)LXLabelWithText:(NSString *)text
                   textColor:(UIColor *)textColor
             backgroundColor:(UIColor *)backgroundColor
                       frame:(CGRect)frame
                        font:(UIFont *)font
               textAlignment:(NSTextAlignment)textAlignment {
    
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = textAlignment;
    label.text = text;
    label.textColor = textColor;
    label.backgroundColor = backgroundColor;
    label.frame = frame;
    label.font = font;
    
    return label;
}

@end
