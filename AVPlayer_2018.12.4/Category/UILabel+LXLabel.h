//
//  UILabel+LXLabel.h
//  XinkangPatient
//
//  Created by Geraint on 2018/12/3.
//  Copyright © 2018 kilolumen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (LXLabel)

+ (UILabel *)LXLabelWithText:(NSString *)text
                   textColor:(UIColor *)textColor
             backgroundColor:(UIColor *)backgroundColor
                       frame:(CGRect)frame
                        font:(UIFont *)font
               textAlignment:(NSTextAlignment)textAlignment;

@end
