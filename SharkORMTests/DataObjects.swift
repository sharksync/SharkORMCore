//
//  Person.swift
//  SharkORMTests
//
//  Created by Adrian Herridge on 27/06/2018.
//  Copyright © 2018 SharkSync. All rights reserved.
//

import Foundation
import SharkORM

class Person: SRKObject {
    
    var name: String?
    var age: Int = 0
    var seq: Int = 0
    var payrollNumber: Int = 0
    var department: Department?
    var origDepartment: Department?
    var location: Location?
    
    override class func defaultValuesForEntity() -> [String: Any]? {
        return ["age": 36]
    }
    
}

class SmallPerson: Person {
    
    var height: Int = 0
    
}

class Department: SRKObject {
    
    var name: String?
    var location: Location?
    
    override class func indexDefinitionForEntity() -> SRKIndexDefinition? {
        return SRKIndexDefinition(["name"])
    }
    
}

class Location: SRKObject {
    var locationName: String?
    var department: Department?
}

class MostObjectTypes: SRKObject {
    
    var string: String?
    var date: Date?
    var array = [Any]()
    var dictionary = [AnyHashable: Any]()
    var number: NSNumber?
    var intvalue: Int = 0
    var floatValue: Float = 0.0
    var doubleValue: Double = 0.0
    
}

class StringIdObject: SRKStringObject {
    var value: String?
    var related: StringIdRelatedObject?
}

class StringIdRelatedObject: SRKStringObject {
    var name: String?
}

