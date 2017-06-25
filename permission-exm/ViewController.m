//
//  ViewController.m
//  permission-exm
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#import "ViewController.h"
@import VNPermission;

@interface ViewController ()
@property (nonatomic, retain) VNPermissionScopeManager *singlePscope;
@property (nonatomic, retain) VNPermissionScopeManager *multiPscope;
@property (nonatomic, retain) VNPermissionScopeManager *noUIPscope;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.singlePscope = [[VNPermissionScopeManager alloc] init];
    self.multiPscope = [[VNPermissionScopeManager alloc] init];
    self.noUIPscope = [[VNPermissionScopeManager alloc] init];
    
    NSSet *categories = nil;
    NSOperatingSystemVersion ios10_0 = (NSOperatingSystemVersion ){10,0,0};
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios10_0]) {
        UNNotificationAction *action = [UNNotificationAction actionWithIdentifier:@"Action" title:@"Action Title" options:UNNotificationActionOptionForeground];
        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"Category" actions:@[action] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
        categories = [NSSet setWithObject:category];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
        action.identifier = @"Action";
        action.title = @"Action Title";
        action.activationMode = UIUserNotificationActivationModeForeground;
        action.authenticationRequired = TRUE;
        UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
        category.identifier = @"Category";
        [category setActions:@[action] forContext:UIUserNotificationActionContextDefault];
        categories = [NSSet setWithObject:category];
#pragma clang diagnostic pop
    }
    
    [self.singlePscope addPermission:[[VNPermissionNotification alloc] initWithCategories:categories] withMessage:@"We use this to send you\r\nspam and love notes"];
    
    [self.multiPscope addPermission:[[VNPermissionContacts alloc] init] withMessage:@"We use this to steal\r\nyour friends"];
    [self.multiPscope addPermission:[[VNPermissionNotification alloc] initWithCategories:categories] withMessage:@"We use this to send you\r\nspam and love notes"];
    [self.multiPscope addPermission:[[VNPermissionLocationWhileInUse alloc] init] withMessage:@"We use this to track\r\nwhere you live"];
    
    [self.noUIPscope addPermission:[[VNPermissionCamera alloc] init] withMessage:@"We use this to take \r\nphoto while you sleep"];
    self.noUIPscope.onAuthChange = ^(BOOL finished, NSSet<VNPermissionResult *> * _Nullable results) {
        NSLog(@"Auth change : %@", results);
    };
    self.noUIPscope.viewControllerForAlerts = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickSimpleNotification:(id)sender {
    [self.singlePscope showWithAuthChangeCompletion:^(BOOL finished, NSSet<VNPermissionResult *> * _Nullable results) {
        NSLog(@"Got results : %@", results);
    } cancelCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
        NSLog(@"User cancel action");
    }];
}
- (IBAction)onClickMultipleNotifications:(id)sender {
    [self.multiPscope showWithAuthChangeCompletion:^(BOOL finished, NSSet<VNPermissionResult *> * _Nullable results) {
        NSLog(@"Got results : %@", results);
    } cancelCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
        NSLog(@"User cancel action");
    }];
}
- (IBAction)onClickUIlessPermission:(id)sender {
    [self.noUIPscope requestCamera];
}

@end
