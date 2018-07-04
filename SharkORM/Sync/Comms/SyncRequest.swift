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

class SyncResponseViewModel : Codable {
    
    var Groups: [SyncObjectGroupResponseViewModel] = []
    var Errors: [String] = []
    var Success: Bool?
    
}

class SyncObjectGroupResponseViewModel : Codable {
    
    var Group: String?
    var Tidemark: Int64?
    var Changes: [SyncObjectChangeViewModel] = []
    
}

class SyncObjectGroupViewModel : Codable {
    
    var Group: String?
    var Tidemark: Int64?
    
}

class SyncObjectChangeViewModel : Codable {
    
    var RecordId: String?
    var Entity: String?
    var Property: String?
    var Value: String?
    var SecondsAgo: Int64?
    var Group: String?
    var Operation: Int?
    var Modified: String?
    
}

class SyncRequestViewModel : Codable {
    
    var app_id: String?
    var device_id: String?
    var app_api_access_key: String?
    var changes: [SyncObjectChangeViewModel] = []
    var groups: [SyncObjectGroupViewModel] = []
    
}

class SyncRequest {
    
    var changes: [SharkSyncChange]?
    
    func generateRequestObject() -> SyncRequestViewModel {
        
        let r = SyncRequestViewModel()
        r.app_id = SharkSync.sharedObject().applicationKey
        r.device_id = SharkSync.sharedObject().deviceId
        r.app_api_access_key = SharkSync.sharedObject().accountKeyKey
        
        // pull out a reasonable amount of writes to be sent to the server
        let changeResults = (SharkSyncChange.query().limit(200).order("timestamp").fetch()) as! [SharkSyncChange]
        self.changes = changeResults
        
        for change: SharkSyncChange in changeResults {
            
            let secondsAgo = Int64((Date().timeIntervalSince1970 - change.timestamp) * 1000)
            let c = SyncObjectChangeViewModel()
            c.Group = change.recordGroup
            c.Entity = change.entity
            c.RecordId = change.recordId
            c.Property = change.property
            c.SecondsAgo = secondsAgo
            c.Value = change.value
            r.changes.append(c)
            
        }
        
        // now select out the data groups to poll for, oldest first
        let groupResults = SRKSyncGroup.query().limit(200).order("last_polled").fetch() as! [SRKSyncGroup]
        for group: SRKSyncGroup in groupResults {
            let g = SyncObjectGroupViewModel()
            g.Group = group.groupName
            g.Tidemark = group.tidemark
            r.groups.append(g)
        }
        
        return r
        
    }
    
    func handleResponse(_ response: SyncResponseViewModel, changes: [SharkSyncChange]?) {
        
        // check for success/error
        if response.Success == false {
            return
        }
        
        // remove the outbound items
        for change in changes ?? [] {
            change.remove()
        }
        
        /* now work through the response */
        
        for group in response.Groups {
            
            for change in group.Changes {
                
                let value = change.Value ?? ""
                let record_id = change.RecordId!
                let class_name = change.Entity!
                let property = change.Property!
                
                // process this change
                if property.contains("__delete__") {
                    
                    /* just delete the record and add an entry into the destroyed table to prevent late arrivals from breaking things */
                    let deadObject = SRKSyncObject.object(fromClass: class_name, withPrimaryKey: record_id) as? SRKSyncObject
                    if deadObject != nil {
                        deadObject?.__removeRawNoSync()
                    }
                    let defObj = SRKDefunctObject()
                    defObj.defunctId = record_id
                    defObj.commit()
                    
                } else {
                    
                    // deal with an insert/update
                    
                    // existing object, uopdate the value
                    var decryptedValue = SharkSync.decryptValue(value)
                    let targetObject = SRKSyncObject.object(fromClass: class_name, withPrimaryKey: record_id) as? SRKSyncObject
                    if targetObject != nil {
                        
                        // check to see if this property is actually in the class, if not, store it for a future schema
                        for fieldName: String in targetObject!.fieldNames() {
                            if (fieldName == property) {
                                targetObject?.setField(property, value: decryptedValue as! NSObject)
                                if targetObject?.getRecordGroup() == nil {
                                    targetObject?.setRecordVisibilityGroup(group.Group!)
                                }
                                if targetObject?.__commitRaw(withObjectChainNoSync: nil) != nil {
                                    decryptedValue = nil
                                }
                            }
                        }
                        
                        if decryptedValue != nil {
                            
                            // cache this object for a future instance of the schema, when this field exists
                            let deferredChange = SRKDeferredChange()
                            deferredChange.key = record_id
                            deferredChange.className = class_name
                            deferredChange.value = value
                            deferredChange.property = property
                            deferredChange.commit()
                            
                        }
                        
                    }
                    else {
                        if SRKDefunctObject.query().where("defunctId = ?", parameters: [record_id]).count() > 0 {
                            // defunct object, do nothing
                        }
                        else {
                            // not previously defunct, but new key found, so create an object and set the value
                            let targetObject = SRKSyncObject.object(fromClass: class_name) as? SRKSyncObject
                            if targetObject != nil {
                                
                                targetObject!.id = record_id
                                
                                // check to see if this property is actually in the class, if not, store it for a future schema
                                for fieldName: String in targetObject!.fieldNames() {
                                    if (fieldName == property) {
                                        targetObject!.setField(property, value: decryptedValue as! NSObject)
                                        if targetObject?.getRecordGroup() == nil {
                                            targetObject?.setRecordVisibilityGroup(group.Group!)
                                        }
                                        if targetObject!.__commitRaw(withObjectChainNoSync: nil) {
                                            decryptedValue = nil
                                        }
                                    }
                                }
                                if decryptedValue != nil {
                                    // cache this object for a future instance of the schema, when this field exists
                                    let deferredChange = SRKDeferredChange()
                                    deferredChange.key = record_id
                                    deferredChange.className = class_name
                                    deferredChange.value = value
                                    deferredChange.property = property
                                    deferredChange.commit()
                                }
                            }
                        }
                    }
                }
                
            }
            
            // now update the group tidemark so as to not receive this data again
            let grp = SRKSyncGroup.groupWithEncodedName(group.Group!)
            if grp != nil {
                grp!.tidemark = group.Tidemark ?? 0
                grp!.last_polled = NSNumber(value: Date().timeIntervalSince1970)
                grp!.commit()
            }
            
        }
    }
}

