#import "AXExampleXPC.h"

@implementation NSArray (XPC)
+ (id)arrayFromXPC:(xpc_object_t)xpc
{
  if (xpc_get_type(xpc) == XPC_TYPE_ARRAY)
  {
    NSMutableArray * array = [NSMutableArray array];
    xpc_array_apply(xpc, ^bool(size_t index, xpc_object_t value) {
      [array insertObject:[NSObject objectFromXPC:value] atIndex:index];
      return true;
    });
    return [NSArray arrayWithArray:array];
  }
  else
    return nil;
}
- (xpc_object_t)xpc
{
  xpc_object_t array = xpc_array_create(NULL, 0);
  [self enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL * stop) {
    xpc_array_append_value(array, [object xpc]);
  }];
  return array;
}
@end

@implementation NSData (XPC)
+ (id)dataFromXPC:(xpc_object_t)xpc
{
  xpc_type_t type = xpc_get_type(xpc);
  
  if (type == XPC_TYPE_SHMEM)
    return nil; // NOT SUPPORTED
  else if (type == XPC_TYPE_DATA)
    return [NSData dataWithBytes:xpc_data_get_bytes_ptr(xpc) length:xpc_data_get_length(xpc)];
  else
    return nil;
}
- (xpc_object_t)xpc
{
  return xpc_data_create([self bytes], [self length]);
}
@end

@implementation NSDate (XPC)
+ (id)dateFromXPC:(xpc_object_t)xpc
{
  return xpc_get_type(xpc) == XPC_TYPE_DATE ? [NSDate dateWithTimeIntervalSince1970:xpc_date_get_value(xpc) / 1000000000] : nil;
}
- (xpc_object_t)xpc
{
  return xpc_date_create([self timeIntervalSince1970] * 1000000000);
}
@end

@implementation NSDictionary (XPC)
+ (id)dictionaryFromXPC:(xpc_object_t)xpc
{
  if (xpc_get_type(xpc) == XPC_TYPE_DICTIONARY)
  {
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    xpc_dictionary_apply(xpc, ^bool(const char * key, xpc_object_t value) {
      [dictionary setValue:[NSObject objectFromXPC:value] forKey:[NSString stringWithUTF8String:key]];
      return true;
    });
    return [NSDictionary dictionaryWithDictionary:dictionary];
  }
  else
    return nil;
}
- (void)mergeWithXPC:(xpc_object_t)dictionary
{
  [self enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL * stop) {
    xpc_dictionary_set_value(dictionary, [key UTF8String], [object xpc]);
  }];
}
- (xpc_object_t)xpc
{
  xpc_object_t dictionary = xpc_dictionary_create(NULL, NULL, 0);
  [self mergeWithXPC:dictionary];
  return dictionary;
}
@end

@implementation NSError (XPC)
+ (id)errorFromXPC:(xpc_object_t)xpc
{
  if (xpc_get_type(xpc) == XPC_TYPE_ERROR)
  {
    NSString * description = [NSString stringFromXPC:xpc_dictionary_get_value(xpc, XPC_ERROR_KEY_DESCRIPTION)];
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"XPC" code:0 userInfo:userInfo];
  }
  else
    return nil;
}
@end

@implementation NSFileHandle (XPC)
+ (id)fileHandleFromXPC:(xpc_object_t)xpc
{
  return xpc_get_type(xpc) == XPC_TYPE_FD ? [[NSFileHandle alloc] initWithFileDescriptor:xpc_fd_dup(xpc) closeOnDealloc:YES] : nil;
}
- (xpc_object_t)xpc
{
  return xpc_fd_create([self fileDescriptor]);
}
@end

@implementation NSObject (XPC)
+ (id)objectFromXPC:(xpc_object_t)xpc
{
  xpc_type_t type = xpc_get_type(xpc);
  
  if (type == XPC_TYPE_ARRAY)
    return [NSArray arrayFromXPC:xpc];
  else if (type == XPC_TYPE_BOOL || type == XPC_TYPE_DOUBLE || type == XPC_TYPE_INT64 || type == XPC_TYPE_UINT64)
    return [NSNumber numberFromXPC:xpc];
  else if (type == XPC_TYPE_DATA || type == XPC_TYPE_SHMEM)
    return [NSDate dateFromXPC:xpc];
  else if (type == XPC_TYPE_DATE)
    return [NSDate dateFromXPC:xpc];
  else if (type == XPC_TYPE_DICTIONARY)
    return [NSDictionary dictionaryFromXPC:xpc];
  else if (type == XPC_TYPE_ERROR)
    return [NSError errorFromXPC:xpc];
  else if (type == XPC_TYPE_FD)
    return [NSFileHandle fileHandleFromXPC:xpc];
  else if (type == XPC_TYPE_NULL)
    return nil;
  else if (type == XPC_TYPE_STRING)
    return [NSString stringFromXPC:xpc];
  else if (type == XPC_TYPE_UUID)
    return nil; // NOT SUPPORTED
  else
    return nil;
}
@end

@implementation NSNumber (XPC)
+ (id)numberFromXPC:(xpc_object_t)xpc
{
  xpc_type_t type = xpc_get_type(xpc);
  
  if (type == XPC_TYPE_BOOL)
    return [NSNumber numberWithBool:xpc_bool_get_value(xpc)];
  else if (type == XPC_TYPE_DOUBLE)
    return [NSNumber numberWithDouble:xpc_double_get_value(xpc)];
  else if (type == XPC_TYPE_INT64)
    return [NSNumber numberWithLong:xpc_int64_get_value(xpc)];
  else if (type == XPC_TYPE_UINT64)
    return [NSNumber numberWithUnsignedLong:xpc_uint64_get_value(xpc)];
  else
    return nil;
}
- (xpc_object_t)xpc
{
  if (self == (NSNumber *)kCFBooleanTrue)
    return xpc_bool_create(true);
  else if (self == (NSNumber *)kCFBooleanFalse)
    return xpc_bool_create(false);
  else
  {
    const char * type = [self objCType];
    if (strcmp(type, @encode(unsigned long)) == 0)
      return xpc_uint64_create([self unsignedLongValue]);
    else if (strcmp(type, @encode(long)) == 0)
      return xpc_int64_create([self longValue]);
    else
      return xpc_double_create([self doubleValue]);
  }
}
@end

@implementation NSString (XPC)
+ (id)stringFromXPC:(xpc_object_t)xpc
{
  return xpc_get_type(xpc) == XPC_TYPE_STRING ? [NSString stringWithUTF8String:xpc_string_get_string_ptr(xpc)] : nil;
}
- (xpc_object_t)xpc
{
  return xpc_string_create([self UTF8String]);
}
@end
