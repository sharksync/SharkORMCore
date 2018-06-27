//
//  SharkORMTests.swift
//  SharkORMTests
//
//  Created by Adrian Herridge on 27/06/2018.
//  Copyright © 2018 SharkSync. All rights reserved.
//

import XCTest
import SharkORM

class SharkORMTests: XCTestCase, SRKDelegate {
    
    static var currentError: SRKError?
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        SharkORM.setDelegate(self)
        SharkORM.openDatabaseNamed("Persistence")
        SharkORM.rawQuery("DELETE FROM Person;")
        SharkORM.rawQuery("DELETE FROM PersonSwift;")
        SharkORM.rawQuery("DELETE FROM Department;")
        SharkORM.rawQuery("DELETE FROM DepartmentSwift;")
        SharkORM.rawQuery("DELETE FROM Location;")
        SharkORM.rawQuery("DELETE FROM SmallPerson;")
        SharkORM.rawQuery("DELETE FROM StringIdObject;")
        SharkORM.rawQuery("DELETE FROM MostObjectTypes;")
        SharkORMTests.currentError = nil
    }
    
    override func tearDown() {
        
        SharkORM.rawQuery("DELETE FROM Person;")
        SharkORM.rawQuery("DELETE FROM PersonSwift;")
        SharkORM.rawQuery("DELETE FROM Department;")
        SharkORM.rawQuery("DELETE FROM DepartmentSwift;")
        SharkORM.rawQuery("DELETE FROM Location;")
        SharkORM.rawQuery("DELETE FROM SmallPerson;")
        SharkORM.rawQuery("DELETE FROM StringIdObject;")
        SharkORM.rawQuery("DELETE FROM MostObjectTypes;")
        
        SharkORM.closeDatabaseNamed("Persistence")
        SharkORM.setDelegate(nil)
        SharkORMTests.currentError = nil
        
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func databaseError(_ error: SRKError?) {
        if let aMessage = error?.errorMessage, let aQuery = error?.sqlQuery {
            print("error = \(aMessage)\nsql=\(aQuery)")
        }
    }
    
}
