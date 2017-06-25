<div style="width: 1000px; height: 600px;">
    <p align="center">
        <img src="https://github.com/oceanrescue/VNPermission/blob/master/Screen_en.png" alt="Example EN" width="25%" height="25%" />
        <img src="https://github.com/oceanrescue/VNPermission/blob/master/Screen_ru.png" alt="Example RU" width="25%" height="25%" />
    </p>
</div>



<p align="center">
<img src="https://img.shields.io/badge/platform-iOS%208%2B-blue.svg?style=flat" alt="Platform: iOS 8+" />
<img src="https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat" alt="License: MIT" />
</p>



Inspired by [PermissionScope](https://github.com/nickoneill/PermissionScope)'s permission control, VNPermission is pure Objective-C framework instead of PermissionScope. 

Some examples of multiple permissions requests, a single permission and the denied alert in example App.

Supported permissions:
* Notifications (local)
* Location (WhileInUse, Always)
* Contacts
* Events
* Microphone
* Camera
* Photos
* Reminders
* Bluetooth
* Motion

## compatibility

VNPermission requires iOS 8+, compatible **Objective-C** based projects.


## installation
Link binary with framework
and `@import VNPermission;` in the files you'd like to use it.

## dialog usage

The simplest implementation displays a list of permissions and is removed when all of them have satisfactory access.

```obj-c
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.multiPscope = [[VNPermissionScopeManager alloc] init];
    self.noUIPscope = [[VNPermissionScopeManager alloc] init];


    [self.multiPscope addPermission:[[VNPermissionContacts alloc] init] withMessage:@"We use this to steal\r\nyour friends"];
    [self.multiPscope addPermission:[[VNPermissionCamera alloc] init] withMessage:@"We use this\r\nto issue drive license"];
    [self.multiPscope addPermission:[[VNPermissionLocationWhileInUse alloc] init] withMessage:@"We use this to track\r\nwhere you live"];

    [self.noUIPscope addPermission:[[VNPermissionCamera alloc] init] withMessage:@"We use this to take \r\nphoto while you sleep"];
    self.noUIPscope.onAuthChange = ^(BOOL finished, NSSet<VNPermissionResult *> * _Nullable results) {
        NSLog(@"Auth change : %@", results);
    };
    self.noUIPscope.viewControllerForAlerts = self;
}
```

Show dialog with callbacks:
```obj-c
[self.multiPscope showWithAuthChangeCompletion:^(BOOL finished, NSSet<VNPermissionResult *> * _Nullable results) {
    NSLog(@"Got results : %@", results);
} cancelCompletion:^(NSSet<VNPermissionResult *> * _Nullable results) {
    NSLog(@"User cancel action");
}];
```

Ask permission without UI:
```obj-c
    [self.noUIPscope requestCamera];
```



## extra requirements for permissions

### location 
**You must set these Info.plist keys for location to work**

Trickiest part of implementing location permissions? You must implement the proper key in your Info.plist file with a short description of how your app uses location info (shown in the system permissions dialog). Without this, trying to get location  permissions will just silently fail. *Software*!

Use `NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription` where appropriate for your app usage. You can specify which of these location permissions you wish to request with `.LocationAlways` or `.LocationInUse` while configuring PermissionScope.

### bluetooth

The *NSBluetoothPeripheralUsageDescription* key in the Info.plist specifying a short description of why your app needs to act as a bluetooth peripheral in the background is **optional**.

However, enabling `background-modes` in the capabilities section and checking the `acts as a bluetooth LE accessory` checkbox is **required**.



## license

VNPermission uses the MIT license. Please file an issue if you have any questions or if you'd like to share how you're using this tool.
