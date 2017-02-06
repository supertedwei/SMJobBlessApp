//
//  AppDelegate.m
//  SMJobBless
//
//  Created by Ted Wei on 06/02/2017.
//
//

#import "AppDelegate.h"

#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"switchIcon.png"];
    [self.statusItem.image setTemplate:YES];
    
    self.statusItem.highlightMode = NO;
    self.statusItem.toolTip = @"control-click to quit";
    
    [self.statusItem setAction:@selector(itemClicked:)];
    
    #pragma unused(notification)
    NSError *error = nil;
    
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &self->_authRef);
    if (status != errAuthorizationSuccess) {
        /* AuthorizationCreate really shouldn't fail. */
        assert(NO);
        self->_authRef = NULL;
    }
    
    if (![self blessHelperWithLabel:@"com.apple.bsd.SMJobBlessHelper" error:&error]) {
        NSLog(@"Something went wrong! %@ / %d", [error domain], (int) [error code]);
    } else {
        /* At this point, the job is available. However, this is a very
         * simple sample, and there is no IPC infrastructure set up to
         * make it launch-on-demand. You would normally achieve this by
         * using XPC (via a MachServices dictionary in your launchd.plist).
         */
        NSLog(@"Job is available!");
        
        [self->_textField setHidden:false];
    }
}

- (void)itemClicked:(id)sender {
    //Look for control click, close app if so
    NSEvent *event = [NSApp currentEvent];
    if([event modifierFlags] & NSControlKeyMask) {
        [[NSApplication sharedApplication] terminate:self];
        return;
    }
    
    //Change theme
    [self toggleTheme];
    
    //Toggle darkMode
    self.darkModeOn = !self.darkModeOn;
    
    //Change desktop
    if (self.darkModeOn) {
        [self turnInternetOn];
    }
    else {
        [self turnInternetOff];
    }
    
    [self refreshDarkMode];
    [self turnInternetOff];
}

- (void)refreshDarkMode {
    NSString * value = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([value isEqualToString:@"Dark"]) {
        self.darkModeOn = YES;
    }
    else {
        self.darkModeOn = NO;
    }
}

- (void)toggleTheme {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"ThemeToggle" ofType:@"scpt"];
    NSURL* url = [NSURL fileURLWithPath:path];
    NSDictionary* errors = [NSDictionary dictionary];
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
    [appleScript executeAndReturnError:nil];
}

- (void)turnInternetOff {
    system("networksetup -setwebproxy Wi-Fi 192.168.1.100");
    system("networksetup -setsecurewebproxy Wi-Fi 192.168.1.100");
}

- (void)turnInternetOn {
    system("networksetup -setwebproxystate Wi-Fi off");
    system("networksetup -setsecurewebproxystate Wi-Fi off");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    //Attempt to restore things back the way we found them
    [self turnInternetOn];
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)errorPtr;
{
    BOOL result = NO;
    NSError * error = nil;
    
    AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights	= { 1, &authItem };
    AuthorizationFlags flags		=	kAuthorizationFlagDefaults				|
    kAuthorizationFlagInteractionAllowed	|
    kAuthorizationFlagPreAuthorize			|
    kAuthorizationFlagExtendRights;
    
    /* Obtain the right to install our privileged helper tool (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCopyRights(self->_authRef, &authRights, kAuthorizationEmptyEnvironment, flags, NULL);
    if (status != errAuthorizationSuccess) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    } else {
        CFErrorRef  cfError;
        
        /* This does all the work of verifying the helper tool against the application
         * and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        result = (BOOL) SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, self->_authRef, &cfError);
        if (!result) {
            error = CFBridgingRelease(cfError);
        }
    }
    if ( ! result && (errorPtr != NULL) ) {
        assert(error != nil);
        *errorPtr = error;
    }
    
    return result;
}

@end
