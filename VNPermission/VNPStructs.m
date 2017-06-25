//
//  VNPStructs.m
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#import "VNPStructs.h"
#import "VNPermissionLocalization.h"

@implementation VNPermissionResult

-(instancetype)initWithType:(VNPermissionType)type status:(VNPermissionStatus)status {
    self = [super init];
    if (self) {
        self.type= type;
        self.status = status;
    }
    return self;
}
-(NSString *)description {
    return [NSString stringWithFormat:@"%@ : %@", permissionTypeDescription(self.type), permissionStatusDescription(self.status)];
}

@end

NSString * permissionTypeTitle(VNPermissionType type) {
    switch (type) {
        case VNPermissionTypeCamera:
            return @"Camera";
            break;
        case VNPermissionTypeEvents:
            return @"Events";
            break;
        case VNPermissionTypeMotion:
            return @"Motion";
            break;
        case VNPermissionTypePhotos:
            return @"Photos";
            break;
        case VNPermissionTypeContacts:
            return @"Contacts";
            break;
        case VNPermissionTypeBluetooth:
            return @"Bluetooth";
            break;
        case VNPermissionTypeReminders:
            return @"Reminders";
            break;
        case VNPermissionTypeMicrophone:
            return @"Microphone";
            break;
        case VNPermissionTypeLocationInUse:
            return @"LocationInUse";
            break;
        case VNPermissionTypeLocationAlways:
            return @"LocationAlways";
            break;
        case VNPermissionTypeNotifications:
        default:
            return @"Notifications";
            break;
    }
}

NSString * permissionTypeDescription(VNPermissionType type) {
    switch (type) {
        case VNPermissionTypeCamera:
            return VNLocalizedString(@"com.mistral.permission.type.camera", @"Title permission type Camera");
            break;
        case VNPermissionTypeEvents:
            return VNLocalizedString(@"com.mistral.permission.type.events", @"Title permission type Events");
            break;
        case VNPermissionTypeMotion:
            return VNLocalizedString(@"com.mistral.permission.type.motion", @"Title permission type Motion");
            break;
        case VNPermissionTypePhotos:
            return VNLocalizedString(@"com.mistral.permission.type.photos", @"Title permission type Photos");
            break;
        case VNPermissionTypeContacts:
            return VNLocalizedString(@"com.mistral.permission.type.contacts", @"Title permission type Contacts");
            break;
        case VNPermissionTypeBluetooth:
            return VNLocalizedString(@"com.mistral.permission.type.bluetooth", @"Title permission type Bluetooth");
            break;
        case VNPermissionTypeReminders:
            return VNLocalizedString(@"com.mistral.permission.type.reminders", @"Title permission type Reminders");
            break;
        case VNPermissionTypeMicrophone:
            return VNLocalizedString(@"com.mistral.permission.type.microphone", @"Title permission type Microphone");
            break;
        case VNPermissionTypeLocationInUse:
            return VNLocalizedString(@"com.mistral.permission.type.locationInUse", @"Title permission type Location in use");
            break;
        case VNPermissionTypeLocationAlways:
            return VNLocalizedString(@"com.mistral.permission.type.locationAlways", @"Title permission type Location always");
            break;
        case VNPermissionTypeNotifications:
        default:
            return VNLocalizedString(@"com.mistral.permission.type.notifications", @"Title permission type Notifications");
            break;
    }
}
NSString * permissionStatusDescription(VNPermissionStatus status) {
    switch (status) {
        case VNPermissionStatusDisabled:
            return VNLocalizedString(@"com.mistral.permission.status.disabled", @"permission status Disabled");
            break;
        case VNPermissionStatusAuthorized:
            return VNLocalizedString(@"com.mistral.permission.status.authorized", @"permission status Authorized");
            break;
        case VNPermissionStatusUnAuthorized:
            return VNLocalizedString(@"com.mistral.permission.status.unauthorized", @"permission status Unauthorized");
            break;
        case VNPermissionStatusUnknown:
        default:
            return VNLocalizedString(@"com.mistral.permission.status.unknown", @"permission status Unknown");
            break;
    }
}
