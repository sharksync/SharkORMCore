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

#import <Foundation/Foundation.h>
#import "SharkORM.h"

typedef unsigned int SRKPropertyType;

typedef enum : NSUInteger {
    Undefined = 0,
    CreateTable = 1,
    AddColumn = 2,
    RemoveColumn = 3,
} SchemaChangeOperation;

@interface SchemaStruct : NSObject

@property (nonatomic) NSString* db;
@property (nonatomic) NSString* entity;
@property (nonatomic) NSString* pk;
@property (nonatomic) NSMutableDictionary<NSString*,NSNumber*>* fields;
@property (nonatomic) NSMutableDictionary<NSString*,NSString*>* indexes;

@end

typedef NSMutableArray<SRKRelationship*>* SRKArrayRelationships;
typedef NSDictionary<NSString*, SchemaStruct*>* SRKSchemaStructDictionary;
typedef NSDictionary<NSString*, NSString*>* SRKSchemaIndexDefinitionsDictionary;

@interface SchemaManager : NSObject

+ (instancetype)sharedSchemaManager;

// relationships
@property (nonatomic) SRKArrayRelationships relationships;

- (SRKArrayRelationships)relationshipsForEntity:(NSString*)entity;
- (SRKArrayRelationships)relationshipsForEntity:(NSString*)entity forType:(SRKPropertyType)type;
- (SRKArrayRelationships)relationshipsForEntity:(NSString*)entity forProperty:(NSString*)property;
- (void)relationshipAdd:(SRKRelationship*)relationship;

// structure/schema
@property (nonatomic) SRKSchemaStructDictionary schemas;

- (BOOL)schemaPropertyExistsForEntity:(NSString*)entity property:(NSString*)property;
- (NSArray<NSString*>*)schemaPropertiesForEntity:(NSString*)entity;
- (SRKPropertyType)schemaPropertyTypeForEntity:(NSString*)entity property:(NSString*)property;
- (void)schemaSetEntity:(NSString*)entity property:(NSString*)property type:(SRKPropertyType)type;
- (void)schemaSetEntity:(NSString*)entity pk:(NSString*)pk;
- (void)schemaSetEntity:(NSString*)entity database:(NSString*)database;
- (NSArray<NSString*>*)schemaTablesForEntity:(NSString*)entity;
- (NSString*)schemaPrimaryKeyForEntity:(NSString*)entity;
- (SRKPropertyType)schemaPrimaryKeyTypeForEntity:(NSString*)entity;
- (void)schemaAddIndexDefinitionForEntity:(NSString*)entity name:(NSString*)name definition:(NSString*)definition;
- (SRKSchemaIndexDefinitionsDictionary)schemaIndexDefinitionsForEntity:(NSString*)entity;
- (void)schemaUpdateMissingDatabaseEntriesForDatabase:(NSString*)database;

//database
@property (nonatomic) SRKSchemaStructDictionary databsaes;

- (BOOL)databasePropertyExistsForEntity:(NSString*)entity property:(NSString*)property;
- (NSArray<NSString*>*)databasePropertiesForEntity:(NSString*)entity;
- (SRKPropertyType)databasePropertyTypeForEntity:(NSString*)entity property:(NSString*)property;
- (void)databaseSetForEntity:(NSString*)entity property:(NSString*)property type:(SRKPropertyType)type;
- (void)databaseSetForEntity:(NSString*)entity database:(NSString*)database;
- (void)databaseSetFroEntity:(NSString*)entity pk:(NSString*)pk;
- (NSArray<NSString*>*)databaseTablesForDatabase:(NSString*)database;
- (NSString*)databasePrimaryKeyForEntity:(NSString*)entity;
- (SRKPropertyType)databasePrimaryKeyTypeForEntity:(NSString*)entity;
- (void)databaseAddIndexDefinitionForEntity:(NSString*)entity name:(NSString*)name definition:(NSString*)definition;
- (SRKSchemaIndexDefinitionsDictionary)databaseIndexDefinitionsForEntity:(NSString*)entity;



@end
