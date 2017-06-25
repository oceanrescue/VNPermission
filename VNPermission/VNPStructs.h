//
//  VNPStructs.h
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//


#ifndef VNPStructs_h
#define VNPStructs_h
#import <Foundation/Foundation.h>

typedef enum {
    VNPermissionTypeContacts = 0,
    VNPermissionTypeLocationAlways,
    VNPermissionTypeLocationInUse,
    VNPermissionTypeNotifications,
    VNPermissionTypeMicrophone,
    VNPermissionTypeCamera,
    VNPermissionTypePhotos,
    VNPermissionTypeReminders,
    VNPermissionTypeEvents,
    VNPermissionTypeBluetooth,
    VNPermissionTypeMotion,
} VNPermissionType;

extern NSString * permissionTypeTitle(VNPermissionType type);
extern NSString * permissionTypeDescription(VNPermissionType type);


typedef enum {
    VNPermissionStatusUnknown = 0,
    VNPermissionStatusUnAuthorized,
    VNPermissionStatusAuthorized,
    VNPermissionStatusDisabled, // System-level
}VNPermissionStatus;

extern NSString * permissionStatusDescription(VNPermissionStatus status);


@interface VNPermissionResult : NSObject
@property VNPermissionType type;
@property VNPermissionStatus status;

-(instancetype)initWithType:(VNPermissionType)type status:(VNPermissionStatus)status;
@end
    
#endif
