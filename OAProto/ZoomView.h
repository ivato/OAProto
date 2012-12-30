//
//  ZoomView.h
//  OAProto
//
//  Created by Ivan Touzeau on 04/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OpenAnnotation;
#import "EditViewController.h"

@interface ZoomView : UIImageView

- (id)      initWithEditController:(EditViewController *)aController;

- (void)    updateZoom:(CGRect)rect;

- (void)    updateZoomForScrollView:(UIScrollView *)scrollView;

- (void) 	updateCompositeForNote:(OpenAnnotation *)note;

@end
