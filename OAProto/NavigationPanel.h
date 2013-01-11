//
//  NavigationPanel.h
//  OAProto
//
//  Created by Ivan Touzeau on 17/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//
//  NavigationPanel is the top panel that allows to browse pages.
//  Shadows are simple PNGs with black gradient ( for performance ) 

#import <UIKit/UIKit.h>

@interface NavigationPanel : UIView


@property (nonatomic,assign)       CALayer * topShadow;
@property (nonatomic,assign)       CALayer * bottomShadow;

@end
