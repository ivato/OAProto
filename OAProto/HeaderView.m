//
//  HeaderView.m
//  FlowLayoutNoNIB
//
//  Created by Beau G. Bolle on 2012.10.29.
//
//

#import "HeaderView.h"

@implementation HeaderView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
        NSLog(@"HeaderView initWithFrame %@",NSStringFromCGRect(frame));
	}
	return self;
}

@end
