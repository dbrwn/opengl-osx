//
//  DBAppDelegate.h
//  Tutorial6Arm
//
//  Created by David Brown on 01/05/14.
//  Copyright (c) 2014 David T. Brown.
//  This file is licensed under the MIT License.
//

#import <Cocoa/Cocoa.h>

@class DBOpenGLView;

@interface DBAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet DBOpenGLView *openGLView;

@end
