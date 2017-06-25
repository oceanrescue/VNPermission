//
//  VNPermissionLocalization.h
//  VNPermission
//
//  Created by Valery Nikitin on 24/06/2017.
//  Copyright © 2017 Mistral. All rights reserved.
//

#ifndef VNPermissionLocalization_h
#define VNPermissionLocalization_h

#define VNLocalizedString(key, comment) \
[[NSBundle bundleWithIdentifier:@"com.mistral.VNPermission"] localizedStringForKey:key value:nil table:nil]

#endif /* VNPermissionLocalization_h */
