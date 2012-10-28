#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>
#import "AXExamplePrivilegedHelper.h"
#import "AXExampleXPC.h"

static BOOL authorize_application(NSString * executablePath, NSString ** message)
{
  AXError error = AXMakeProcessTrusted((__bridge CFStringRef)executablePath);
  return error == kAXErrorSuccess;
}

static NSDictionary * client_handler(NSString * action, NSDictionary * payload)
{
  NSString * message = @"";
  BOOL result = NO;
  
  if ([action isEqualToString:kAXExamplePrivilegedHelperActionAuthorize])
  {
    NSString * executablePath = [payload valueForKey:kAXExamplePrivilegedHelperExecutablePathKey];
    result = authorize_application(executablePath, &message);
  }
  else
  {
    message = @"Unknown action";
    result = NO;
  }
  
  NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithBool:result] forKey:kAXExamplePrivilegedHelperResultKey];
  [dictionary setValue:message forKey:kAXExamplePrivilegedHelperMessageKey];
  
  return [NSDictionary dictionaryWithDictionary:dictionary];
}

static void client_event_handler(xpc_connection_t client, xpc_object_t event)
{
  @autoreleasepool
  {
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_ERROR)
    {
      NSLog(@"client_event_handler client=%p error=%@", client, [NSError errorFromXPC:event]);
    }
    else if (type == XPC_TYPE_DICTIONARY)
    {
      NSDictionary * payload = [NSDictionary dictionaryFromXPC:event];
      NSLog(@"client_event_handler client=%p dictionary=%@", client, payload);
      
      NSDictionary * result = client_handler([payload valueForKey:kAXExamplePrivilegedHelperActionKey], payload);
      xpc_object_t reply = xpc_dictionary_create_reply(event);
      [result mergeWithXPC:reply];
      xpc_connection_send_message(client, reply);
    }
  }
}

static void service_event_handler(xpc_connection_t service, xpc_object_t event)
{
  @autoreleasepool
  {
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_ERROR)
    {
      NSLog(@"service_event_handler error=%@", [NSError errorFromXPC:event]);
    }
    else if (type == XPC_TYPE_CONNECTION)
    {
      NSLog(@"service_event_handler connection=%p", event);
      xpc_connection_set_event_handler(event, ^(xpc_object_t object) { client_event_handler(event, object); });
      xpc_connection_resume(event);
    }
  }
}

int main(int argc, const char * argv[])
{
  @autoreleasepool
  {
    NSLog(@"starting");
    xpc_connection_t service = xpc_connection_create_mach_service([kAXExamplePrivilegedHelperMachServiceName UTF8String], NULL, XPC_CONNECTION_MACH_SERVICE_LISTENER);
    xpc_connection_set_event_handler(service, ^(xpc_object_t object) { service_event_handler(service, object); });
    xpc_connection_resume(service);
    
    NSLog(@"started");
    dispatch_main();
    
    return 0;
  }
}

