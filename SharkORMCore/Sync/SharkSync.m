//    MIT License
//
//    Copyright (c) 2016 SharkSync
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

#import "SharkORM+Private.h"
#import "SRKEntity+Private.h"
#import "SRKDefunctObject.h"
#import "SRKSyncOptions.h"
#import <CommonCrypto/CommonDigest.h>
#import "SRKAES256Extension.h"
#import "SharkORMCore-Swift.h"
#import "SRKSyncRegisteredClass.h"

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIImage.h>
typedef UIImage XXImage;
#else
#import <AppKit/NSImage.h>
typedef NSImage XXImage;
#endif

typedef enum : NSUInteger {
    SharkSyncOperationCreate = 1,     // a new object has been created
    SharkSyncOperationSet = 2,        // a value(s) have been set
    SharkSyncOperationDelete = 3,     // object has been removed from the store
    SharkSyncOperationIncrement = 4,  // value has been incremented - future implementation
    SharkSyncOperationDecrement = 5,  // value has been decremented - future implementation
} SharkSyncOperation;

@interface SharkSync ()

@property (strong) NSMutableDictionary* concurrentRecordGroups;

@end

@implementation SharkSync

+ (void)initServiceWithApplicationId:(NSString*)application_key apiKey:(NSString*)account_key {
    
    /* get the options object */
    SRKSyncOptions* options = [[[[SRKSyncOptions query] limit:1] fetch] firstObject];
    if (!options) {
        options = [SRKSyncOptions new];
        options.device_id = [[[NSUUID UUID] UUIDString] lowercaseString];
        [options commit];
    }
    
    SharkSync* sync = [SharkSync sharedObject];
    sync.applicationKey = application_key;
    sync.accountKeyKey = account_key;
    sync.deviceId = options.device_id;
    
    sync.settings = [SharkSyncSettings new];
    
}

+ (void)setSyncSettings:(SharkSyncSettings*) settings {
    [SharkSync setSyncSettings:settings];
}

+ (void)startSynchronisation {
    [SyncService StartService];
}

+ (void)synchroniseNow {
    [SyncService SynchroniseNow];
}

+ (void)stopSynchronisation {
    [SyncService StopService];
}

+ (instancetype)sharedObject {
    static id this = nil;
    if (!this) {
        this = [SharkSync new];
        ((SharkSync*)this).concurrentRecordGroups = [NSMutableDictionary new];
    }
    return this;
}

+ (NSString *)MD5FromString:(NSString *)inVar {
    
    const char * pointer = [inVar UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
    
    NSMutableString *string = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [string appendFormat:@"%02x",md5Buffer[i]];
    
    return string;
    
}

+ (void)addVisibilityGroup:(NSString *)visibilityGroup {
    
    // adds a visibility group to the table, to be sent with all sync requests.
    // AH originally wanted the groups to be set per class, but i think it's better that a visibility group be across all classes, much good idea for the dev
    
    if (![[[[SRKSyncGroup query] whereWithFormat:@"groupName = %@", [self MD5FromString:visibilityGroup]] limit:1] count]) {
        SRKSyncGroup* newGroup = [SRKSyncGroup new];
        newGroup.groupName = [self MD5FromString:visibilityGroup];
        newGroup.tidemark_uuid = @"";
        [newGroup commit];
    }
    
}

+ (void)removeVisibilityGroup:(NSString *)visibilityGroup {
    
    NSString* vg = [self MD5FromString:visibilityGroup];
    
    [[[[[SRKSyncGroup query] whereWithFormat:@"groupName = %@", vg]  limit:1] fetch] removeAll];
    
    // now we need to remove all the records which were part of this visibility group
    for (SRKSyncRegisteredClass* c in [[SRKSyncRegisteredClass query] fetch]) {
        NSString* sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE recordVisibilityGroup = '%@'", c.className, vg];
        // TODO: execute against all attached databases
        [SharkORM executeSQL:sql inDatabase:nil];
    }
    
    
}

+ (NSString*)getEffectiveRecordGroup {
    @synchronized ([SharkSync sharedObject].concurrentRecordGroups) {
        return [[SharkSync sharedObject].concurrentRecordGroups objectForKey:[NSString stringWithFormat:@"%@", [NSThread currentThread]]];
    }
}

+ (void)setEffectiveRecorGroup:(NSString*)group {
    [[SharkSync sharedObject].concurrentRecordGroups setObject:group forKey:[NSString stringWithFormat:@"%@", [NSThread currentThread]]];
}

+ (void)clearEffectiveRecordGroup {
    [[SharkSync sharedObject].concurrentRecordGroups removeObjectForKey:[NSString stringWithFormat:@"%@", [NSThread currentThread]]];
}

+ (id)decryptValue:(NSString*)value {
    
    // the problem with base64 is that it can contain "/" chars!
    if (!value) {
        return nil;
    }
    if (![value containsString:@"/"]) {
        return nil;
    }
    
    NSRange r = [value rangeOfString:@"/"];
    NSString* type = [value substringToIndex:r.location];
    NSString* data = [value substringFromIndex:r.location+1];
    
    NSData* dValue = [[NSData alloc] initWithBase64EncodedString:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    // call the block in the sync settings to encrypt the data
    SharkSync* sync = [SharkSync sharedObject];
    SharkSyncSettings* settings = sync.settings;
    
    dValue = settings.decryptBlock(dValue);
    
    
    if ([type isEqualToString:@"text"]) {
        
        // turn the data back to a string
        NSString* sValue = [[NSString alloc] initWithData:dValue encoding:NSUnicodeStringEncoding];
        
        return sValue;
        
    } else if ([type isEqualToString:@"number"]) {
        
        // turn the data back to a string
        NSString* sValue = [[NSString alloc] initWithData:dValue encoding:NSUnicodeStringEncoding];
        
        // now turn the sValue back to it's original value
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        return [f numberFromString:sValue];
        
    } else if ([type isEqualToString:@"date"]) {
        
        // turn the data back to a string
        NSString* sValue = [[NSString alloc] initWithData:dValue encoding:NSUnicodeStringEncoding];
        
        // now turn the sValue back to it's original value
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        return [NSDate dateWithTimeIntervalSince1970:[f numberFromString:sValue].doubleValue];
        
    } else if ([type isEqualToString:@"bytes"]) {
        
        return dValue;
        
    } else if ([type isEqualToString:@"image"]) {
        
        // turn the data back to an image
        return [UIImage imageWithData:dValue];
        
    } else if ([type isEqualToString:@"mdictionary"] || [type isEqualToString:@"dictionary"] || [type isEqualToString:@"marray"] || [type isEqualToString:@"array"]) {
        
        NSError* error;
        
        if ([type isEqualToString:@"mdictionary"]) {
            
            return [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:dValue options:NSJSONReadingMutableLeaves error:&error]];
            
        } else if ([type isEqualToString:@"dictionary"]) {
            
            return [NSDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:dValue options:NSJSONReadingMutableLeaves error:&error]];
            
        } else if ([type isEqualToString:@"array"]) {
            
            return [NSArray arrayWithArray:[NSJSONSerialization JSONObjectWithData:dValue options:NSJSONReadingMutableLeaves error:&error]];
            
        } else if ([type isEqualToString:@"marray"]) {
            
            return [NSMutableArray arrayWithArray:[NSJSONSerialization JSONObjectWithData:dValue options:NSJSONReadingMutableLeaves error:&error]];
            
        }
        
        
    }  else if ([type isEqualToString:@"entity"]) {
        
        NSData* dValue = [[NSData alloc] initWithBase64EncodedData:[NSData dataWithBytes:data.UTF8String length:data.length] options:0];
        
        // call the block in the sync settings to encrypt the data
        SharkSync* sync = [SharkSync sharedObject];
        SharkSyncSettings* settings = sync.settings;
        
        dValue = settings.decryptBlock(dValue);
        
        // turn the data back to a string
        NSString* sValue = [[NSString alloc] initWithData:dValue encoding:NSUnicodeStringEncoding];
        
        // now turn the sValue back to it's original value
        return sValue;
        
    }
    
    return nil;
    
}

+ (void)queueObject:(SRKSyncObject *)object withChanges:(NSMutableDictionary*)changes withOperation:(SharkSyncOperation)operation inHashedGroup:(NSString*)group {
    
    if (![[[SRKSyncRegisteredClass query] whereWithFormat:@"className = %@", [object.class description]] count]) {
        SRKSyncRegisteredClass* c = [SRKSyncRegisteredClass new];
        c.className = [object.class description];
        [c commit];
    }
    
    if (operation == SharkSyncOperationCreate || operation == SharkSyncOperationSet) {
        
        /* we have an object so look at the modified fields and queue the properties that have been set */
        for (NSString* property in changes.allKeys) {
            
            // exclude the group and ID keys
            if (![property isEqualToString:@"Id"] && ![property isEqualToString:@"recordVisibilityGroup"]) {
                
                /* because all values are encrypted by the client before being sent to the server, we need to convert them into NSData,
                 to be encrypted however the developer wants, using any method */
                
                id value = [changes objectForKey:property];
                NSString* type = nil;
                
                if (value) {
                    if ([value isKindOfClass:[NSString class]]) {
                        
                        type = @"text";
                        
                        NSData* dValue = [((NSString*)value) dataUsingEncoding: NSUnicodeStringEncoding];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        
                        type = @"number";
                        NSData* dValue = [[NSString stringWithFormat:@"%@", value] dataUsingEncoding: NSUnicodeStringEncoding];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSDate class]]) {
                        
                        type = @"date";
                        
                        NSData* dValue = [[NSString stringWithFormat:@"%@", @(((NSDate*)value).timeIntervalSince1970)] dataUsingEncoding: NSUnicodeStringEncoding];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSData class]]) {
                        
                        type = @"bytes";
                        
                        NSData* dValue = (NSData*)value;
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[XXImage class]]) {
                        
                        type = @"image";
                        
                        NSData* dValue = UIImageJPEGRepresentation(((XXImage*)value), 0.6);
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]]) {
                        
                        if ([value isKindOfClass:[NSMutableDictionary class]]) {
                            type = @"mdictionary";
                        } else if ([value isKindOfClass:[NSMutableArray class]]) {
                            type = @"marray";
                        } else if ([value isKindOfClass:[NSDictionary class]]) {
                            type = @"dictionary";
                        } else if ([value isKindOfClass:[NSArray class]]) {
                            type = @"array";
                        }
                        
                        NSError* error;
                        NSData* dValue = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&error];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[SRKEntity class]]) {
                        
                        type = @"entity";
                        
                        NSData* dValue = [[NSString stringWithFormat:@"%@", ((SRKSyncObject*)value).Id] dataUsingEncoding: NSUnicodeStringEncoding];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSNull class]]) {
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = [[NSDate date] timeIntervalSince1970];
                        change.value = nil;
                        [change commit];
                        
                    }
                    
                }
                
            }
            
        }
    } else if (operation == SharkSyncOperationDelete) {
        
        SharkSyncChange* change = [SharkSyncChange new];
        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], @"__delete__"];
        change.action = operation;
        change.recordGroup = group;
        change.timestamp = [[NSDate date] timeIntervalSince1970];
        [change commit];
        
    }
    
}

@end

@implementation SharkSyncSettings

- (instancetype)init {
    self = [super init];
    if (self) {
        
        // these are just defaults to ensure all data is encrypted, it is reccommended that you develop your own or at least set your own aes256EncryptionKey value.
        
        self.autoSubscribeToGroupsWhenCommiting = YES;
        self.aes256EncryptionKey = [SharkSync sharedObject].applicationKey;
        self.encryptBlock = ^NSData*(NSData* dataToEncrypt) {
            
            SharkSync* sync = [SharkSync sharedObject];
            SharkSyncSettings* settings = sync.settings;
            
            return [dataToEncrypt SRKAES256EncryptWithKey:settings.aes256EncryptionKey];
            
        };
        self.decryptBlock = ^NSData*(NSData* dataToDecrypt) {
            
            SharkSync* sync = [SharkSync sharedObject];
            SharkSyncSettings* settings = sync.settings;
            
            return [dataToDecrypt SRKAES256DecryptWithKey:settings.aes256EncryptionKey];
            
        };
    }
    return self;
}

@end
