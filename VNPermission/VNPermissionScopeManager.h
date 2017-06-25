//
//  VNPermissionScopeManager.h
//  VNPermission
//
//  Created by Valery Nikitin on 19/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#ifndef VNPermissionScopeManager_h
#define VNPermissionScopeManager_h
@import Foundation;
@import UIKit;
@import CoreLocation;
@import CoreBluetooth;
@import CoreMotion;

#import "VNPStructs.h"



typedef void (^StatusRequestClosure)(VNPermissionStatus status);

typedef void (^AuthClosureType)(BOOL finished, NSSet <VNPermissionResult*> * _Nullable results);

typedef void (^CancelClosureType)(NSSet <VNPermissionResult*> * _Nullable results);

@protocol VNPermissionProtocol;



@interface VNPermissionScopeManager : NSObject
/// Default status for Core Motion Activity
@property VNPermissionStatus motionPermissionStatus;

@property (nonatomic, retain) NSMutableArray <id <VNPermissionProtocol>> * _Nullable configuredPermissions;
@property (nonatomic, retain) NSMutableDictionary <NSNumber*, NSString*> * _Nullable permissionMessages;


@property BOOL askedBluetooth;
@property BOOL askedMotion;
@property BOOL waitingForBluetooth;
/// Returns whether PermissionScope is waiting for the user to enable/disable motion access or not.
@property BOOL waitingForMotion;


@property (nonatomic, retain, readonly) CBPeripheralManager * _Nullable bluetoothManager;
@property (nonatomic, retain, readonly) CLLocationManager * _Nullable locationManager;
@property (nonatomic, retain, readonly) CMMotionActivityManager * _Nullable motionManager;



// Useful for direct use of the request* methods

/// Callback called when permissions status change.
@property (nonatomic, copy, nullable) AuthClosureType onAuthChange;

/// Callback called when the user taps on the close button.
@property (nonatomic, copy, nullable) CancelClosureType onCancel;


/// Called when the user has disabled or denied access to notifications, and we're presenting them with a help dialog.
@property (nonatomic, copy, nullable) CancelClosureType onDisabledOrDenied;

/// View controller to be used when presenting alerts. Defaults to self. You'll want to set this if you are calling the `request*` methods directly.
@property (nonatomic, weak, nullable) UIViewController *viewControllerForAlerts;


/**
 Adds a permission configuration to permission manager.
 
 - parameter config: Configuration for a specific permission.
 - parameter message: Body label's text on the presented dialog when requesting access.
 */
-(void)addPermission:(id <VNPermissionProtocol> _Nonnull)permission withMessage:(NSString*_Nonnull)message;

-(void)allAuthorized:(nonnull void (^)(BOOL areAuthorized))completion;
-(NSDictionary <NSNumber*, NSNumber*> * _Nullable)permissionStatuses:(nonnull NSSet <NSNumber*> *)permissionTypes;


-(void)showWithAuthChangeCompletion:(AuthClosureType _Nullable )authChangeCompletion cancelCompletion:(CancelClosureType _Nullable )cancelCompletion;
-(void)hide;

-(VNPermissionStatus)statusLocationAlways;
-(VNPermissionStatus)statusLocationInUse;
-(VNPermissionStatus)statusContacts;
-(VNPermissionStatus)statusNotifications;
-(VNPermissionStatus)statusMicrophone;
-(VNPermissionStatus)statusCamera;
-(VNPermissionStatus)statusPhotos;
-(VNPermissionStatus)statusReminders;
-(VNPermissionStatus)statusEvents;
-(VNPermissionStatus)statusBluetooth;
-(VNPermissionStatus)statusMotion;

-(void)requestLocationAlways;
-(void)requestLocationInUse;
-(void)requestContacts;
-(void)requestNotifications;
-(void)requestMicrophone;
-(void)requestCamera;
-(void)requestPhotos;
-(void)requestReminders;
-(void)requestEvents;
-(void)requestBluetooth;
-(void)requestMotion;
@end
#endif
