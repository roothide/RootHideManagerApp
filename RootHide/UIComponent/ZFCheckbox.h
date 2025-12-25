//
//  ZFCheckbox.h
//  ZFCheckbox
//
//  Created by Amornchai Kanokpullwad on 30/03/2015.
//
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ZFCheckbox : UIControl

@property (nonatomic) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *lineBackgroundColor;
@property (nonatomic) CGFloat animateDuration;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

@end
