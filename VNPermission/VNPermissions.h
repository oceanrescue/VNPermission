//
//  VNPermissions.h
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#ifndef VNPermissions_h
#define VNPermissions_h
#import <Foundation/Foundation.h>

@import Foundation;
@import CoreLocation;
@import AddressBook;

@import AVFoundation;
@import Photos;
@import EventKit;
@import CoreBluetooth;
@import CoreMotion;
@import CloudKit;
@import Accounts;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif

#import "VNPStructs.h"

@protocol VNPermissionProtocol <NSObject>
@property (nonatomic, readonly) VNPermissionType type;
@end


@interface VNPermissionNotification : NSObject <VNPermissionProtocol>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0    // iOS 10+
@property NSSet <UNNotificationCategory*> *notificationCategories;
-(instancetype)initWithCategories:(NSSet <UNNotificationCategory*> *)notificationCategories;
#else // Pre iOS 10
@property NSSet <UIUserNotificationCategory*> *notificationCategories;
-(instancetype)initWithCategories:(NSSet <UIUserNotificationCategory*> *)notificationCategories;
#endif
@end


@interface VNPermissionLocationWhileInUse : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionLocationAlways : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionContacts : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionEvents : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionMicrophone : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionCamera : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionPhotos : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionReminders : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionBluetooth : NSObject <VNPermissionProtocol>
@end

@interface VNPermissionMotion : NSObject <VNPermissionProtocol>
@end

#endif
