//
//  SchemaTest.swift
//  SharkORMTests
//
//  Created by Adrian Herridge on 27/06/2018.
//  Copyright © 2018 SharkSync. All rights reserved.
//

import Foundation
import SharkORM
import XCTest

class SchemaObject: SRKObject {
    
    @objc dynamic var schemaField1: String?
    @objc dynamic var schemaField2: String?
    
    override class func ignoredProperties() -> [String] {
        return ["schemaField2"]
    }
    
}

class SchemaTests: SharkORMTests {
    
    func test_ignored_properties() {
        // reference the object to create the table
        let _ = SchemaObject.query()
        // now query the master database to check the ignored property is missing
        var results: SRKRawResults = SharkORM.rawQuery("SELECT * FROM sqlite_master WHERE type='table' AND name='SchemaObject'")
        XCTAssert(results.rowCount() == 1, "table schema was not created properly")
        results = SharkORM.rawQuery("SELECT * FROM sqlite_master WHERE type='table' AND name='SchemaObject' AND sql LIKE '%schemaField1%'")
        XCTAssert(Int(results.rowCount()) == 1, "table schema was not created properly")
        results = SharkORM.rawQuery("SELECT * FROM sqlite_master WHERE type='table' AND name='SchemaObject' AND sql LIKE '%schemaField2%'")
        XCTAssert(Int(results.rowCount()) == 0, "table schema was not created properly")
    }
    
}
