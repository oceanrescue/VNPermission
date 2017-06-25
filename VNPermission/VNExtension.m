//
//  VNExtension.m
//  VNPermission
//
//  Created by Valery Nikitin on 23/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#import "VNExtension.h"

@implementation UIColor (vnp_extension)

-(UIColor *)inverse {
    CGFloat r=0., g=0., b=0., a=0.;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
    }
    return self;
}

@end
