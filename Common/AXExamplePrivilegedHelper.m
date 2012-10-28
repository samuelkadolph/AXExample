#import <Security/Security.h>
#import <ServiceManagement/ServiceManagement.h>
#import "AXExamplePrivilegedHelper.h"
#import "AXExampleXPC.h"

#define XPC_ERROR_DESCRIPTION(dictionary) [NSString stringWithCString:xpc_dictionary_get_string(dictionary, XPC_ERROR_KEY_DESCRIPTION) encoding:NSASCIIStringEncoding]

static NSString * AuthorizationCreateStatusToString(OSStatus status)
{
  switch (status)
  {
    case errAuthorizationDenied:   return @"";
    case errAuthorizationCanceled: return @"";
    default:                       return @"";
  }
}

NSString * kAXExamplePrivilegedHelperLabel = @"com.samuelkadolph.AXExamplePrivilegedHelper";
NSString * kAXExamplePrivilegedHelperMachServiceName = @"com.samuelkadolph.AXExamplePrivilegedHelper";

NSString * kAXExamplePrivilegedHelperActionKey = @"Action";
NSString * kAXExamplePrivilegedHelperActionAuthorize = @"Authorize";
NSString * kAXExamplePrivilegedHelperExecutablePathKey = @"ExecutablePath";
NSString * kAXExamplePrivilegedHelperMessageKey = @"Message";
NSString * kAXExamplePrivilegedHelperResultKey = @"Result";

@implementation AXExamplePrivilegedHelper
+ (id)helper
{
  return [[self alloc] init];
}
+ (id)helperAndInstallIfNotInstalled:(NSError **)error
{
  if (![self isInstalled])
    if (![self install:error])
      return nil;
  
  return [self helper];
}

+ (BOOL)install:(NSError **)error
{
  AuthorizationItem item = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
  AuthorizationRights rights = { 1, &item };
  AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize;
	AuthorizationRef auth;
  OSStatus status;
  
  if ((status = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &auth) != errAuthorizationSuccess))
  {
    NSDictionary * info = [NSDictionary dictionaryWithObject:AuthorizationCreateStatusToString(status) forKey:NSLocalizedDescriptionKey];
    *error = [NSError errorWithDomain:kAXExamplePrivilegedHelperLabel code:0 userInfo:info];
    NSLog(@"AuthorizationCreate failed: %d", status);
    return NO;
	}
  
  CFErrorRef cfError;
  if (!SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)kAXExamplePrivilegedHelperLabel, auth, &cfError))
  {
    *error = (__bridge NSError *)cfError;
    NSLog(@"SMJobBless failed: %@", [*error description]);
    return NO;
  }
  
  NSLog(@"AXExamplePrivilegedHelper installed");
  return YES;
}
+ (BOOL)isInstalled
{
  return NO; // TODO
}


- (id)init
{
  if (self = [super init])
  {
    connection = xpc_connection_create_mach_service([kAXExamplePrivilegedHelperMachServiceName UTF8String], NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
      // TODO
      //      if (errorCallback) errorCallback(@"error");
    });
    xpc_connection_resume(connection);
  }
  
  return self;
}

- (void)resume
{
  xpc_connection_resume(connection);
}
- (void)suspend
{
  xpc_connection_suspend(connection);
}

- (void)authorize:(NSString *)executablePath callback:(AXExamplePrivilegedHelperAuthorizeCallback)callback errorCallback:(AXExamplePrivilegedHelperErrorCallback)error
{
  NSMutableDictionary * payload = [NSMutableDictionary dictionary];
  [payload setValue:kAXExamplePrivilegedHelperActionAuthorize forKey:kAXExamplePrivilegedHelperActionKey];
  [payload setValue:executablePath forKey:kAXExamplePrivilegedHelperExecutablePathKey];
  
  [self send:payload callback:^(NSDictionary * result) {
    callback([[result objectForKey:kAXExamplePrivilegedHelperResultKey] boolValue]);
  } errorCallback:error];
}
- (void)send:(NSDictionary *)payload callback:(AXExamplePrivilegedHelperSendCallback)callback errorCallback:(AXExamplePrivilegedHelperErrorCallback)error
{
  xpc_connection_send_message_with_reply(connection, [payload xpc], dispatch_get_main_queue(), ^(xpc_object_t reply) {
    xpc_type_t type = xpc_get_type(reply);
    
    if (type == XPC_TYPE_ERROR)
    {
      NSLog(@"reply error: %@", [NSError errorFromXPC:reply]);
    }
    else if (type == XPC_TYPE_DICTIONARY)
    {
      callback([NSDictionary dictionaryFromXPC:reply]);
    }
  });
}
@end
