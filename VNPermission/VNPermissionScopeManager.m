//
//  VNPermissionScopeManager.m
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#import "VNPermissionScopeManager.h"
#import "VNPConstants.h"
#import "VNPermissionScopeViewController.h"
#import "VNPStructs.h"
#import "VNExtension.h"
#import "VNPermissions.h"
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
@import UserNotifications;


typedef void (^ResultsForConfigClosure)(NSSet <VNPermissionResult*> * _Nullable results);


@interface VNPermissionScopeManager () <CLLocationManagerDelegate, CBPeripheralManagerDelegate, VNPermissionScopeViewControllerDelegate>
@property (nonatomic, retain, readwrite) CBPeripheralManager * bluetoothManager;
@property (nonatomic, retain, readwrite) CLLocationManager * locationManager;
@property (nonatomic, retain, readwrite) CMMotionActivityManager * motionManager;
@property (nonatomic, retain) VNPermissionScopeViewController *viewController;
-(void)allAuthorized:(nonnull void (^)(BOOL areAuthorized))completion;
@property (nonatomic, retain) NSTimer *notificationTimer;
@end

@implementation VNPermissionScopeManager

// MARK: - Customizing the permissions

/**
 Adds a permission configuration to permission manager.
 
 - parameter config: Configuration for a specific permission.
 - parameter message: Body label's text on the presented dialog when requesting access.
 */
-(void)addPermission:(id <VNPermissionProtocol> _Nonnull)permission withMessage:(NSString*_Nonnull)message {
    NSAssert(permission, @"Permission must exists");
    NSAssert(message.length > 0, @"Including a message about your permission usage is helpful");
    NSAssert(self.configuredPermissions.count < 3, @"Ask for three or fewer permissions at a time");
    [self.configuredPermissions enumerateObjectsUsingBlock:^(id<VNPermissionProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert(obj.type != permission.type, @"Permission for %@ has been already set", permissionTypeDescription(permission.type));
    }];
    
    [self.configuredPermissions addObject:permission];
    self.permissionMessages[@(permission.type)] = message;
    
    if (permission.type == VNPermissionTypeBluetooth && self.askedBluetooth) {
        [self triggerBluetoothStatusUpdate];
    } else if (permission.type == VNPermissionTypeMotion && self.askedMotion) {
        [self triggerMotionStatusUpdate];
    }
}

// MARK: - Status and Requests for each permission

// MARK: Location

/**
 Returns the current permission status for accessing LocationAlways.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusLocationAlways {
    if (![CLLocationManager locationServicesEnabled]) return VNPermissionStatusDisabled;
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            return VNPermissionStatusAuthorized;
            break;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            return VNPermissionStatusUnAuthorized;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            // Curious why this happens? Details on upgrading from WhenInUse to Always:
            // [Check this issue](https://github.com/nickoneill/PermissionScope/issues/24 )
            if ([[NSUserDefaults standardUserDefaults] boolForKey:vnp_RequestedInUseToAlwaysUpgrade]) {
                return VNPermissionStatusUnAuthorized;
            } else {
                return VNPermissionStatusUnknown;
            }
        case kCLAuthorizationStatusNotDetermined:
        default:
            return VNPermissionStatusUnknown;
            break;
    }
}

/**
 Requests access to LocationAlways, if necessary.
 */
-(void)requestLocationAlways {
    
    BOOL hasAlwaysKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:vnp_LocationAlways];
    NSAssert(hasAlwaysKey, @"%@ not found in Info.plist", vnp_LocationAlways);
    
    
    VNPermissionStatus status = [self statusLocationAlways];
    switch (status) {
        case VNPermissionStatusUnknown:
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
                [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:vnp_RequestedInUseToAlwaysUpgrade];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            [self.locationManager requestAlwaysAuthorization];
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeLocationAlways];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeLocationAlways];
            break;
        default:
            break;
    }
}

/**
 Returns the current permission status for accessing LocationWhileInUse.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusLocationInUse {
    if (![CLLocationManager locationServicesEnabled]) return VNPermissionStatusDisabled;
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    

    // if you're already "always" authorized, then you don't need in use
    // but the user can still demote you! So I still use them separately.
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            return VNPermissionStatusAuthorized;
            break;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            return VNPermissionStatusUnAuthorized;
        case kCLAuthorizationStatusNotDetermined:
        default:
            return VNPermissionStatusUnknown;
            break;
    }
}

/**
 Requests access to LocationWhileInUse, if necessary.
 */
-(void)requestLocationInUse {
    
    BOOL hasAlwaysKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:vnp_LocationWhenInUse];
    NSAssert(hasAlwaysKey, @"%@ not found in Info.plist", vnp_LocationWhenInUse);
    
    
    VNPermissionStatus status = [self statusLocationAlways];
    switch (status) {
        case VNPermissionStatusUnknown:
            [self.locationManager requestWhenInUseAuthorization];
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeLocationInUse];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeLocationInUse];
            break;
        default:
            break;
    }
}

// MARK: Contacts

/**
 Returns the current permission status for accessing Contacts.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusContacts {
    NSOperatingSystemVersion ios9_0 = (NSOperatingSystemVersion ){9,0,0};
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios9_0]) {
        
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        switch (status) {
            case CNAuthorizationStatusAuthorized:
                return VNPermissionStatusAuthorized;
                break;
            case CNAuthorizationStatusRestricted:
            case CNAuthorizationStatusDenied:
                return VNPermissionStatusUnAuthorized;
            case CNAuthorizationStatusNotDetermined:
            default:
                return VNPermissionStatusUnknown;
                break;
        }
    } else {
        // Fallback on earlier versions
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        switch (status) {
            case kABAuthorizationStatusAuthorized:
                return VNPermissionStatusAuthorized;
                break;
            case kABAuthorizationStatusRestricted:
            case kABAuthorizationStatusDenied:
                return VNPermissionStatusUnAuthorized;
            case kABAuthorizationStatusNotDetermined:
            default:
                return VNPermissionStatusUnknown;
                break;
        }
#pragma clang diagnostic pop
    }
}

/**
 Requests access to Contacts, if necessary.
 */
-(void)requestContacts {
    VNPermissionStatus status = [self statusContacts];
    switch (status) {
        case VNPermissionStatusUnknown:
        {
            NSOperatingSystemVersion ios9_0 = (NSOperatingSystemVersion ){9,0,0};
            __weak VNPermissionScopeManager *weakSelf = self;
            if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios9_0]) {
                CNContactStore *contactDB = [[CNContactStore alloc] init];
                [contactDB requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    [weakSelf detectAndCallback];
                }];
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                ABAddressBookRequestAccessWithCompletion(nil, ^(bool granted, CFErrorRef error) {
                    [weakSelf detectAndCallback];
                });
#pragma clang diagnostic pop
            }
        }
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeContacts];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeContacts];
            break;
        case VNPermissionStatusAuthorized:
        default:
            break;
    }
}

// MARK: Notifications

/**
 Returns the current permission status for accessing Notifications.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusNotifications {
    NSOperatingSystemVersion ios10_0 = (NSOperatingSystemVersion ){10,0,0};

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios10_0]) {
        
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block UNNotificationSettings *blockSettings;
        
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            blockSettings = settings;
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        switch (blockSettings.authorizationStatus) {
            case UNAuthorizationStatusDenied:
                return VNPermissionStatusUnAuthorized;
                break;
            case UNAuthorizationStatusAuthorized:
                return VNPermissionStatusAuthorized;
                break;
            case UNAuthorizationStatusNotDetermined:
            default:
                return VNPermissionStatusUnknown;
                break;
        }
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (settings.types != UIUserNotificationTypeNone) {
            return VNPermissionStatusAuthorized;
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:vnp_RequestedNotifications]) {
                return VNPermissionStatusUnAuthorized;
            }
            return VNPermissionStatusUnknown;
        }
#pragma clang diagnostic pop
    }
}


/**
 Requests access to User Notifications, if necessary.
 */
-(void)requestNotifications {
    VNPermissionStatus status = [self statusNotifications];
    switch (status) {
        case VNPermissionStatusUnknown:
        {
            VNPermissionNotification *notificationsPermission = [[self.configuredPermissions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                if ([evaluatedObject isKindOfClass:[VNPermissionNotification class]]) {
                    return TRUE;
                }
                return FALSE;
            }]] firstObject];

            NSAssert(notificationsPermission, @"Notification permission must be configured");
            
            NSSet *notificationCategories = notificationsPermission.notificationCategories;
            NSAssert(notificationCategories.count > 0, @"Notification categories must be configured");

            
            NSOperatingSystemVersion ios10_0 = (NSOperatingSystemVersion ){10,0,0};
            if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios10_0]) {
                
                [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:notificationCategories];
                
                __weak VNPermissionScopeManager *weakSelf = self;
                [[UNUserNotificationCenter currentNotificationCenter]
                 requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound
                 completionHandler:^(BOOL granted, NSError * _Nullable error) {
                     [weakSelf detectAndCallback];
                }];
            }
            else {

                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showingNotificationPermission) name:UIApplicationWillResignActiveNotification object:nil];
                self.notificationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(finishedShowingNotificationPermission) userInfo:nil repeats:FALSE];
                
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:notificationCategories];
                [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
#pragma clang diagnostic pop
            }
        }
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeNotifications];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeNotifications];
            break;
        case VNPermissionStatusAuthorized:
            [self detectAndCallback];
            break;
        default:
            break;
    }
}

-(void)showingNotificationPermission {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedShowingNotificationPermission) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.notificationTimer invalidate];
    self.notificationTimer = nil;
}

-(void)finishedShowingNotificationPermission {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.notificationTimer invalidate];
    self.notificationTimer = nil;
    
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:vnp_RequestedNotifications];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    __weak VNPermissionScopeManager *weakSelf = self;
    
    // callback after a short delay, otherwise notifications don't report proper auth
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_MSEC * 100)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf getResultsForConfigWithCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
            VNPermissionResult *notificationResult = [[results filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(VNPermissionResult * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                return evaluatedObject.type == VNPermissionTypeNotifications;
            }]] anyObject];
            if (!notificationResult) return;
            if (notificationResult.status == VNPermissionStatusUnknown) {
                [weakSelf showDeniedAlert:notificationResult.type];
            } else {
                [weakSelf detectAndCallback];
            }
        }];
    });
}
// MARK: Microphone

/**
 Returns the current permission status for accessing the Microphone.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusMicrophone {
    AVAudioSessionRecordPermission recordPermission = [[AVAudioSession sharedInstance] recordPermission];
    switch (recordPermission) {
        case AVAudioSessionRecordPermissionDenied:
            return VNPermissionStatusUnAuthorized;
            break;
        case AVAudioSessionRecordPermissionGranted:
            return VNPermissionStatusAuthorized;
        case AVAudioSessionRecordPermissionUndetermined:
        default:
            return VNPermissionStatusUnknown;
            break;
    }
}

/**
 Requests access to the Microphone, if necessary.
 */
-(void)requestMicrophone {
    VNPermissionStatus status = [self statusMicrophone];
    switch (status) {
        case VNPermissionStatusUnknown:
        {
            __weak VNPermissionScopeManager *weakSelf = self;
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                [weakSelf detectAndCallback];
            }];
        }
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeMicrophone];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeMicrophone];
            break;
        case VNPermissionStatusAuthorized:
        default:
            break;
    }
}

// MARK: Camera

/**
 Returns the current permission status for accessing the Camera.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusCamera {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            return VNPermissionStatusAuthorized;
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            return VNPermissionStatusUnAuthorized;
        case AVAuthorizationStatusNotDetermined:
        default:
            return VNPermissionStatusUnknown;
            break;
    }
}

/**
 Requests access to the Camera, if necessary.
 */
-(void)requestCamera {
    VNPermissionStatus status = [self statusCamera];
    switch (status) {
        case VNPermissionStatusUnknown:
        {
            __weak VNPermissionScopeManager *weakSelf = self;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                [weakSelf detectAndCallback];
            }];
        }
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeCamera];
             break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeCamera];
            break;
        case VNPermissionStatusAuthorized:
        default:
            break;
    }
}

// MARK: Photos

/**
 Returns the current permission status for accessing Photos.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusPhotos {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusAuthorized:
            return VNPermissionStatusAuthorized;
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            return VNPermissionStatusUnAuthorized;
            break;
        case PHAuthorizationStatusNotDetermined:
        default:
            return VNPermissionStatusUnknown;
            break;
    }
}

/**
 Requests access to Photos, if necessary.
 */
-(void)requestPhotos {
    VNPermissionStatus status = [self statusPhotos];
    switch (status) {
        case VNPermissionStatusUnknown:
        {
            __weak VNPermissionScopeManager *weakSelf = self;
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                [weakSelf detectAndCallback];
            }];
        }
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypePhotos];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypePhotos];
            break;
        case VNPermissionStatusAuthorized:
        default:
            break;
    }
}

// MARK: Reminders

/**
 Returns the current permission status for accessing Reminders.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusReminders {
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
    switch (status) {
        case EKAuthorizationStatusAuthorized:
            return VNPermissionStatusAuthorized;
            break;
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
            return VNPermissionStatusUnAuthorized;
            break;
        case EKAuthorizationStatusNotDetermined:
        default:
            return VNPermissionStatusUnknown;
            break;
    }
}

/**
 Requests access to Reminders, if necessary.
 */
-(void)requestReminders {
    VNPermissionStatus status = [self statusReminders];
    switch (status) {
        case VNPermissionStatusUnknown:
        {
            __weak VNPermissionScopeManager *weakSelf = self;
            [[[EKEventStore alloc] init] requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError * _Nullable error) {
                [weakSelf detectAndCallback];
            }];
        }
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeReminders];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeReminders];
            break;
        case VNPermissionStatusAuthorized:
        default:
            break;
    }
}

// MARK: Events

/**
 Returns the current permission status for accessing Events.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusEvents {
    
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    switch (status) {
        case EKAuthorizationStatusAuthorized:
            return VNPermissionStatusAuthorized;
            break;
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
            return VNPermissionStatusUnAuthorized;
            break;
        case EKAuthorizationStatusNotDetermined:
        default:
            return VNPermissionStatusUnknown;
            break;
    }
}

/**
 Requests access to Events, if necessary.
 */
-(void)requestEvents {
    VNPermissionStatus status = [self statusEvents];
    switch (status) {
        case VNPermissionStatusUnknown:
        {
            __weak VNPermissionScopeManager *weakSelf = self;
            [[[EKEventStore alloc] init] requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
                [weakSelf detectAndCallback];
            }];
        }
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeEvents];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeEvents];
            break;
        case VNPermissionStatusAuthorized:
        default:
            break;
    }

}

// MARK: Bluetooth

/// Returns whether Bluetooth access was asked before or not.
-(BOOL)askedBluetooth {
    return [[NSUserDefaults standardUserDefaults] boolForKey:vnp_RequestedBluetooth];
}
-(void)setAskedBluetooth:(BOOL)askedBluetooth {
    [[NSUserDefaults standardUserDefaults] setBool:askedBluetooth forKey:vnp_RequestedBluetooth];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/// Returns whether PermissionScope is waiting for the user to enable/disable bluetooth access or not.
//               fileprivate var waitingForBluetooth = false

/**
Returns the current permission status for accessing Bluetooth.

- returns: Permission status for the requested type.
*/
-(VNPermissionStatus)statusBluetooth {
    // if already asked for bluetooth before, do a request to get status, else wait for user to request
    if (!self.askedBluetooth) {
        return VNPermissionStatusUnknown;
        
    }
    [self triggerBluetoothStatusUpdate];
    CBManagerState serviceState = self.bluetoothManager.state;
    CBPeripheralManagerAuthorizationStatus status = [CBPeripheralManager authorizationStatus];
    if (serviceState == CBManagerStateUnsupported || serviceState == CBManagerStatePoweredOff || status == CBPeripheralManagerAuthorizationStatusRestricted) {
        return VNPermissionStatusDisabled;
    }
    
    else if (serviceState == CBManagerStateUnauthorized || status == CBPeripheralManagerAuthorizationStatusDenied) {
        return VNPermissionStatusUnAuthorized;
    }
    
    else if (serviceState == CBManagerStatePoweredOn && status == CBPeripheralManagerAuthorizationStatusAuthorized) {
        return VNPermissionStatusAuthorized;
    }
    
    return VNPermissionStatusUnknown;
}

               
/**
Requests access to Bluetooth, if necessary.
*/
-(void)requestBluetooth {
    VNPermissionStatus status = [self statusBluetooth];
    switch (status) {
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeBluetooth];
            break;
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeBluetooth];
            break;
        case VNPermissionStatusUnknown:
            [self triggerBluetoothStatusUpdate];
            break;
        default:
            break;
    }
}

/**
Start and immediately stop bluetooth advertising to trigger
its permission dialog.
*/
-(void)triggerBluetoothStatusUpdate {
   if (!self.waitingForBluetooth && self.bluetoothManager.state == CBManagerStateUnknown) {
       [self.bluetoothManager startAdvertising:nil];
       [self.bluetoothManager stopAdvertising];
       self.askedBluetooth = TRUE;
       self.waitingForBluetooth = TRUE;
   }
}


// MARK: Core Motion Activity

/**
 Returns the current permission status for accessing Core Motion Activity.
 
 - returns: Permission status for the requested type.
 */
-(VNPermissionStatus)statusMotion {
    if (self.askedMotion) {
        [self triggerMotionStatusUpdate];
    }
    return self.motionPermissionStatus;
}

/**
 Requests access to Core Motion Activity, if necessary.
 */
-(void)requestMotion {
    VNPermissionStatus status = [self statusMotion];
    switch (status) {
        case VNPermissionStatusUnAuthorized:
            [self showDeniedAlert:VNPermissionTypeMotion];
            break;
        case VNPermissionStatusDisabled:
            [self showDisabledAlert:VNPermissionTypeMotion];
            break;
        case VNPermissionStatusUnknown:
            [self triggerMotionStatusUpdate];
            break;
        default:
            break;
    }
}

/**
 Prompts motionManager to request a status update. If permission is not already granted the user will be prompted with the system's permission dialog.
 */
-(void)triggerMotionStatusUpdate {
    if (![CMMotionActivityManager isActivityAvailable]) {
        self.waitingForMotion = FALSE;
        self.motionPermissionStatus = VNPermissionStatusDisabled;
        return;
    }
    
    VNPermissionStatus tmpMotionPermissionStatus = self.motionPermissionStatus;
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:vnp_RequestedMotion];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSDate *today = [NSDate date];
    __weak VNPermissionScopeManager *weakSelf = self;
    [self.motionManager queryActivityStartingFromDate:today toDate:today toQueue:[NSOperationQueue mainQueue] withHandler:^(NSArray<CMMotionActivity *> * _Nullable activities, NSError * _Nullable error) {
        if (error ) {
            NSLog(@"Error: %@", error);
            weakSelf.motionPermissionStatus = VNPermissionStatusUnAuthorized;
        } else {
            weakSelf.motionPermissionStatus = VNPermissionStatusAuthorized;
        }
        [weakSelf.motionManager stopActivityUpdates];
        weakSelf.motionManager = nil;
        weakSelf.waitingForMotion = FALSE;
        if (tmpMotionPermissionStatus != weakSelf.motionPermissionStatus) {
            [weakSelf detectAndCallback];
        }
    }];
    
    
    self.askedMotion = TRUE;
    self.waitingForMotion = TRUE;
}

/// Returns whether Bluetooth access was asked before or not.
-(BOOL)askedMotion {
    return [[NSUserDefaults standardUserDefaults] boolForKey:vnp_RequestedMotion];
}
-(void)setAskedMotion:(BOOL)askedMotion {
    [[NSUserDefaults standardUserDefaults] setBool:askedMotion forKey:vnp_RequestedMotion];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


// MARK: - Helpers

/**
 This notification callback is triggered when the app comes back
 from the settings page, after a user has tapped the "show me"
 button to check on a disabled permission. It calls detectAndCallback
 to recheck all the permissions and update the UI.
 */
-(void)appForegroundedAfterSettings {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [self detectAndCallback];
}

/**
 Requests the status of any permission.
 
 - parameter type:       Permission type to be requested
 - parameter completion: Closure called when the request is done.
 */
-(void)statusForPermission:(VNPermissionType)type withCompletion:(StatusRequestClosure)completion {

    NSAssert(completion, @"Completion must exists");
    // Get permission status
    VNPermissionStatus status = VNPermissionStatusUnknown;
    switch (type) {
        case VNPermissionTypeLocationAlways:
            status = [self statusLocationAlways];
            break;
        case VNPermissionTypeLocationInUse:
            status = [self statusLocationInUse];
            break;
        case VNPermissionTypeContacts:
            status = [self statusContacts];
            break;
        case VNPermissionTypeNotifications:
            status = [self statusNotifications];
            break;
        case VNPermissionTypeMicrophone:
            status = [self statusMicrophone];
            break;
        case VNPermissionTypeCamera:
            status = [self statusCamera];
            break;
        case VNPermissionTypePhotos:
            status = [self statusPhotos];
            break;
        case VNPermissionTypeReminders:
            status = [self statusReminders];
            break;
        case VNPermissionTypeEvents:
            status = [self statusEvents];
            break;
        case VNPermissionTypeBluetooth:
            status = [self statusBluetooth];
            break;
        case VNPermissionTypeMotion:
            status = [self statusMotion];
            break;
        default:
            break;
    }
    // Perform completion
    completion(status);
}


/**
 Rechecks the status of each requested permission, updates
 the PermissionScope UI in response and calls your onAuthChange
 to notifiy the parent app.
 */
-(void)detectAndCallback {
    __weak VNPermissionScopeManager *weakSelf = self;
    // compile the results and pass them back if necessary
    AuthClosureType onAuthChange = self.onAuthChange;
    if (onAuthChange) {
        [self getResultsForConfigWithCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
            [weakSelf allAuthorized:^(BOOL areAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    onAuthChange(areAuthorized, results);
                });
            }];
        }];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf updateViewController];
    });
    
    // and hide if we've sucessfully got all permissions
    [weakSelf allAuthorized:^(BOOL areAuthorized) {
        if (areAuthorized){
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf hide];
            });
        }
    }];
    
}

/**
 Calculates the status for each configured permissions for the caller
 */
-(void)getResultsForConfigWithCompletion:(ResultsForConfigClosure)completion {
    
    NSAssert(completion, @"Completion must exists");

    __block NSMutableSet <VNPermissionResult*> *results = [NSMutableSet new];
    __weak VNPermissionScopeManager *weakSelf = self;
    
    dispatch_async(dispatch_queue_create("com.vnpermission.checkresults", DISPATCH_QUEUE_CONCURRENT), ^{
        dispatch_group_t semaGroup = dispatch_group_create();
        
        for (id<VNPermissionProtocol> config in weakSelf.configuredPermissions) {
            VNPermissionType type = config.type;
            dispatch_group_enter(semaGroup);
            [weakSelf statusForPermission:type withCompletion:^(VNPermissionStatus status) {
                [results addObject:[[VNPermissionResult alloc] initWithType:type status:status]];
                dispatch_group_leave(semaGroup);
            }];
        }
        dispatch_group_wait(semaGroup, DISPATCH_TIME_FOREVER);
        completion(results);
    });
    
}

/**
 Checks whether all the configured permission are authorized or not.
 
 - parameter completion: Closure used to send the result of the check.
 */
-(void)allAuthorized:(nonnull void (^)(BOOL areAuthorized))completion {
    [self getResultsForConfigWithCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
        BOOL result = TRUE;
        for (VNPermissionResult *object in results) {
            if (object.status != VNPermissionStatusAuthorized) {
                result = FALSE;
                break;
            }
        }
        completion(result);
    }];
}

// use the code we have to see permission status
//Dictionary<PermissionType, PermissionStatus>
-(NSDictionary <NSNumber*, NSNumber*> *)permissionStatuses:(nonnull NSSet <NSNumber*> *)permissionTypes {
    
    __block NSMutableDictionary *statuses = [NSMutableDictionary new];
    __weak VNPermissionScopeManager *weakSelf = self;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    
    __block NSInteger counter = 0;
    for (int type = VNPermissionTypeContacts; type< VNPermissionTypeMotion; type++) {
        
        if (![permissionTypes containsObject:@(type)])  continue;
        
        counter += 1;
        [weakSelf statusForPermission:type withCompletion:^(VNPermissionStatus status) {
            statuses[@(type)] = @(status);
            
            counter -= 1;
            if (counter <= 0) {
                dispatch_semaphore_signal(semaphore);
            }
        }];
    }
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return statuses;
}

// MARK: - UI

/**
 Shows the modal viewcontroller for requesting access to the configured permissions and sets up the closures on it.
 
 - parameter authChange: Called when a status is detected on any of the permissions.
 - parameter cancelled:  Called when the user taps the Close button.
 */

-(void)updateViewController {
    if (_viewController) {
        [self.viewController.view setNeedsLayout];
    }
}

-(void)showWithAuthChangeCompletion:(AuthClosureType)authChangeCompletion cancelCompletion:(CancelClosureType)cancelCompletion {
    self.onAuthChange = authChangeCompletion;
    self.onCancel = cancelCompletion;
    
#if DEBUG
    NSAssert(self.configuredPermissions.count > 0, @"Please add at least one permission");
#endif
    

    __weak VNPermissionScopeManager *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (weakSelf.waitingForBluetooth || weakSelf.waitingForMotion) { }
        // call other methods that need to wait before show
        // no missing required perms? callback and do nothing
        [weakSelf allAuthorized:^(BOOL areAuthorized) {
            if (areAuthorized) {
                if (weakSelf.onAuthChange) {
                    [weakSelf getResultsForConfigWithCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
                        weakSelf.onAuthChange(TRUE, results);
                    }];
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf showAlertViewController];
                });
            }
        }];
    });
}

/**
 Creates the modal viewcontroller and shows it.
 */
-(void)showAlertViewController {
    // add the backing views
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    //hide KB if it is shown
    [window endEditing:TRUE];
    if (window.rootViewController) {
        [window.rootViewController presentViewController:self.viewController animated:FALSE completion:nil];
    } else {
        [window addSubview:self.viewController.view];
    }
    self.viewController.view.frame = window.bounds;
    
    self.viewController.baseView.frame = window.bounds;
    [self.viewController.view setNeedsLayout];
    
    // slide in the view
    CGRect frame = self.viewController.baseView.frame;
    frame.origin.y = self.viewController.view.bounds.origin.y - frame.size.height;
    self.viewController.view.alpha = 0;
    
    __weak VNPermissionScopeManager *weakSelf = self;
    CGPoint center = window.center;
    CGPoint baseViewCenter = self.viewController.baseView.center;
    baseViewCenter.y = center.y + 15.f;
    
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.viewController.baseView.center = baseViewCenter;
        weakSelf.viewController.view.alpha = 1.;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.viewController.baseView.center = center;
        }];
    }];
}
/**
 Hides the modal viewcontroller with an animation.
 */
-(void)hide {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    __weak VNPermissionScopeManager *weakSelf = self;
    
    CGPoint center = window.center;
    CGPoint baseViewCenter = self.viewController.baseView.center;
    baseViewCenter.y = center.y + 400.f;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.viewController.view.center = baseViewCenter;
            weakSelf.viewController.view.alpha = 0;
        } completion:^(BOOL finished) {
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            if (window.rootViewController) {
                [window.rootViewController dismissViewControllerAnimated:FALSE completion:nil];
            } else {
                [weakSelf.viewController.view removeFromSuperview];
            }
            weakSelf.viewController = nil;
        }];
    });
    
    [self.notificationTimer invalidate];
    self.notificationTimer = nil;
}

/**
 Shows an alert for a permission which was Denied.
 
 - parameter permission: Permission type.
 */
-(void)showDeniedAlert:(VNPermissionType)permissionType {
    // compile the results and pass them back if necessary
    CancelClosureType onDisabledOrDenied = self.onDisabledOrDenied;
    if (onDisabledOrDenied)  {
        [self getResultsForConfigWithCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
            onDisabledOrDenied(results);
        }];
    }
    
    __weak VNPermissionScopeManager *weakSelf = self;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.alert.title.denied.", @"Permission for %@ was denied."), permissionTypeDescription(permissionType)] message:[NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.alert.message.denied.", @"Please enable access to %@ in the Settings app"), permissionTypeDescription(permissionType)] preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:VNLocalizedString(@"com.mistral.permission.alert.actionButton.OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:VNLocalizedString(@"com.mistral.permission.alert.actionButton.showPreferrencies", @"Show me - button title to show Settings preferencies") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(appForegroundedAfterSettings) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        NSOperatingSystemVersion ios10_0 = (NSOperatingSystemVersion ){10,0,0};
        
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios10_0]) {
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] openURL:settingsURL];
#pragma clang diagnostic pop
        }
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.viewControllerForAlerts) {
            [weakSelf.viewControllerForAlerts presentViewController:alert animated:TRUE completion:nil];
        } else {
            
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            
            //hide KB if it is shown
            [window endEditing:TRUE];
            if (window.rootViewController) {
                [window.rootViewController presentViewController:alert animated:TRUE completion:nil];
            }

        }
    });
}

/**
 Shows an alert for a permission which was Disabled (system-wide).
 
 - parameter permission: Permission type.
 */
-(void)showDisabledAlert:(VNPermissionType)permissionType {
    // compile the results and pass them back if necessary
    CancelClosureType onDisabledOrDenied = self.onDisabledOrDenied;
    
    if (onDisabledOrDenied) {
        [self getResultsForConfigWithCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
            onDisabledOrDenied(results);
        }];
    }
    
    __weak VNPermissionScopeManager *weakSelf = self;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.alert.title.disabled.", @"Permission for %@ is curently disabled."), permissionTypeDescription(permissionType)] message:[NSString localizedStringWithFormat:VNLocalizedString(@"com.mistral.permission.alert.message.disabled.", @"Please enable access to %@ in the Settings app"), permissionTypeDescription(permissionType)] preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:VNLocalizedString(@"com.mistral.permission.alert.actionButton.OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
        
    [alert addAction:[UIAlertAction actionWithTitle:VNLocalizedString(@"com.mistral.permission.alert.actionButton.showPreferrencies", @"Show me - button title to show Settings preferencies") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(appForegroundedAfterSettings) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        NSOperatingSystemVersion ios10_0 = (NSOperatingSystemVersion ){10,0,0};
        
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios10_0]) {
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] openURL:settingsURL];
#pragma clang diagnostic pop
        }
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.viewControllerForAlerts) {
            [weakSelf.viewControllerForAlerts presentViewController:alert animated:TRUE completion:nil];
        } else {
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            
            //hide KB if it is shown
            [window endEditing:TRUE];
            if (window.rootViewController) {
                [window.rootViewController presentViewController:alert animated:TRUE completion:nil];
            }
        }
    });
}



// MARK: - Delegates

// MARK: Location delegate
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self detectAndCallback];
}

// MARK: Bluetooth delegate
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    self.waitingForBluetooth = FALSE;
    [self detectAndCallback];
}

// MARK: ViewController delegate
-(void)viewControllerWillCancel:(VNPermissionScopeViewController *)viewController {
    
    [self hide];
    
    if (self.onCancel) {
        __weak VNPermissionScopeManager *weakSelf = self;
        [self getResultsForConfigWithCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
            weakSelf.onCancel(results);
        }];
    }
}

-(VNPermissionStatus)viewController:(VNPermissionScopeViewController*)viewController askPermissionStatus:(VNPermissionType)permissionType {
    VNPermissionStatus status = VNPermissionStatusUnknown;
    switch (permissionType) {
        case VNPermissionTypeCamera:
            status = [self statusCamera];
            break;
        case VNPermissionTypeEvents:
            status = [self statusEvents];
            break;
        case VNPermissionTypeMotion:
            status = [self statusMotion];
            break;
        case VNPermissionTypePhotos:
            status = [self statusPhotos];
            break;
        case VNPermissionTypeContacts:
            status = [self statusContacts];
            break;
        case VNPermissionTypeBluetooth:
            status = [self statusBluetooth];
            break;
        case VNPermissionTypeReminders:
            status = [self statusReminders];
            break;
        case VNPermissionTypeMicrophone:
            status = [self statusMicrophone];
            break;
        case VNPermissionTypeLocationInUse:
            status = [self statusLocationInUse];
            break;
        case VNPermissionTypeLocationAlways:
            status = [self statusLocationAlways];
            break;
        case VNPermissionTypeNotifications:
            status = [self statusNotifications];
            break;
        default:
            break;
    }
    return status;
}

-(void)viewController:(VNPermissionScopeViewController *)viewController requestPermission:(VNPermissionType)permissionType {
    NSString *selectorString = [NSString stringWithFormat:@"request%@", permissionTypeTitle(permissionType)];
    [self performSelector:NSSelectorFromString(selectorString)];
}

// MARK: - Init
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.motionPermissionStatus = VNPermissionStatusUnknown;
        [self statusMotion]; //Added to check motion status on load
    }
    return self;
}

// MARK: - Various lazy managers & properties
-(CLLocationManager*)locationManager {
    if (!_locationManager) {
        CLLocationManager *lm = [[CLLocationManager alloc] init];
        lm.delegate = self;
        self.locationManager = lm;
    }
    return _locationManager;
}

-(CBPeripheralManager*)bluetoothManager {
    if (!_bluetoothManager) {
        CBPeripheralManager *pm = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey: @(FALSE)}];
        self.bluetoothManager = pm;
    }
    return _bluetoothManager;
}

-(CMMotionActivityManager*)motionManager {
    if (!_motionManager) {
        CMMotionActivityManager *mm = [[CMMotionActivityManager alloc] init];
        self.motionManager = mm;
    }
    return _motionManager;
}

-(NSMutableArray<id<VNPermissionProtocol>> *)configuredPermissions {
    if (!_configuredPermissions) {
        self.configuredPermissions = [NSMutableArray new];
    }
    return _configuredPermissions;
}

-(NSMutableDictionary<NSNumber *,NSString *> *)permissionMessages {
    if (!_permissionMessages) {
        self.permissionMessages = [NSMutableDictionary new];
    }
    return _permissionMessages;
}

-(VNPermissionScopeViewController *)viewController {
    if (!_viewController) {
        VNPermissionScopeViewController *vc = [[VNPermissionScopeViewController alloc] init];
        vc.delegate = self;
        vc.permissionMessages = self.permissionMessages;
        vc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        if (!_viewControllerForAlerts) {
            _viewControllerForAlerts = vc;
        }
        self.viewController = vc;
    }
    return _viewController;
}

@end
