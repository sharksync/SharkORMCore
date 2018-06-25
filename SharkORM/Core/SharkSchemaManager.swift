//    MIT License
//
//    Copyright (c) 2017 SharkSync
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

/*
 *    The Schema class is designed to replace the JIT refactoring of the orginal ORM,
 *      there is now separation between the creation of teh current schema and the
 *      eventual schema that will be required when the database is finally opened.
 */

import Foundation

public enum SharkSchemaChangeOperation {
    case Undefined
    case CreateTable
    case AddColumn
    case RemoveColumn
}

public struct SharkSchemaStruct {
    
    var db: String?
    var entity: String = ""
    var pk: String = ""
    var fields: [String:Int] = [:]
    var indexes: [String:String] = [:]
    
}

@objc public class SharkSchemaManager : NSObject {
    
    private static var sharedSchemaManager: SharkSchemaManager = {
        let schemaManager = SharkSchemaManager()
        return schemaManager
    }()
    
    @objc public class func shared() -> SharkSchemaManager {
        return sharedSchemaManager
    }
    
    //MARK: - Relationships
    private var relationships: [SRKRelationship] = []
    
    @objc public func relationships(entity: String) -> [SRKRelationship] {
        
        var results: [SRKRelationship] = []
        for r in relationships {
            if r.sourceClass.description() == entity {
                results.append(r)
            }
        }
        
        return results
        
    }
    
    @objc public func relationships(entity: String, type: Int32) -> [SRKRelationship] {
        
        var results: [SRKRelationship] = []
        let relationshipsForEntity = relationships(entity: entity)
        for r in relationshipsForEntity {
            if r.relationshipType == type {
                results.append(r)
            }
        }
        return results
        
    }
    
    @objc public func relationships(entity: String, property: String) -> SRKRelationship? {
        
        var results: [SRKRelationship] = []
        let relationshipsForEntity = relationships(entity: entity)
        for r in relationshipsForEntity {
            if r.sourceProperty ?? "" == property {
                results.append(r)
            }
        }
        if results.count > 0 {
            return results[0]
        } else {
            return nil
        }
        
    }
    
    @objc public func relationshipAdd(_ relationship: SRKRelationship) {
        relationships.append(relationship)
    }
    
    //MARK: - Structure
    private var schemas: [String:SharkSchemaStruct] = [:]
    
    @objc public func schemaPropertyExists(entity: String, property:String) -> Bool {
        
        if schemas[entity] != nil {
            let schema = schemas[entity]! as SharkSchemaStruct
            for f in schema.fields.keys {
                if f == property {
                    return true
                }
            }
        }
        
        return false
    }
    
    @objc public func schemaPropertiesForEntity(_ entity: String) -> [String] {
        
        var results: [String] = []
        
        if schemas[entity] != nil {
            let schema = schemas[entity]! as SharkSchemaStruct
            for f in schema.fields.keys {
                results.append(f)
            }
        }
        
        return results
        
    }
    
    @objc public func schemaPropertyType(entity: String, property: String) -> Int {
        if schemas[entity] != nil {
            let schema = schemas[entity]! as SharkSchemaStruct
            return schema.fields[property] ?? 0
        }
        return 0
    }
    
    @objc public func schemaSet(entity: String, property: String, type: Int) {
        var schema = schemas[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            schemas[entity] = schema
        }
        schema?.fields[property] = type
        schemas[entity] = schema
    }
    
    @objc public func schemaSet(entity: String, pk: String) {
        
        var schema = schemas[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            schemas[entity] = schema
        }
        schema?.pk = pk
        schemas[entity] = schema
        
        // register the index for this 
        
    }
    
    @objc public func schemaSet(entity: String, database: String?) {
        var schema = schemas[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            schemas[entity] = schema
        }
        schema?.db = database
        schemas[entity] = schema
    }
    
    @objc public func schemaTables(database: String?) -> [String] {
        
        var returnValues: [String] = []
        
        for s in schemas.keys.sorted() {
            if schemas[s]?.db == database && schemas[s]?.entity != nil {
                returnValues.append(schemas[s]!.entity)
            }
        }
        
        return returnValues
    }
    
    @objc public func schemaPrimaryKey(entity: String) -> String? {
        
        let schema = schemas[entity]
        if schema != nil {
            return schema?.pk
        }
        
        return nil
        
    }
    
    @objc public func schemaPrimaryKeyType(entity: String) -> Int {
        
        let schema = schemas[entity]
        if schema != nil {
            return schema!.fields[schema!.pk] ?? Int(SRK_PROPERTY_TYPE_NUMBER)
        }
        
        return Int(SRK_PROPERTY_TYPE_NUMBER) // SQLITE_INTEGER
        
    }
    
    @objc public func schemaAddIndexDefinition(entity: String, name: String, definition: String) {
        var schema = schemas[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            schemas[entity] = schema
        }
        schema?.indexes[name] = definition
        schemas[entity] = schema
    }
    
    @objc public func schemaIndexDefinitions(entity: String) -> [String:String] {
        
        let schema = schemas[entity]
        if schema != nil {
            return schema!.indexes
        }
        
        return [:]
        
    }
    
    @objc public func schemaUpdateMissingDatabaseEntries(database: String?) {
        
        if database == nil {
            return
        }
        
        for s in schemas {
            if schemas[s.key]?.db == nil {
                schemas[s.key]?.db = database
            }
        }
        
    }
    
    //MARK: - Database
    private var databases: [String:SharkSchemaStruct] = [:]
    
    
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    @objc public func databasePropertyExists(entity: String, property:String) -> Bool {
        
        if databases[entity] != nil {
            let schema = databases[entity]! as SharkSchemaStruct
            for f in schema.fields.keys {
                if f == property {
                    return true
                }
            }
        }
        
        return false
    }
    
    @objc public func databasePropertiesForEntity(_ entity: String) -> [String] {
        
        var results: [String] = []
        
        if databases[entity] != nil {
            let schema = databases[entity]! as SharkSchemaStruct
            for f in schema.fields.keys {
                results.append(f)
            }
        }
        
        return results
        
    }
    
    @objc public func databasePropertyType(entity: String, property: String) -> Int {
        if databases[entity] != nil {
            let schema = databases[entity]! as SharkSchemaStruct
            return schema.fields[property] ?? 0
        }
        return 0
    }
    
    @objc public func databaseSet(entity: String, property: String, type: Int) {
        var schema = databases[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            databases[entity] = schema
        }
        schema?.fields[property] = type
        databases[entity] = schema
    }
    
    @objc public func databaseSet(entity: String, database: String) {
        var schema = databases[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            databases[entity] = schema
        }
        schema?.db = database
        databases[entity] = schema
    }
    
    @objc public func databaseSet(entity: String, pk: String) {
        var schema = databases[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            databases[entity] = schema
        }
        schema?.pk = pk
        databases[entity] = schema
    }
    
    @objc public func databaseTables(_ database: String) -> [String] {
        
        var retValues: [String] = []
        
        for d in databases {
            if d.value.db == database {
                retValues.append(d.value.entity)
            }
        }
        
        return retValues
        
    }
    
    @objc public func databasePrimaryKey(entity: String) -> String? {
        
        let schema = databases[entity]
        if schema != nil {
            return schema?.pk
        }
        
        return nil
        
    }
    
    @objc public func databasePrimaryKeyType(entity: String) -> Int {
        
        let schema = databases[entity]
        if schema != nil {
            return schema!.fields[schema!.pk] ?? 1
        }
        
        return Int(SQLITE_INTEGER)
        
    }
    
    @objc public func databaseAddIndexDefinition(entity: String, name: String, definition: String) {
        var schema = databases[entity]
        if schema == nil {
            schema = SharkSchemaStruct()
            schema?.entity = entity
            databases[entity] = schema
        }
        schema?.indexes[name] = definition
        databases[entity] = schema
    }
    
    @objc public func databaseIndexDefinitions(entity: String) -> [String:String] {
        
        let schema = databases[entity]
        if schema != nil {
            return schema!.indexes
        }
        
        return [:]
        
    }
    
    //MARK: - Refactoring
    func reloadDatabaseSchema(database: String) {
        
        let handle = SRKGlobals.sharedObject().handle(forName: database)
        let db = OpaquePointer(handle)
        var tableNames: OpaquePointer?
        let tablesSql = "SELECT name FROM sqlite_master WHERE type='table';"
        if sqlite3_prepare_v2(db, tablesSql , Int32(tablesSql.utf8.count), &tableNames, nil) == SQLITE_OK {
            
            while sqlite3_step(tableNames) == SQLITE_ROW {
                
                let table = String.init(cString:sqlite3_column_text(tableNames, Int32(0)))
                var columnNames: OpaquePointer?
                let columnSql = "PRAGMA table_info(\(table));"
                
                SharkSchemaManager.shared().databaseSet(entity: table, database: database)
                
                if sqlite3_prepare_v2(db, columnSql , Int32(columnSql.utf8.count), &columnNames, nil) == SQLITE_OK {
                    
                    while sqlite3_step(columnNames) == SQLITE_ROW {
                        
                        let field = String.init(cString:sqlite3_column_text(columnNames, Int32(1)))
                        let type = String.init(cString:sqlite3_column_text(columnNames, Int32(2)))
                        let pk = Int(sqlite3_column_int64(columnNames, Int32(5)))
                        let typeEnum = sqlTextTypeToInt(type)
                        
                        // now update the database schemas in memory
                        SharkSchemaManager.shared().databaseSet(entity: table, property: field, type: typeEnum)
                        if pk != 0 {
                            SharkSchemaManager.shared().databaseSet(entity: table, pk: field)
                        }
                        
                    }
                }
                sqlite3_finalize(columnNames)
                
                // now grab the indexes out too
                
                var indexNames: OpaquePointer?
                let indexSql = "SELECT name,sql FROM sqlite_master WHERE tbl_name = '\(table)' AND type = 'index' AND sql IS NOT NULL;"
                
                if sqlite3_prepare_v2(db, indexSql , Int32(indexSql.utf8.count), &indexNames, nil) == SQLITE_OK {
                    
                    while sqlite3_step(indexNames) == SQLITE_ROW {
                        
                        let name = String.init(cString:sqlite3_column_text(indexNames, Int32(0)))
                        let sql = String.init(cString:sqlite3_column_text(indexNames, Int32(1)))
                        
                        SharkSchemaManager.shared().databaseAddIndexDefinition(entity: table, name: name, definition: sql)
                        
                    }
                }
                sqlite3_finalize(indexNames)
                
            }
        }
        
        sqlite3_finalize(tableNames)
        
    }
    
    func sqlTextTypeToInt(_ textType: String) -> Int {
        
        switch textType {
        case "TEXT":
            return Int(SRK_COLUMN_TYPE_TEXT)
        case "TEXT COLLATE NOCASE":
            return Int(SRK_COLUMN_TYPE_TEXT)
        case "INTEGER":
            return Int(SRK_COLUMN_TYPE_INTEGER)
        case "NONE":
            return Int(SRK_COLUMN_TYPE_BLOB)
        case "BLOB":
            return Int(SRK_COLUMN_TYPE_BLOB)
        case "REAL":
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case "NUMBER":
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case "DATETIME":
            return Int(SRK_COLUMN_TYPE_DATE)
        default:
            return Int(SRK_COLUMN_TYPE_INTEGER)
        }
        
    }
    
    func sqlTextTypeFromColumnType(_ columnType: Int) -> String {
        
        if columnType == SRK_COLUMN_TYPE_TEXT {
            return "TEXT"
        }
        
        if columnType == SRK_COLUMN_TYPE_NUMBER {
            return "NUMBER"
        }
        
        if columnType == SRK_COLUMN_TYPE_INTEGER {
            return "INTEGER"
        }
        
        if columnType == SRK_COLUMN_TYPE_DATE {
            return "DATETIME"
        }
        
        if columnType == SRK_COLUMN_TYPE_IMAGE {
            return "BLOB"
        }
        
        if columnType == SRK_COLUMN_TYPE_BLOB {
            return "BLOB"
        }
        
        if columnType == SRK_COLUMN_TYPE_ENTITYCLASS {
            return "INTEGER"
        }
        
        if columnType == SRK_COLUMN_TYPE_ENTITYCOLLECTION {
            return ""
        }
        
        return ""
        
    }
    
    func entityTypeToSqlStorageType(_ entityType: Int) -> Int {
        
        switch Int32(entityType) {
        case SRK_PROPERTY_TYPE_NUMBER:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_STRING:
            return Int(SRK_COLUMN_TYPE_TEXT)
        case SRK_PROPERTY_TYPE_IMAGE:
            return Int(SRK_COLUMN_TYPE_IMAGE)
        case SRK_PROPERTY_TYPE_ARRAY:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_DICTIONARY:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_DATE:
            return Int(SRK_COLUMN_TYPE_DATE)
        case SRK_PROPERTY_TYPE_INT:
            return Int(SRK_COLUMN_TYPE_INTEGER)
        case SRK_PROPERTY_TYPE_BOOL:
            return Int(SRK_COLUMN_TYPE_INTEGER)
        case SRK_PROPERTY_TYPE_LONG:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_FLOAT:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_CHAR:
            return Int(SRK_COLUMN_TYPE_TEXT)
        case SRK_PROPERTY_TYPE_SHORT:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_LONGLONG:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_UCHAR:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_UINT:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_USHORT:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_ULONG:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_ULONGLONG:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_DOUBLE:
            return Int(SRK_COLUMN_TYPE_NUMBER)
        case SRK_PROPERTY_TYPE_CHARPTR:
            return Int(SRK_COLUMN_TYPE_TEXT)
        case SRK_PROPERTY_TYPE_DATA:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_MUTABLEDATA:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_MUTABLEARAY:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_MUTABLEDIC:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_URL:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_ENTITYOBJECT:
            return Int(SRK_COLUMN_TYPE_ENTITYCLASS)
        case SRK_PROPERTY_TYPE_ENTITYOBJECTARRAY:
            return Int(SRK_COLUMN_TYPE_ENTITYCOLLECTION)
        case SRK_PROPERTY_TYPE_NSOBJECT:
            return Int(SRK_COLUMN_TYPE_BLOB)
        case SRK_PROPERTY_TYPE_UNDEFINED:
            assert(1 == 2, "")
        default:
            break;
        }
        
        return 0
        
    }
    
    @objc public func refactor(database: String, entity: String) {
        
        var db = database
        
        if db == "" {
            // this is blank, so it's the default database (if it's open)
            if SRKGlobals.sharedObject().defaultDatabaseName() != nil {
                db = SRKGlobals.sharedObject().defaultDatabaseName()
            }
        }
        
        // check to see if this database has been opened
        if SRKGlobals.sharedObject().handle(forName: db) == nil {
            
            // this will be refactored when the database is finally opened
            return;
            
        }
        
        // check to see if this table already exists
        if databases[entity] == nil {
            
            // completely new table, we can do this in a single operation
            var sql = "CREATE TABLE IF NOT EXISTS \(entity) (Id "
            if schemaPrimaryKeyType(entity: entity) == SRK_PROPERTY_TYPE_NUMBER {
                sql += "INTEGER PRIMARY KEY AUTOINCREMENT);"
            } else {
                sql += "TEXT PRIMARY KEY);"
            }
            
            SharkORM.executeSQL(sql, inDatabase: db)
            
            for f in schemaPropertiesForEntity(entity) {
                
                // now add the columns in one by one
                SharkORM.executeSQL("ALTER TABLE \(entity) ADD COLUMN \(f) \(sqlTextTypeFromColumnType(entityTypeToSqlStorageType(schemaPropertyType(entity: entity, property: f))));", inDatabase: db)
                
            }
            
        } else {
            
            // look for missing columns, and add them
            for f in schemaPropertiesForEntity(entity) {
                if !databasePropertyExists(entity: entity, property: f) {
                    SharkORM.executeSQL("ALTER TABLE \(entity) ADD COLUMN \(f) \(sqlTextTypeFromColumnType(entityTypeToSqlStorageType(schemaPropertyType(entity: entity, property: f))));", inDatabase: db)
                }
            }
            
            // look for changed types
            for f in schemaPropertiesForEntity(entity) {
                if databasePropertyExists(entity: entity, property: f) {
                    if entityTypeToSqlStorageType(schemaPropertyType(entity: entity, property: f)) != databasePropertyType(entity: entity, property: f) {
                        // detect and change the values in the table appropriately
                    }
                }
            }
            
            // notify entity that we are between two states, all new columns have been added, but we have not removed the old ones yet
            
            // look for extra columns, that need removing.
            var foundDefunctColumns: Bool = false
            for f in databasePropertiesForEntity(entity) {
                if !schemaPropertyExists(entity: entity, property: f) {
                    foundDefunctColumns = true
                }
            }
            
            if foundDefunctColumns {
                
                // reconstruct this table, removing the defunct columns
                SharkORM.executeSQL("ALTER TABLE \(entity) RENAME TO temp_\(entity);", inDatabase: db)
                
                // create the new table
                var sql = "CREATE TABLE IF NOT EXISTS \(entity) (Id "
                if schemaPrimaryKeyType(entity: entity) == SRK_PROPERTY_TYPE_NUMBER {
                    sql += "INTEGER PRIMARY KEY AUTOINCREMENT);"
                } else {
                    sql += "TEXT PRIMARY KEY);"
                }
                
                SharkORM.executeSQL(sql, inDatabase: db)
                
                for f in schemaPropertiesForEntity(entity) {
                    
                    // now add the columns in one by one
                    SharkORM.executeSQL("ALTER TABLE \(entity) ADD COLUMN \(f) \(sqlTextTypeFromColumnType(entityTypeToSqlStorageType(schemaPropertyType(entity: entity, property: f))));", inDatabase: db)
                    
                }
                
                SharkORM.executeSQL("INSERT INTO \(entity) (\(schemaPropertiesForEntity(entity).joined(separator: ",")) SELECT \(schemaPropertiesForEntity(entity).joined(separator: ",")) FROM temp_\(entity);", inDatabase: db)
                
                SharkORM.executeSQL("DROP TABLE temp_\(entity);", inDatabase: db)
                
                // clear out the old indexes as they are no longer on the table
                var s = databases[entity]
                s?.indexes = [:]
                
            }
            
        }
        
        // now create and remove indexes on the tables
        for i in schemaIndexDefinitions(entity: entity) {
            
            if databaseIndexDefinitions(entity: entity)[i.key] == nil {
                // missing index, create it now
                SharkORM.executeSQL(i.value, inDatabase: db)
            }
            
        }
        
        for i in databaseIndexDefinitions(entity: entity) {
            if schemaIndexDefinitions(entity: entity)[i.key] == nil {
                SharkORM.executeSQL("DROP INDEX IF EXISTS \(i.key);", inDatabase: db)
            }
        }
        
    }
    
    @objc public func refactor(database: String) {
        
        /*
         *    This will iterate through the schema's, checking them against the Database structure.  After finding all the tables in the database and initialising their class objects if possible
         */
        
        reloadDatabaseSchema(database: database)
        
        // go though all the tables, checking for missed entities
        for t in databaseTables(database) {
            // now we try to create objects from that, to initialise the entity schema
            
            if NSClassFromString(t) == nil {
                let fqn = SRKGlobals.sharedObject().getFQName(forClass: t)
                if fqn != nil {
                   NSClassFromString(fqn!)
                }
            }
            
        }
        
        // loop the tables, creating new or refactoring
        for entity in schemaTables(database: database) {
            
            refactor(database: database, entity: entity)
            
        }
        
    }
    
}
