//
//  VNPermissions.m
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#import "VNPermissions.h"

@implementation VNPermissionNotification
-(VNPermissionType)type {
    return VNPermissionTypeNotifications;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0    // iOS 10+
-(instancetype)initWithCategories:(NSSet <UNNotificationCategory*> *)notificationCategories {
    self = [super init];
    if (self) {
        self.notificationCategories = notificationCategories;
    }
    return self;
}
#else // Pre iOS 10
-(instancetype)initWithCategories:(NSSet <UIUserNotificationCategory*> *)notificationCategories {
    self = [super init];
    if (self) {
        self.notificationCategories = notificationCategories;
    }
    return self;
}
#endif
@end



@implementation VNPermissionLocationWhileInUse
-(VNPermissionType)type {
    return VNPermissionTypeLocationInUse;
}
@end


@implementation VNPermissionLocationAlways
-(VNPermissionType)type {
    return VNPermissionTypeLocationAlways;
}
@end

@implementation VNPermissionContacts
-(VNPermissionType)type {
    return VNPermissionTypeContacts;
}
@end

@implementation VNPermissionEvents
-(VNPermissionType)type {
    return VNPermissionTypeEvents;
}
@end

@implementation VNPermissionMicrophone
-(VNPermissionType)type {
    return VNPermissionTypeMicrophone;
}
@end

@implementation VNPermissionCamera
-(VNPermissionType)type {
    return VNPermissionTypeCamera;
}
@end

@implementation VNPermissionPhotos
-(VNPermissionType)type {
    return VNPermissionTypePhotos;
}
@end

@implementation VNPermissionReminders
-(VNPermissionType)type {
    return VNPermissionTypeReminders;
}
@end

@implementation VNPermissionBluetooth
-(VNPermissionType)type {
    return VNPermissionTypeBluetooth;
}
@end

@implementation VNPermissionMotion
-(VNPermissionType)type {
    return VNPermissionTypeMotion;
}
@end
