//
//  AppDelegate.m
//  SMJobBless
//
//  Created by Ted Wei on 06/02/2017.
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

//@property (weak) IBOutlet NSWindow *window;

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (assign, nonatomic) BOOL darkModeOn;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"switchIcon.png"];
    [self.statusItem.image setTemplate:YES];
    
    self.statusItem.highlightMode = NO;
    self.statusItem.toolTip = @"control-click to quit";
    
    [self.statusItem setAction:@selector(itemClicked:)];
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

@end
