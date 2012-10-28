#import <Foundation/Foundation.h>

NSString * kAXExamplePrivilegedHelperLabel;
NSString * kAXExamplePrivilegedHelperMachServiceName;

NSString * kAXExamplePrivilegedHelperActionKey;
NSString * kAXExamplePrivilegedHelperActionAuthorize;
NSString * kAXExamplePrivilegedHelperExecutablePathKey;
NSString * kAXExamplePrivilegedHelperMessageKey;
NSString * kAXExamplePrivilegedHelperResultKey;

typedef void(^AXExamplePrivilegedHelperErrorCallback)(NSString * message);
typedef void(^AXExamplePrivilegedHelperAuthorizeCallback)(BOOL result);
typedef void(^AXExamplePrivilegedHelperSendCallback)(NSDictionary * result);

const char * AXExamplePrivilegedHelperSerializeDictionary(NSDictionary * dictionary, NSError ** error);
NSDictionary * AXExamplePrivilegedHelperDeserializeDictionary(const char * dictionary, NSError ** error);

@interface AXExamplePrivilegedHelper : NSObject
{
  xpc_connection_t connection;
}

+ (id)helper;
+ (id)helperAndInstallIfNotInstalled:(NSError **)error;

+ (BOOL)install:(NSError **)error;
+ (BOOL)isInstalled;

- (void)resume;
- (void)suspend;

- (void)authorize:(NSString *)executablePath callback:(AXExamplePrivilegedHelperAuthorizeCallback)callback errorCallback:(AXExamplePrivilegedHelperErrorCallback)error;
- (void)send:(NSDictionary *)payload callback:(AXExamplePrivilegedHelperSendCallback)callback errorCallback:(AXExamplePrivilegedHelperErrorCallback)error;
@end
