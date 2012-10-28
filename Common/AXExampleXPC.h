#import <Foundation/Foundation.h>
#import <xpc/xpc.h>

@interface NSArray (XPC)
+ (id)arrayFromXPC:(xpc_object_t)xpc;
- (xpc_object_t)xpc;
@end

@interface NSData (XPC)
+ (id)dataFromXPC:(xpc_object_t)xpc;
- (xpc_object_t)xpc;
@end

@interface NSDate (XPC)
+ (id)dateFromXPC:(xpc_object_t)xpc;
- (xpc_object_t)xpc;
@end

@interface NSDictionary (XPC)
+ (id)dictionaryFromXPC:(xpc_object_t)xpc;
- (void)mergeWithXPC:(xpc_object_t)dictionary;
- (xpc_object_t)xpc;
@end

@interface NSError (XPC)
+ (id)errorFromXPC:(xpc_object_t)xpc;
@end

@interface NSFileHandle (XPC)
+ (id)fileHandleFromXPC:(xpc_object_t)xpc;
- (xpc_object_t)xpc;
@end

@interface NSObject (XPC)
+ (id)objectFromXPC:(xpc_object_t)xpc;
@end

@interface NSNumber (XPC)
+ (id)numberFromXPC:(xpc_object_t)xpc;
- (xpc_object_t)xpc;
@end

@interface NSString (XPC)
+ (id)stringFromXPC:(xpc_object_t)xpc;
- (xpc_object_t)xpc;
@end
