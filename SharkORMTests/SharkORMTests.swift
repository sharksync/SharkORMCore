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

import XCTest
import SharkORM

class SharkORMTests: XCTestCase, SRKDelegate {
    
    static var currentError: SRKError?
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        SharkORM.setDelegate(self)
        SharkORM.openDatabaseNamed("Persistence")
        cleardown()
        SharkORMTests.currentError = nil
        
    }
    
    func cleardown() {
        
        SharkORM.rawQuery("DELETE FROM Person;")
        SharkORM.rawQuery("DELETE FROM PersonSwift;")
        SharkORM.rawQuery("DELETE FROM Department;")
        SharkORM.rawQuery("DELETE FROM DepartmentSwift;")
        SharkORM.rawQuery("DELETE FROM Location;")
        SharkORM.rawQuery("DELETE FROM SmallPerson;")
        SharkORM.rawQuery("DELETE FROM StringIdObject;")
        SharkORM.rawQuery("DELETE FROM MostObjectTypes;")
        
    }
    
    override func tearDown() {
        
        cleardown()
        
        SharkORM.closeDatabaseNamed("Persistence")
        SharkORM.setDelegate(nil)
        SharkORMTests.currentError = nil
        
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func databaseError(_ error: SRKError) {
        print("error = \(error.errorMessage!)\nsql=\(error.sqlQuery!)")
    }
    
    func testPerformance() {
        // This is an example of a performance test case.
        self.measure {
            
            arc4random_stir()
            autoreleasepool {
                // small record tests
                for i in 0..<100 {
                    autoreleasepool {
                        let p = Person()
                        p.name = "\(Int(arc4random_uniform(999999999)))"
                        p.age = Int(arc4random())
                        p.seq = i
                        p.commit()
                    }
                }
                for _ in 0..<1 {
                    autoreleasepool {
                        let _ = Person.query().where("seq > 30 AND seq < 80").fetch()
                        let _ = Person.query().where("seq > 30 AND seq < 70").fetch()
                        let _ = Person.query().where("seq > 40 AND seq < 55").order("age").fetch()
                        let _ = Person.query().where("seq > 20 AND seq < 40").fetch()
                        let _ = Person.query().where("seq > 10 AND seq < 70").order(byDescending: "age").fetch()
                        let _ = Person.query().where("seq > 90 AND seq < 90").fetch()
                    }
                }
                for _ in 0..<10 {
                    autoreleasepool {
                        let _ = Person.query().where("seq = ?", parameters:[Int(arc4random_uniform(99))]).limit(1).fetch()
                        let _ = Person.query().where("seq > ?", parameters:[Int(arc4random_uniform(99))]).fetch()
                    }
                }
            }
            
        }
    }
    
    func test_schema_ignored_properties() {
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
    
    func test_Persistence_Simple_Object_Insert() {
        cleardown()
        let p = Person()
        let result = p.commit()
        XCTAssert(result, "Failed to insert simple object (without values)")
        XCTAssert(Person.query().count() == 1, "BOOL <return value> from commit was TRUE but the count on the table was 0")
    }
    
    func test_Persistence_Simple_Object_Update() {
        cleardown()
        let p = Person()
        p.name = "Adrian"
        let result = p.commit()
        if result {
            let p2 = Person.query().fetch().firstObject as? Person
            if p2 != nil {
                p2?.name = "Sarah"
                XCTAssert(p2!.commit(), "Failed to update existing record with new values")
                let p3 = Person.query().fetch().firstObject as? Person
                XCTAssert((p3!.name == "Sarah"), "Non current value retrieved from store")
            } else {
                XCTAssert(p2 != nil, "Object which was believed to be persisted, failed to be retrieved")
            }
        } else {
            XCTAssert(result, "Failed to insert simple object (without values)")
        }
    }
    
    func test_Persistence_Simple_Object_Delete() {
        cleardown()
        let p = Person()
        let result = p.commit()
        if result {
            Person.query().fetch().remove()
            XCTAssert(Person.query().count() == 0, "'removeAll' called, but objects remain in table")
        } else {
            XCTAssert(result, "Failed to insert simple object (without values)")
        }
    }
    
    func test_Persistence_Multiple_Object_Insert() {
        cleardown()
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        p1.commit()
        p2.commit()
        p3.commit()
        XCTAssert(Person.query().count() == 3, "Insert 3 records inline failed")
    }
    
    func test_Persistence_Single_Object_Insert_Multiple_Times() {
        cleardown()
        let p1 = Person()
        p1.commit()
        p1.commit()
        p1.commit()
        XCTAssert(Person.query().count() == 1, "Insert 1 record 3 times failed")
    }
    
    func test_Persistence_Nested_Object_Insert() {
        cleardown()
        let p = Person()
        p.name = "New Person"
        p.department = Department()
        p.department!.name = "New Department"
        p.commit()
        XCTAssert(Person.query().count() == 1, "Insert 1 record with a related/embedded object has failed")
        XCTAssert(Department.query().count() == 1, "Insert 1 related record via a parent object")
        // actually check the correct object exists
        let d = Department.query().fetch().firstObject as? Department
        XCTAssert(d != nil, "Department object not retrieved")
        XCTAssert((d?.name == "New Department"), "Invalid 'name' value in department object")
    }
    
    func test_Persistence_Nested_Object_Update() {
        cleardown()
        let p = Person()
        p.name = "New Person"
        p.department = Department()
        p.department!.name = "New Department"
        p.commit()
        XCTAssert(Person.query().count() == 1, "Insert 1 record with a related/embedded object has failed")
        XCTAssert(Department.query().count() == 1, "Insert 1 related record via a parent object")
        // actually check the correct object exists
        var d = Department.query().fetch().firstObject as? Department
        XCTAssert(d != nil, "Department object not retrieved")
        XCTAssert((d?.name == "New Department"), "Invalid 'name' value in department object")
        // now check persistence of an update to a related object when commit is called on the parent object
        p.department!.name = "New Name"
        p.commit()
        d = Department.query().fetch().firstObject as? Department
        XCTAssert(d != nil, "Department object not retrieved")
        XCTAssert((d?.name == "New Name"), "Invalid 'name' value in department object after persistence call to parent object")
    }
    
    func test_Persistence_all_object_types() {
        
        MostObjectTypes.query().fetchLightweight().remove()
        let ob = MostObjectTypes()
        ob.number = 42
        ob.array = [1, 2, 3]
        ob.date = Date()
        ob.dictionary = ["one": 1, "two": 2]
        ob.intvalue = 42
        ob.floatValue = 42.424242
        ob.doubleValue = 1234567.1234567
        ob.commit()
        for mot in MostObjectTypes.query().fetch() as! [MostObjectTypes] {
            print("\(mot)")
        }
        
    }
    
    func test_Persistence_invalid_object_types() {
        
        let ob = MostObjectTypes()
        ob.number = 42
        ob.array = [1, 2, 3]
        ob.date = Date()
        ob.dictionary = ["vc": UIViewController()]
        ob.intvalue = 42
        ob.floatValue = 42.424242
        ob.doubleValue = 1234567.1234567
        ob.commit()
        let _ = MostObjectTypes.query().fetch().firstObject as? MostObjectTypes
        
    }
    
    func test_Persistence_string_pk_object() {
        let obj = StringIdObject()
        obj.value = "test value"
        // there should not be a UUID yet for the PK column
        XCTAssert(obj.id == nil, "Primary key had been generated prior to insertion into data store")
        obj.commit()
        XCTAssert(obj.id != nil, "Primary key had not been generated post insertion into data store")
        let o2 = StringIdObject.object(withPrimaryKeyValue: obj.id!)
        XCTAssert(o2 != nil, "Retrieval of object with a string PK value failed")
    }
    
    func test_Persistence_initial_values() {
        cleardown()
        let p: Person? = Person(dictionary: ["name": "Adrian Herridge", "age": 38])
        XCTAssert(p?.age == 38, "initial values population failed")
        p?.commit()
        let count = (Person.query().where("name = 'Adrian Herridge' AND age = 38 AND seq = 0 AND department IS NULL")).count()
        XCTAssert(Int(count) == 1, "initial values population failed")
    }

    func test_event_simple_object_update_event() {
        cleardown()
        let p = Person()
        p.commit()
        var updated = false
         p.registerBlock(forEvents: SharkORMEventUpdate, with: { event in
            updated = true
        }, onMainThread: true)
        p.name = "New name"
        p.commit()
        XCTAssert(updated, "event failed to be raised for update.")
    }
    
    func test_event_simple_object_delete_event() {
        cleardown()
        let p = Person()
        p.commit()
        var updated = false
        p.registerBlock(forEvents: SharkORMEventDelete, with: { event in
            updated = true
        }, onMainThread: true)
        p.remove()
        XCTAssert(updated, "event failed to be raised for update.")
    }
    
    func test_event_simple_entity_class_insert_event() {
        cleardown()
        var called = false
        let handler: SRKEventHandler? = Person.eventHandler()
        handler?.registerBlock(forEvents: SharkORMEventInsert, with: { event in
            called = true
        }, onMainThread: true)
        let p = Person()
        p.commit()
        XCTAssert(called, "event failed to be raised for insert")
    }
    
    func test_event_simple_entity_class_update_not_insert_event() {
        cleardown()
        var called = false
        let handler: SRKEventHandler? = Person.eventHandler()
        handler?.registerBlock(forEvents: SharkORMEventUpdate, with: { event in
            called = true
        }, onMainThread: true)
        let p = Person()
        p.commit()
        XCTAssert(!called, "event raised for insert, but only monitoring update")
        p.name = "New Name"
        p.commit()
        XCTAssert(called, "event failed to be raised for update")
    }
    
    func test_event_simple_entity_class_bitwise_events() {
        cleardown()
        var called = false
        let handler: SRKEventHandler? = Person.eventHandler()
        handler?.registerBlock(forEvents: SharkORMEvent.init(SharkORMEventUpdate.rawValue+SharkORMEventDelete.rawValue), with: { event in
            called = true
        }, onMainThread: true)
        let p = Person()
        p.commit()
        XCTAssert(!called, "event raised for insert, but only monitoring update|delete")
        p.remove()
        XCTAssert(called, "event failed to be raised for delete despite monitoring for update|delete")
    }
    
    func test_event_simple_object_update_event_multithreaded() {
        cleardown()
        let p = Person()
        p.commit()
        var updated = false
        p.registerBlock(forEvents: SharkORMEventUpdate, with: { event in
            updated = true
        }, onMainThread: false)
        // can't use main thread here because it clashes with the sleep on the same thread.
        DispatchQueue.global(qos: .default).async(execute: {
            p.name = "New name"
            p.commit()
        })
        Thread.sleep(forTimeInterval: 2)
        XCTAssert(updated, "event failed to be raised for update from different thread.")
    }
    
    func test_global_event_blocks() {
        cleardown()
        var insertCount: Int = 0
        var updateCount: Int = 0
        var deleteCount: Int = 0
        SharkORM.setInsertCallbackBlock( { entity in
            if (entity.classForCoder.description() == "Person") {
                insertCount += 1
            }
        })
        SharkORM.setUpdateCallbackBlock( { entity in
            if (entity.classForCoder.description() == "Person") {
                updateCount += 1
            }
        })
        SharkORM.setDeleteCallbackBlock( { entity in
            if (entity.classForCoder.description() == "Person") {
                deleteCount += 1
            }
        })
        var p = Person()
        p.name = "testing 123"
        p.commit()
        XCTAssert(insertCount == 1 && updateCount == 0 && deleteCount == 0, "failed to trigger event correctly")
        p.name = "testing 321"
        p.commit()
        XCTAssert(insertCount == 1 && updateCount == 1 && deleteCount == 0, "failed to trigger event correctly")
        p.remove()
        XCTAssert(insertCount == 1 && updateCount == 1 && deleteCount == 1, "failed to trigger event correctly")
        insertCount = 0
        updateCount = 0
        deleteCount = 0
        p = Person()
        SRKTransaction.transaction({
            // insert
            p.name = "testing 123"
            p.commit()
        }, withRollback: {
        })
        SRKTransaction.transaction({
            // update
            p.name = "testing 321"
            p.commit()
        }, withRollback: {
        })
        SRKTransaction.transaction({
            // delete
            p.remove()
        }, withRollback: {
        })
        XCTAssert(insertCount == 1 && updateCount == 1 && deleteCount == 1, "failed to trigger event correctly")
        insertCount = 0
        updateCount = 0
        deleteCount = 0
        SRKTransaction.transaction({
            let p = Person()
            p.name = "testing 123"
            p.commit()
            p.name = "testing 321"
            p.commit()
            p.remove()
        }, withRollback: {
            // a transaction only holds a "final" state for an object, which in this case is delete.
            XCTAssert(insertCount == 0 && updateCount == 0 && deleteCount == 1, "failed to trigger event correctly")
        })
    }
    
    func test_basic_example_methods() {
        
        /* clear all pre-existing data from the entity class */
        Person.query().fetchLightweight().remove()
        /* now create a new object ready for persistence */
        let newPerson = Person()
        // set some values
        newPerson.name = "Adrian"
        newPerson.age = 38
        newPerson.payrollNumber = 12345678
        newPerson.commit()
        /* getting objects back again */
        let results = Person.query().fetch() as! [Person]
        for p in results {
            // modify the record and then commit the change back in again
            p.age += 1
            p.commit()
        }
        
    }

    func setupJoinData() {
        cleardown()
        let l = Location()
        l.locationName = "Alton"
        let d = Department()
        d.name = "Development"
        d.location = l
        let p = Person()
        p.name = "Adrian"
        p.age = 37
        p.department = d
        p.location = l
        p.commit()
    }
    
    func test_single_join() {
        setupJoinData()
        // pull out a single object but use join to join to the department class and not the relationship
        let p = Person.query().join(to: Department.self, leftParameter: "department", targetParameter: "Id").fetch().firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert(p?.joinedResults!["Department.name"] != nil, "join failed, no results returned for first join")
    }
    
    func test_multiple_join() {
        setupJoinData()
        // pull out a single object but use 2 joins to join to the department &  class and not the relationship
        let p = Person.query().join(to: Department.self, leftParameter: "department", targetParameter: "Id").join(to: Location.self, leftParameter: "location", targetParameter: "Id").fetch().firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert((p?.joinedResults!["Department.name"] as? String == "Development"), "join failed, no results returned for first join")
        XCTAssert((p?.joinedResults!["Location.locationName"] as? String == "Alton"), "join failed, no results returned for second join")
    }
    
    func test_multiple_join_with_fail_on_second_join() {
        setupJoinData()
        // pull out a single object but use 2 joins to join to the department &  class and not the relationship
        let p = Person.query().join(to: Department.self, leftParameter: "department", targetParameter: "Id").join(to: Location.self, leftParameter: "name", targetParameter: "Id").fetch().firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert(p?.joinedResults!["Department.name"] != nil, "join failed, no results returned for first join")
        XCTAssert((p?.joinedResults!["Location.locationName"] is NSNull), "join failed, no results returned for second join")
    }
    
    func test_multiple_join_with_fail_on_second_join_test_for_null_in_where() {
        setupJoinData()
        // pull out a single object but use 2 joins to join to the department &  class and not the relationship
        let p = Person.query().where("Location.Id IS NULL").join(to: Department.self, leftParameter: "department", targetParameter: "Id").join(to: Location.self, leftParameter: "name", targetParameter: "Id").fetch().firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert(p?.joinedResults!["Department.name"] != nil, "join failed, no results returned for first join")
        XCTAssert((p?.joinedResults!["Location.locationName"] is NSNull), "join failed, no results returned for first join")
    }
    
    func test_multiple_join_with_joined_table_referenced_in_where() {
        setupJoinData()
        // pull out a single object but use 2 joins to join to the department &  class and not the relationship
        let p = ((Person.query().join(to: Department.self, leftParameter: "department", targetParameter: "Id").join(to: Location.self, leftParameter: "location", targetParameter: "Id").where("Location.locationName = 'Alton'")).fetch()).firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert((p?.joinedResults!["Department.name"] as? String == "Development"), "join failed, no results returned for first join")
        XCTAssert((p?.joinedResults!["Location.locationName"] as? String == "Alton"), "join failed, no results returned for second join")
    }
    
    func test_multiple_join_chaining_join_one_and_two() {
        setupJoinData()
        // pull out a single object but use 2 joins to join to the department &  class and not the relationship
        let p = Person.query().join(to: Department.self, leftParameter: "department", targetParameter: "Id").join(to: Location.self, leftParameter: "Department.location", targetParameter: "Id").fetch().firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert((p?.joinedResults!["Department.name"] as? String == "Development"), "join failed, no results returned for first join")
        XCTAssert((p?.joinedResults!["Location.locationName"] as? String == "Alton"), "join failed, no results returned for second join")
    }
    
    func test_multiple_join_specifying_fully_qualified_field_names() {
        setupJoinData()
        // pull out a single object but use 2 joins to join to the department &  class and not the relationship
        let p = Person.query().join(to: Department.self, leftParameter: "Person.department", targetParameter: "Department.Id").join(to: Location.self, leftParameter: "Department.location", targetParameter: "Location.Id").fetch().firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert((p?.joinedResults!["Department.name"] as? String == "Development"), "join failed, no results returned for first join")
        XCTAssert((p?.joinedResults!["Location.locationName"] as? String == "Alton"), "join failed, no results returned for second join")
    }
    
    func test_where_query_with_object_dot_notation_joins_and_normal_joins() {
        setupJoinData()
        let r: SRKResultSet? = Person.query().where("department.name='Development' AND location.locationName = 'Alton'").join(to: Department.self, leftParameter: "Person.department", targetParameter: "Department.Id").join(to: Location.self, leftParameter: "Department.location", targetParameter: "Location.Id").fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 1, "incorrect number of results returned")
        let p: Person? = r?.firstObject as? Person
        XCTAssert(p != nil, "failed to retrieve and object when using a single join")
        XCTAssert((p?.joinedResults!["Department.name"] as? String == "Development"), "join failed, no results returned for first join")
        XCTAssert((p?.joinedResults!["Location.locationName"] as? String == "Alton"), "join failed, no results returned for second join")
    }

    func test_multithreaded_insert_of_sequential_objects_x50() {
        cleardown()
        // now loop creating 50x simultanious insert operations
        for i in 1...50 {
            let copyInt: Int = i
            DispatchQueue.global(qos: .default).async(execute: {
                let p = Person()
                p.age = copyInt
                p.commit()
            })
        }
        // just wait until we can guarantee the inserts have finished, then we can test the output
        Thread.sleep(forTimeInterval: 10)
        XCTAssert(Person.query().count() == 50, "Failed to insert 50 records simultaniously")
        for i in 1...50 {
            XCTAssert((Person.query().where("age = ?", parameters:[i]).count() == 1), "missing record when inserting simultanious objects")
        }
    }
    
    func test_stress_insert_update_delete_objects_semi_sequntial_x50() {
        // there is no way to measure the random nature of this test, but we will look for crashes from mult threaded access
        cleardown()
        arc4random_stir()
        // setup the base level data.
        for i in 1...50 {
            let p = Person()
            p.age = i
            p.commit()
        }
        // now flood the insert / update / delete mechanisums
        // now loop creating 50x simultanious insert operations
        for i in 1...50 {
            let copyInt: Int = i
            DispatchQueue.global(qos: .default).async(execute: {
                let p = Person()
                p.age = copyInt
                p.commit()
            })
        }
        // now loop creating 50x simultanious query/update operations
        for _ in 1...50 {
            DispatchQueue.global(qos: .default).async(execute: {
                let results: SRKResultSet = Person.query().fetch()
                let p = results[Int(arc4random_uniform(50))] as? Person
                if p != nil {
                    p?.age = Int(arc4random_uniform(50))
                    p?.commit()
                }
            })
        }
        // now loop creating 50x simultanious query/delete operations
        for _ in 1...50 {
            DispatchQueue.global(qos: .default).async(execute: {
                let results: SRKResultSet = Person.query().fetch()
                let p = results.object(at: Int(arc4random_uniform(UInt32(results.count)))) as? Person
                if p != nil {
                    p?.remove()
                }
            })
        }
        // just wait until we can guarantee the inserts have finished, then we can test the output
        Thread.sleep(forTimeInterval: 10)
    }
    
    func test_stress_insert_update_delete_objects_grouped_x50() {
        // there is no way to measure the random nature of this test, but we will look for crashes from mult threaded access
        cleardown()
        arc4random_stir()
        // setup the base level data.
        for i in 1...50 {
            let p = Person()
            p.age = i
            p.commit()
        }
        // now flood the insert / update / delete mechanisums
        // now loop creating 50x simultanious insert operations
        for i in 1...50 {
            let copyInt: Int = i
            DispatchQueue.global(qos: .default).async(execute: {
                let p = Person()
                p.age = copyInt
                p.commit()
            })
            DispatchQueue.global(qos: .default).async(execute: {
                let results: SRKResultSet? = Person.query().fetch()
                let p = results?[Int(arc4random_uniform(UInt32(results?.count ?? 0)))] as? Person
                if p != nil {
                    p?.age = Int(arc4random_uniform(100))
                    p?.commit()
                }
            })
            DispatchQueue.global(qos: .default).async(execute: {
                let results: SRKResultSet? = Person.query().fetch()
                let p = results?[Int(arc4random_uniform(UInt32(results?.count ?? 0)))] as? Person
                if p != nil {
                    p?.remove()
                }
            })
        }
        // just wait until we can guarantee the inserts have finished, then we can test the output
        Thread.sleep(forTimeInterval: 10)
    }

    func test_print_concommited_object() {
        let p = Person()
        p.commit()
        print("\(p)")
    }
    
    func test_print_unconcommited_object() {
        let p = Person()
        print("\(p)")
    }

    func setupCommonData() {
        cleardown()
        // setup some common data
        let d = Department()
        d.name = "Test Department"
        let d2 = Department()
        d2.name = "Old Department"
        var p = Person()
        p.name = "Adrian"
        p.age = 37
        p.department = d
        p.origDepartment = d2
        p.commit()
        p = Person()
        p.name = "Neil"
        p.age = 34
        p.department = d
        p.origDepartment = d2
        p.commit()
        p = Person()
        p.name = "Michael"
        p.age = 30
        p.department = d
        p.origDepartment = d2
        p.commit()
    }
    
    func test_where_query() {
        setupCommonData()
        let r: SRKResultSet? = Person.query().where("age >= 34").fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 2, "incorrect number of results returned")
    }
    
    func test_whereWithFormat_query() {
        setupCommonData()
        let r: SRKResultSet? = Person.query().where("age >= ?", parameters:[34]).fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 2, "incorrect number of results returned")
    }
    
    func test_count_query() {
        setupCommonData()
        let r = Person.query().where("age >= ?", parameters:[34]).count()
        XCTAssert(Int(r) == 2, "incorrect number of results returned")
    }
    
    func test_sum_query() {
        setupCommonData()
        let r = Person.query().where("age >= ?", parameters:[34]).sum(of:"age")
        XCTAssert(r == 71, "incorrect number of results returned")
    }
    
    func test_distinct_query_string_value() {
        setupCommonData()
        // duplicate some of the data
        var p = Person()
        p.name = "Adrian"
        p.age = 37
        p.commit()
        p = Person()
        p.name = "Neil"
        p.age = 34
        p.commit()
        let r = Person.query().distinct("name")
        XCTAssert(r.count == 3, "number of items returned from distinct call is incorrect")
    }
    
    func test_distinct_query_string_value_order_by() {
        setupCommonData()
        // duplicate some of the data
        var p = Person()
        p.name = "Adrian"
        p.age = 37
        p.commit()
        p = Person()
        p.name = "Neil"
        p.age = 34
        p.commit()
        let r = Person.query().order("name").distinct("name") as! [String]
        XCTAssert(r.count == 3, "number of items returned from distinct call is incorrect")
        XCTAssert((r[0] == "Adrian"), "order by in distinct failed")
        XCTAssert((r[1] == "Michael"), "order by in distinct failed")
        XCTAssert((r[2] == "Neil"), "order by in distinct failed")
    }
    
    func test_whereWithFormat_parameter_type_entity() {
        setupCommonData()
        let d = ((Department.query().where("name = 'Test Department'")).fetch()).firstObject as? Department
        let r: SRKResultSet? = Person.query().where("department = ?", parameters:[d!]).fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 3, "incorrect number of results returned")
    }
    
    func test_whereWithFormat_parameter_type_int() {
        setupCommonData()
        let r: SRKResultSet? = Person.query().where("age = ?", parameters:[37]).fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 1, "incorrect number of results returned")
    }
    
    func test_whereWithFormat_parameter_type_string() {
        setupCommonData()
        let r: SRKResultSet? = Person.query().where("name = ?", parameters:["Neil"]).fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 1, "incorrect number of results returned")
    }
    
    func test_whereWithFormat_parameter_type_like() {
        setupCommonData()
        var r: SRKResultSet? = Person.query().where("name LIKE ?", parameters:["%cha%"]).fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 1, "incorrect number of results returned")
        XCTAssert((((r?[0] as? Person)?.name) == "Michael"), "incorrect number of results returned")
        // test for case insensitivity
        r = Person.query().where("name LIKE ?", parameters:["%chA%"]).fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        // this is a known bug/feature, SQLite's LIKE comparisons are case insensitive.
        // http://stackoverflow.com/questions/15480319/case-sensitive-and-insensitive-like-in-sqlite
        // TODO: descision to be made on weather this is an acceptable situation or whether we should change the default
        // XCTAssert(r.count == 0,@"incorrect number of results returned");
    }
    
    func test_raw_query() {
        setupCommonData()
        let results: SRKRawResults? = SharkORM.rawQuery("SELECT * FROM Person ORDER BY age;")
        XCTAssert(results?.rowCount() == 3, "Raw query row count was incorrect given fixed data")
        XCTAssert(results?.columnCount() == 8, "Raw query column count was incorrect given fixed data")
        XCTAssert(((results?.value(forColumn: "name", atRow: 0) as? String) == "Michael"), "Raw query column count was incorrect given fixed data")
    }
    
    func test_where_query_with_object_dot_notation_joins() {
        setupCommonData()
        let r: SRKResultSet? = Person.query().where("department.name='Test Department' AND location.locationName IS NULL").fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 3, "incorrect number of results returned")
    }
    
    func test_where_query_with_object_dot_notation_joins_order_by_on_joined_subproperty() {
        setupCommonData()
        let r: SRKResultSet? = Person.query().where("department.name='Test Department' AND location.locationName IS NULL").order("department.name").fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 3, "incorrect number of results returned")
    }
    
    func test_where_query_with_object_dot_notation_joins_not_named_as_entity() {
        setupCommonData()
        let r: SRKResultSet? = Person.query().where("origDepartment.name='Old Department' AND location.locationName IS NULL").fetch()
        XCTAssert(r != nil, "Failed to return a result set")
        XCTAssert(r?.count == 3, "incorrect number of results returned")
    }
    
    func test_batch_size_with_large_data_set() {
        cleardown()
        var p1: Person? = nil
        var p2: Person? = nil
        var p3: Person? = nil
        var p4: Person? = nil
        for i in 0..<10000 {
            autoreleasepool {
                let p = Person()
                p.name = "\(Int(arc4random_uniform(999999999)))"
                p.age = Int(arc4random())
                p.seq = i
                p.commit()
                if i == 50 {
                    p1 = p
                }
                if i == 1050 {
                    p2 = p
                }
                if i == 2050 {
                    p3 = p
                }
                if i == 9000 {
                    p4 = p
                }
            }
        }
        let results = Person.query().batchSize(1000).fetch() as! [Person]
        let count = results.count
        XCTAssert(count > 0, "batch count failed")
        XCTAssert(count == 10000, "batch count failed")
        var i: Int = 0
        for p in results {
            if i == 50 {
                XCTAssert(p.age == p1?.age, "batch comparison failed")
            }
            if i == 1050 {
                XCTAssert(p.age == p2?.age, "batch comparison failed")
            }
            if i == 2050 {
                XCTAssert(p.age == p3?.age, "batch comparison failed")
            }
            if i == 9000 {
                XCTAssert(p.age == p4?.age, "batch comparison failed")
            }
            i += 1
        }
    }
    
    func test_date_parameters() {
        cleardown()
        // fisrt should be excluded form the results
        let mo0 = MostObjectTypes()
        mo0.date = Date()
        mo0.commit()
        Thread.sleep(forTimeInterval: 0.1)
        let start = Date()
        Thread.sleep(forTimeInterval: 0.1)
        let mo1 = MostObjectTypes()
        mo1.date = Date()
        mo1.commit()
        Thread.sleep(forTimeInterval: 0.1)
        let mo2 = MostObjectTypes()
        mo2.date = Date()
        mo2.commit()
        Thread.sleep(forTimeInterval: 0.1)
        let count = MostObjectTypes.query().where("date >= ? AND date <= ?", parameters:[start, Date()]).count()
        XCTAssert(Int(count) == 2, "query with NSDate parameters failed")
    }
    
    func test_nil_related_entity_as_parameter() {
        cleardown()
        let p = Person()
        p.name = "Adrian"
        p.department = Department()
        p.department?.name = "Dev"
        p.commit()
        let d = Department.query().fetch().firstObject as? Department
        d?.remove()
        let _ = (Person.query().where("department = ?", parameters:[d!])).fetch()
    }

    func test_basic_data_syncronisation_with_sharksyncIO() {
        
        let settings = SharkSyncSettings()
        settings.pollInterval = 1;
        SharkSync.startService(withApplicationId: "9a720b2e-d4e7-4d37-b773-a03a257458ca", accessKey: "b03e7cc9-a4b5-4d63-9dd9-00e68edbe4c8", settings: settings, classes: [TestTable.self])
        SharkSync.addVisibilityGroup("testgroup")
        let t = TestTable(dictionary: ["name" : "adrian", "age" : 39])
        t.commit(inGroup: "testgroup")
        SharkSync.synchroniseNow()
        Thread.sleep(forTimeInterval: 10)

    }
    
}
