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

import Foundation
import SharkORM

class Person: SRKObject {
    
    @objc dynamic var name: String?
    @objc dynamic var age: Int = 0
    @objc dynamic var seq: Int = 0
    @objc dynamic var payrollNumber: Int = 0
    @objc dynamic var department: Department?
    @objc dynamic var origDepartment: Department?
    @objc dynamic var location: Location?
    
    override class func defaultValuesForEntity() -> [String: Any]? {
        return ["age": 36]
    }
    
}

class SmallPerson: Person {
    
    @objc dynamic var height: Int = 0
    
}

class Department: SRKObject {
    
    @objc dynamic var name: String?
    @objc dynamic var location: Location?
    
    override class func indexDefinitionForEntity() -> SRKIndexDefinition? {
        return SRKIndexDefinition(["name"])
    }
    
}

class Location: SRKObject {
    @objc dynamic var locationName: String?
    @objc dynamic var department: Department?
}

class MostObjectTypes: SRKObject {
    
    @objc dynamic var string: String?
    @objc dynamic var date: Date?
    @objc dynamic var array = [Any]()
    @objc dynamic var dictionary = [AnyHashable: Any]()
    @objc dynamic var number: NSNumber?
    @objc dynamic var intvalue: Int = 0
    @objc dynamic var floatValue: Float = 0.0
    @objc dynamic var doubleValue: Double = 0.0
    
}

class StringIdObject: SRKStringObject {
    @objc dynamic var value: String?
    @objc dynamic var related: StringIdRelatedObject?
}

class StringIdRelatedObject: SRKStringObject {
    @objc dynamic var name: String?
}

class SchemaObject: SRKObject {
    
    @objc dynamic var schemaField1: String?
    @objc dynamic var schemaField2: String?
    
    override class func ignoredProperties() -> [String] {
        return ["schemaField2"]
    }
    
}

class TestTable: SRKSyncObject {
    
    @objc dynamic var name: String?
    @objc dynamic var age: Int = 0
    
}

