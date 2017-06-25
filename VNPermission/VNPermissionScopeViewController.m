//
//  VNPermissionScopeViewController.m
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#import "VNPermissionScopeViewController.h"
#import "VNPermissionScopeManager.h"
#import "VNPConstants.h"
#import "VNExtension.h"
#import "VNPermissionLocalization.h"

@import UIKit;
@import CoreLocation;
@import AddressBook;
@import AVFoundation;
@import Photos;
@import EventKit;
@import CoreBluetooth;
@import CoreMotion;
@import Contacts;

@interface VNPermissionScopeViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, retain) NSMutableArray *permissionButtons;
@property (nonatomic, retain) NSMutableArray *permissionLabels;
@end

@implementation VNPermissionScopeViewController
// MARK: - View life cycle
-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    // Set background frame
    self.view.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
    // Set frames
    CGFloat x = (screenSize.width - vnp_kContentWidth) / 2;
    
    CGFloat dialogHeight = 0;
    switch (self.permissionMessages.count) {
        case 2:
            dialogHeight = vnp_kDialogHeightTwoPermissions;
            break;
        case 3:
            dialogHeight = vnp_kDialogHeightThreePermissions;
            break;
        default:
            dialogHeight = vnp_kDialogHeightSinglePermission;
            break;
    }
    
    
    CGFloat y = (screenSize.height - dialogHeight) / 2;
    self.contentView.frame = CGRectMake(x, y, vnp_kContentWidth, dialogHeight);
    
    // offset the header from the content center, compensate for the content's offset
    self.headerLabel.center = self.contentView.center;
    CGRect frame = self.headerLabel.frame;
    frame.origin.x -= self.contentView.frame.origin.x;
    frame.origin.y -= self.contentView.frame.origin.y;
    frame.origin.y -= dialogHeight/2 - 50;
    self.headerLabel.frame = frame;
    
    // ... same with the body
    self.bodyLabel.center = self.contentView.center;
    frame = self.bodyLabel.frame;
    frame.origin.x -= self.contentView.frame.origin.x;
    frame.origin.y -= self.contentView.frame.origin.y;
    frame.origin.y -= dialogHeight/2 - 100;
    self.bodyLabel.frame = frame;
    
    
    self.closeButton.center = self.contentView.center;
    frame = self.closeButton.frame;
    frame = CGRectOffset(frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
    frame = CGRectOffset(frame, 105, -(dialogHeight/2 - 20.));
    frame = CGRectOffset(frame, -self.closeOffset.width, -self.closeOffset.height);
    self.closeButton.frame = frame;
    
    if (self.closeButton.imageView.image) {
        [self.closeButton setTitle:@"" forState:UIControlStateNormal];
    }
    
    [self.closeButton setTitleColor:self.closeButtonTextColor forState:UIControlStateNormal];
    
    CGFloat baseOffset = 95.f;
    
#if DEBUG
    NSAssert(self.permissionButtons.count == self.permissionLabels.count, @"Wrong internal parameters");
#endif
    for (NSUInteger index=0; index < self.permissionButtons.count; index ++) {
        UIButton *button = self.permissionButtons[index];
        button.center = self.contentView.center;
        frame = button.frame;
        frame = CGRectOffset(frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
        frame = CGRectOffset(frame, 0, -(dialogHeight/2 - 160) + (CGFloat)(index *baseOffset));
        button.frame = frame;
        
        VNPermissionType type = (VNPermissionType)button.tag;
        VNPermissionStatus status = [self.delegate viewController:self askPermissionStatus:type];
        
        NSString *prettyDescription = nil;
        button.userInteractionEnabled = TRUE;
        
        switch (status) {
            case VNPermissionStatusAuthorized:
                [self setButtonAuthorizedStyle:button];
                prettyDescription = [NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.view.button.status.allowed", @"Allowed %@ - title for permission button"), permissionTypeDescription(type)];
                break;
            case VNPermissionStatusUnAuthorized:
                [self setButtonUnauthorizedStyle:button];
                prettyDescription = [NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.view.button.status.denied", @"Denied %@ - title for permission button"), permissionTypeDescription(type)];
                break;
            case VNPermissionStatusDisabled:
                [self setButtonDisabledStyle:button];
                prettyDescription = [NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.view.button.status.disabled", @"%@ Disabled - title for permission button"), permissionTypeDescription(type)];
                button.userInteractionEnabled = FALSE;
                break;
            case VNPermissionStatusUnknown:
            default:
                break;
        }
        if (prettyDescription.length > 0) {
            [button setTitle:prettyDescription forState:UIControlStateNormal];
        }
        
        
        UILabel *label = self.permissionLabels[index];
        label.center = self.contentView.center;
        frame = label.frame;
        frame = CGRectOffset(frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
        frame = CGRectOffset(frame, 0, -(dialogHeight/2-205) + (CGFloat)(index*baseOffset));
        label.frame = frame;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// MARK: - FACTORY
/**
 Permission button factory. Uses the custom style parameters such as `permissionButtonTextColor`, `buttonFont`, etc.
 
 - parameter type: Permission type
 
 - returns: UIButton instance with a custom style.
 */
-(UIButton*)permissionStyledButton:(VNPermissionType)permissionType {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
    [button setTitleColor:self.permissionButtonTextColor forState:UIControlStateNormal];
    button.titleLabel.font = self.buttonFont;
    button.titleLabel.adjustsFontSizeToFitWidth = TRUE;
    button.titleLabel.minimumScaleFactor = 0.7;
    
    button.layer.borderWidth = self.permissionButtonBorderWidth;
    button.layer.borderColor = self.permissionButtonBorderColor.CGColor;
    button.layer.cornerRadius = self.permissionButtonCornerRadius;
    
    // this is a bit of a mess, eh?
    switch (permissionType) {
        case VNPermissionTypeLocationInUse:
        case VNPermissionTypeLocationAlways:
            [button setTitle:[[NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.view.button.enable", @"Enable %@ - permission type"), permissionTypeDescription(permissionType)] uppercaseString]forState:UIControlStateNormal];
            break;
        default:
            [button setTitle:[[NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.view.button.allow", @"Allow %@ - permission type"), permissionTypeDescription(permissionType)] uppercaseString] forState:UIControlStateNormal];
            break;
    }
    
    [button addTarget:self action:@selector(onClickRequestPermission:) forControlEvents:UIControlEventTouchUpInside];
    
    button.accessibilityIdentifier = [[NSString stringWithFormat:@"permissionscope.button.%@", permissionTypeTitle(permissionType)] lowercaseString];
    button.tag = permissionType;
    return button;
}

/**
 Sets the style for permission buttons with authorized status.
 
 - parameter button: Permission button
 */
-(void)setButtonAuthorizedStyle:(UIButton*)button {
    button.layer.borderWidth = 0;
    button.backgroundColor = self.authorizedButtonColor;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

/**
 Sets the style for permission buttons with unauthorized status.
 
 - parameter button: Permission button
 */
-(void)setButtonUnauthorizedStyle:(UIButton*)button {
    button.layer.borderWidth = 0;
    button.backgroundColor = self.unauthorizedButtonColor ? self.unauthorizedButtonColor : [self.authorizedButtonColor inverse];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}
/**
 Sets the style for permission buttons with disabled status.
 
 - parameter button: Permission button
 */
-(void)setButtonDisabledStyle:(UIButton*)button {
    button.layer.borderWidth = 0;
    button.backgroundColor = [UIColor redColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

/**
 Permission label factory, located below the permission buttons.
 
 - parameter type: Permission type
 
 - returns: UILabel instance with a custom style.
 */
-(UILabel*)permissionStyledLabel:(VNPermissionType)permissionType {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 50)];
    label.font = self.labelFont;
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = self.permissionMessages[@(permissionType)];
    label.textColor = self.permissionLabelColor;
    
    return label;
}

// MARK: - Accessors
-(NSMutableArray *)permissionButtons {
    if (!_permissionButtons) {
        self.permissionButtons = [NSMutableArray new];
    }
    return _permissionButtons;
}
-(NSMutableArray *)permissionLabels {
    if (!_permissionLabels) {
        self.permissionLabels = [NSMutableArray new];
    }
    return _permissionLabels;
}
-(void)setPermissionMessages:(NSDictionary<NSNumber *,NSString *> *)permissionMessages {
    if (_permissionMessages != permissionMessages ) {
        _permissionMessages = permissionMessages;
        [self createButtonsAndLabels];
    }
}
// MARK: - Init
/**
 Designated initializer.
 
 - parameter backgroundTapCancels: True if a tap on the background should trigger the dialog dismissal.
 */

-(instancetype)initWithBackgroundTapCancels:(BOOL)tapFlag {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setupViewControllerWithBackgroundTapCancels:tapFlag];
    }
    return self;
}

/**
 Convenience initializer. Same as `init(backgroundTapCancels: true)`
 */
-(instancetype)init {
    return [self initWithBackgroundTapCancels:FALSE];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSAssert(FALSE, @"init(coder:) has not been implemented");
    return nil;
}


-(void)setupViewControllerWithBackgroundTapCancels:(BOOL)tapFlag {
    
    // Set up ivars
    self.closeButtonTextColor =  [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1];
    /// Color for the permission buttons' text color.
    self.permissionButtonTextColor = [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1];
    /// Color for the permission buttons' border color.
    self.permissionButtonBorderColor = [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1];
    /// Width for the permission buttons.
    self.permissionButtonBorderWidth = 1;
    /// Corner radius for the permission buttons.
    self.permissionButtonCornerRadius = 6;
    /// Color for the permission labels' text color.
    self.permissionLabelColor = [UIColor blackColor];
    /// Font used for all the UIButtons
    self.buttonFont = [UIFont boldSystemFontOfSize:14.f];
    /// Font used for all the UILabels
    self.labelFont = [UIFont systemFontOfSize:14.];
    /// Close button. By default in the top right corner.
    
    /// Offset used to position the Close button.
    self.closeOffset = CGSizeMake(12.f, 8.f);
    /// Color used for permission buttons with authorized status
    self.authorizedButtonColor = [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1];
    
    
    // Set up main view
    self.view.frame = [UIScreen mainScreen].bounds;
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    
    
    // Base View
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    self.baseView = view;
    [self.view addSubview:self.baseView];
    
    if (tapFlag) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickCancel:)];
        tap.delegate = self;
        [self.baseView addGestureRecognizer:tap];
    }
    
    // Content View
    view = [[UIView alloc] initWithFrame:self.view.bounds];
    self.contentView = view;
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = TRUE;
    self.contentView.layer.borderWidth = 0.5;
    [self.baseView addSubview:self.contentView];
    
    
    // header label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    self.headerLabel = label;
    self.headerLabel.font = [UIFont systemFontOfSize:22];
    self.headerLabel.textColor = [UIColor blackColor];
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.text = VNLocalizedString(@"com.mistral.permission.view.headerlabel", @"Hey, listen!");
    self.headerLabel.accessibilityIdentifier = @"com.mistral.permission.view.headerlabel";
    
    [self.contentView addSubview:self.headerLabel];
    
    // body label
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 240, 70)];
    self.bodyLabel = label;
    self.bodyLabel.font = [UIFont boldSystemFontOfSize:16.];
    self.bodyLabel.textColor = [UIColor blackColor];
    self.bodyLabel.textAlignment = NSTextAlignmentCenter;
    self.bodyLabel.text = VNLocalizedString(@"com.mistral.permission.view.bodylabel", @"We need a couple things\r\nbefore you get started.");
    self.bodyLabel.numberOfLines = 3; //was 2
    self.bodyLabel.accessibilityIdentifier = @"com.mistral.permission.view.bodylabel";
    [self.contentView addSubview:self.bodyLabel];
    
    // close button
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 240, 32)];
    self.closeButton = button;
    [self.closeButton setTitle:VNLocalizedString(@"com.mistral.permission.view.closebutton", @"Close - button title") forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(onClickCancel:) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.accessibilityIdentifier = @"com.mistral.permission.view.closebutton";
    [self.closeButton setTitleColor:self.closeButtonTextColor forState:UIControlStateNormal];
    self.closeButton.titleLabel.textAlignment = NSTextAlignmentRight;
    
    [self.contentView addSubview:self.closeButton];
    
    /// create permission buttons and labels
    [self createButtonsAndLabels];
}

-(void)createButtonsAndLabels {
    __weak VNPermissionScopeViewController *weakSelf = self;
    for (UIButton *button in self.permissionButtons) {
        [button removeFromSuperview];
    }
    self.permissionButtons = nil;
    for (UILabel *label in self.permissionLabels) {
        [label removeFromSuperview];
    }
    self.permissionLabels = nil;
    
    [self.permissionMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        UIButton *button = [weakSelf permissionStyledButton:(VNPermissionType)[key integerValue]];
        [weakSelf.permissionButtons addObject:button];
        [weakSelf.contentView addSubview:button];
        
        UILabel *label = [weakSelf permissionStyledLabel:(VNPermissionType)[key integerValue]];
        [weakSelf.permissionLabels addObject:label];
        [weakSelf.contentView addSubview:label];
    }];
}
// MARK: - IBActions
/**
 Called when the users taps on the close button.
 */
-(IBAction)onClickCancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(viewControllerWillCancel:)]) {
        [self.delegate viewControllerWillCancel:self];
    }
}
-(IBAction)onClickRequestPermission:(id)sender {
    UIButton *button = sender;
    VNPermissionType permissionType = (VNPermissionType)button.tag;
    if ([self.delegate respondsToSelector:@selector(viewController:requestPermission:)]) {
        [self.delegate viewController:self requestPermission:permissionType];
    }
}


@end
