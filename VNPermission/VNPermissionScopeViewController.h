//
//  VNPermissionScopeViewController.h
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#ifndef VNPermissionScopeViewController_h
#define VNPermissionScopeViewController_h

#import <UIKit/UIKit.h>
#import "VNPStructs.h"

@class VNPermissionScopeViewController;
@protocol VNPermissionScopeViewControllerDelegate <NSObject>

-(VNPermissionStatus)viewController:(VNPermissionScopeViewController*)viewController askPermissionStatus:(VNPermissionType)permissionType;

@optional
-(void)viewControllerWillCancel:(VNPermissionScopeViewController*)viewController;
-(void)viewController:(VNPermissionScopeViewController*)viewController requestPermission:(VNPermissionType)permissionType;

@end

@class VNPermissionScopeManager;
@interface VNPermissionScopeViewController : UIViewController

// MARK: UI Parameters

/// Header UILabel with the message "Hey, listen!" by default.
@property (nonatomic, weak) UILabel *headerLabel;
/// Header UILabel with the message "We need a couple things\r\nbefore you get started." by default.
@property (nonatomic, weak) UILabel *bodyLabel;

/// Color for the close button's text color.
@property (nonatomic, retain) UIColor *closeButtonTextColor;
/// Color for the permission buttons' text color.
@property (nonatomic, retain) UIColor *permissionButtonTextColor;
/// Color for the permission buttons' border color.
@property (nonatomic, retain) UIColor *permissionButtonBorderColor;
/// Width for the permission buttons.
@property (nonatomic) CGFloat permissionButtonBorderWidth;
/// Corner radius for the permission buttons.
@property (nonatomic) CGFloat permissionButtonCornerRadius;
/// Color for the permission labels' text color.
@property (nonatomic, retain) UIColor *permissionLabelColor;
/// Font used for all the UIButtons
@property (nonatomic, retain) UIFont *buttonFont;
/// Font used for all the UILabels
@property (nonatomic, retain) UIFont *labelFont;
/// Close button. By default in the top right corner.
@property (nonatomic, weak) UIButton *closeButton;
/// Offset used to position the Close button.
@property (nonatomic) CGSize closeOffset;
/// Color used for permission buttons with authorized status
@property (nonatomic, retain) UIColor *authorizedButtonColor;
/// Color used for permission buttons with unauthorized status. By default, inverse of `authorizedButtonColor`.
@property (nonatomic, retain) UIColor *unauthorizedButtonColor;
/// Messages for the body label of the dialog presented when requesting access.

// MARK: View hierarchy for custom alert
@property (nonatomic, weak) UIView *baseView;
@property (nonatomic, weak) UIView *contentView;

@property (nonatomic, weak) NSDictionary <NSNumber*, NSString*> * permissionMessages;

@property (nonatomic, weak) id <VNPermissionScopeViewControllerDelegate> delegate;


@end
#endif //VNPermissionScopeViewController_h
