//
//  AppDelegate.h
//  SMJobBless
//
//  Created by Ted Wei on 06/02/2017.
//
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    
    IBOutlet NSTextField *  _textField;
    
    AuthorizationRef        _authRef;
    
}

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (assign, nonatomic) BOOL darkModeOn;

@end

