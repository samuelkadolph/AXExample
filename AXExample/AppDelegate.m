#import "AppDelegate.h"
#import "AXExamplePrivilegedHelper.h"

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (IBAction)checkAX:(id)sender
{
  NSLog(@"AXAPIEnabled=%@ AXIsProcessTrusted=%@", AXAPIEnabled() ? @"YES" : @"NO", AXIsProcessTrusted() ? @"YES" : @"NO");
}
- (IBAction)installHelper:(id)sender
{
  if (![AXExamplePrivilegedHelper isInstalled])
  {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    NSError * error;
    if (![AXExamplePrivilegedHelper install:&error])
    {
      [[NSAlert alertWithError:error] runModal];
    }
  }
}
- (IBAction)authorize:(id)sender
{
  AXExamplePrivilegedHelper * helper = [AXExamplePrivilegedHelper helper];
  
  [helper authorize:[[NSBundle mainBundle] executablePath] callback:^(BOOL result) {
    if (result)
      NSLog(@"authorized! should relaunch");
    else
      NSLog(@"authorize failed");
  } errorCallback:^(NSString * message) {
    NSLog(@"error=%@", message);
  }];
}
@end
