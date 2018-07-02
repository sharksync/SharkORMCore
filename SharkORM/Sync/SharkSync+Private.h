//    MIT License
//
//    Copyright (c) 2010-2018 SharkSync
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



#ifndef SharkSync_Private_h
#define SharkSync_Private_h

#import "SharkORM.h"
#import "SRKSyncObject+Private.h"
#import "SRKEntity+Private.h"
#import "SharkORM+Private.h"
#import "SharkSync+Private.h"
#import "SRKDefunctObject.h"
#import "SRKDeferredChange.h"

typedef enum : NSUInteger {
    SharkSyncOperationCreate = 1,     // a new object has been created
    SharkSyncOperationSet = 2,        // a value(s) have been set
    SharkSyncOperationDelete = 3,     // object has been removed from the store
    SharkSyncOperationIncrement = 4,  // value has been incremented - future implementation
    SharkSyncOperationDecrement = 5,  // value has been decremented - future implementation
} SharkSyncOperation;

@interface SharkSync ()

@property (strong, nullable) NSMutableDictionary* concurrentRecordGroups;
@property (strong, nullable) SharkSyncSettings* settings;
@property (strong, nullable) NSString* applicationKey;
@property (strong, nullable) NSString* accountKeyKey;
@property (strong, nullable) NSString* deviceId;

+ (nonnull NSString*)MD5FromString:(nonnull NSString*)inVar;
+ (nonnull NSString*)getEffectiveRecordGroup;
+ (void)setEffectiveRecorGroup:(nonnull NSString*)group;
+ (void)clearEffectiveRecordGroup;
+ (nullable id)decryptValue:(nonnull NSString*)value;
+ (void)queueObject:(nonnull SRKEntity *)object withChanges:(nullable NSMutableDictionary*)changes withOperation:(SharkSyncOperation)operation inHashedGroup:(nonnull NSString*)group;
+ (nonnull instancetype)sharedObject;

@end

#endif /* SharkSync_Private_h */
