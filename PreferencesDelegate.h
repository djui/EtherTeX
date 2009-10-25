//
//  PreferencesDelegate.h
//
//  Created by Uwe Dauernheim on 25.10.09.
//  Copyright 2009 KTH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferenceWindow : NSResponder {
    IBOutlet id delegate;
    IBOutlet NSView *initialFirstResponder;
    IBOutlet NSMenu *menu;
}

@end
