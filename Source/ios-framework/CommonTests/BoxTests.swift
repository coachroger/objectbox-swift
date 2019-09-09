//
// Copyright © 2019 ObjectBox Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
@testable import ObjectBox // Give us access to internal methods like box(for: EntityInfo)

// swiftlint:disable identifier_name type_body_length force_try

enum BoxTestError: Error {
    case generalError
    case generalError2
}

class BoxTests: XCTestCase {
    
    var store: Store!
    
    override func setUp() {
        super.setUp()
        store = StoreHelper.tempStore(model: createTestModel())
    }
    
    override func tearDown() {
        try! store?.closeAndDeleteAllFiles()
        store = nil
        super.tearDown()
    }
    
    func testGetNonexistingIDInEmptyBox() {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count, 0)
        XCTAssertNil(box.get(Id<TestPerson>(12345)))
    }
    
    func testPutGet() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count, 0)
        
        let person1 = TestPerson(name: "Søren🙈", age: 42)
        let person1Id = try box.put(person1)
        
        XCTAssertNotEqual(person1Id.value, 0)
        XCTAssertEqual(box.count, 1)
        
        let person2 = TestPerson(name: "κόσμε", age: 40)
        let person2Id = try box.put(person2)
        
        XCTAssertNotEqual(person2Id.value, 0)
        XCTAssertEqual(box.count, 2)
        
        XCTAssertNotEqual(person1Id, person2Id)
        
        let fetchedPerson1 = box.get(person1Id)
        XCTAssertNotNil(fetchedPerson1)
        XCTAssertEqual(fetchedPerson1?.name, person1.name)
        XCTAssertEqual(fetchedPerson1?.age, person1.age)
        
        let fetchedPerson2 = box.get(person2Id)
        XCTAssertNotNil(fetchedPerson2)
        XCTAssertEqual(fetchedPerson2?.name, person2.name)
        XCTAssertEqual(fetchedPerson2?.age, person2.age)
    }
    
    func testPutGetDictionary() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count, 0)
        
        let person1Id = try box.put(TestPerson(name: "Foo", age: 55))
        let person2Id = try box.put(TestPerson(name: "Bar", age: 66))
        let person3Id = try box.put(TestPerson(name: "Baz", age: 77))
        
        XCTAssertNotEqual(person1Id.value, 0)
        XCTAssertNotEqual(person2Id.value, 0)
        XCTAssertNotEqual(person3Id.value, 0)
        XCTAssertEqual(box.count, 3)
        
        let entitiesById = box.dictionaryWithEntities(forIds: [person3Id, person1Id])
        XCTAssertEqual(entitiesById.count, 2)
        XCTAssertEqual(entitiesById[person1Id]?.name, "Foo")
        XCTAssertNil(entitiesById[person2Id])
        XCTAssertEqual(entitiesById[person3Id]?.name, "Baz")
    }
    
    func testPutGet_AllPropertyTypes() throws {
        let box: Box<AllTypesEntity> = store.box(for: AllTypesEntity.self)
        
        let entity = AllTypesEntity()
        entity.boolean = true
        entity.integer = Int32.max - 10
        entity.uInteger = UInt.max - 3
        entity.aDouble = 12345.9876
        entity.date = Date(timeIntervalSince1970: 1234567890)
        entity.string = "a string"
        
        let entityId = try box.put(entity)
        
        XCTAssertNotEqual(entityId.value, 0)
        XCTAssertEqual(box.count, 1)
        
        let fetchedEntity = box.get(entityId)
        XCTAssertNotNil(fetchedEntity)
        XCTAssertEqual(fetchedEntity?.boolean, entity.boolean)
        XCTAssertEqual(fetchedEntity?.integer, entity.integer)
        XCTAssertEqual(fetchedEntity?.uInteger, entity.uInteger)
        XCTAssertEqual(fetchedEntity?.aDouble, entity.aDouble)
        XCTAssertEqual(fetchedEntity?.date, entity.date)
        XCTAssertEqual(fetchedEntity?.string, entity.string)
    }
    
    
    func testPutGet_Dates() throws {
        let box: Box<AllTypesEntity> = store.box(for: AllTypesEntity.self)
        
        try box.put([AllTypesEntity.create(date: Date(timeIntervalSince1970: 0)),
                     AllTypesEntity.create(date: Date(timeIntervalSince1970: 1)),
                     AllTypesEntity.create(date: Date(timeIntervalSince1970: 2))])
        
        XCTAssertEqual(box.count, 3)
        
        let allEntities = box.all()
        XCTAssertEqual(allEntities.count, 3)
        XCTAssert(allEntities.contains(where: { obj -> Bool in
            obj.date?.timeIntervalSince1970 == 0
        }))
        XCTAssert(allEntities.contains(where: { obj -> Bool in
            obj.date?.timeIntervalSince1970 == 1
        }))
        XCTAssert(allEntities.contains(where: { obj -> Bool in
            obj.date?.timeIntervalSince1970 == 2
        }))
    }

    func testPutGetStruct() throws {
        let box: Box<StructEntity> = store.box(for: StructEntity.self)
        
        XCTAssertEqual(box.count, 0)
        
        let entity1 = StructEntity(id: Id<StructEntity>(0), message: "Carol Kaehler wrote the docs.",
                                   date: Date(timeIntervalSince1970: -500))
        let entity1Id = try box.putImmutable(entity1)
        
        XCTAssertNotEqual(entity1Id.value, 0)
        XCTAssertEqual(box.count, 1)
        
        let entity2 = StructEntity(id: Id<StructEntity>(0), message: "Kristee Kreitman and Marge Boots did the art 👩‍🎨",
                                   date: Date(timeIntervalSince1970: 900))
        let entity2Written = try box.put(struct: entity2)
        
        XCTAssertNotEqual(entity2Written.id.value, 0)
        XCTAssertEqual(box.count, 2)
        
        XCTAssertNotEqual(entity1Id, entity2Written.id)
        
        let fetchedEntity1 = box.get(entity1Id)
        XCTAssertNotNil(fetchedEntity1)
        XCTAssertEqual(fetchedEntity1?.message, entity1.message)
        XCTAssertEqual(fetchedEntity1?.date, entity1.date)
        
        let fetchedEntity2 = box.get(entity2Written.id)
        XCTAssertNotNil(fetchedEntity2)
        XCTAssertEqual(fetchedEntity2?.message, entity2.message)
        XCTAssertEqual(fetchedEntity2?.date, entity2.date)
    }

    func testPutInWriteTransactionRollback() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count, 0)
        
        XCTAssertThrowsError(try store.runInTransaction {
            try box.put(TestPerson.irrelevant)
            
            throw BoxTestError.generalError
        })
        
        XCTAssertEqual(box.count, 0)
    }
    
    func testPutSameEntityTwice() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        let person = TestPerson(name: "Ryu", age: 20)
        
        let firstPersonId = try box.put(person)
        XCTAssertNotEqual(firstPersonId.value, 0)
        
        let secondPersonId = try box.put(person)
        XCTAssertNotEqual(secondPersonId.value, 0)

        XCTAssertEqual(secondPersonId, firstPersonId)
    }
    
    func testNestedWriteTransactionRollback() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count, 0)
        
        XCTAssertThrowsError(try store.obx_runInTransaction { _ in
            try box.put(TestPerson.irrelevant)
            
            try store.obx_runInTransaction { _ in
                try box.put(TestPerson.irrelevant)
                
                throw BoxTestError.generalError2
            }
        })
        
        XCTAssertEqual(box.count, 0)
    }
    
    func testWriteAfterTransactionFailureIsRolledBack() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count, 0)
        
        XCTAssertThrowsError(try store.obx_runInTransaction { _ in
            try store.obx_runInTransaction { _ in
                throw BoxTestError.generalError2
            }
            
            XCTAssertNoThrow(try box.put(TestPerson.irrelevant))
        })
        
        // TODO: Should the put itself be aborted or error-out? (Would need an early exit flag like isClosed)
        XCTAssertEqual(box.count, 0)
    }

    func testPutGetAllRemoveAll() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        // Precondition
        XCTAssertEqual(box.count, 0)
        
        let count = 100
        var persons = [TestPerson]()
        for i in 0 ..< count {
            persons.append(TestPerson(name: "\(i)", age: i))
        }
        
        try box.put(persons)
        
        XCTAssertEqual(box.count, count)
        
        let allEntities = box.all().sorted { (obj1, obj2) -> Bool in
            return (obj1.name ?? "").compare(obj2.name ?? "", options: .numeric) == .orderedAscending
        }
        for i in 0 ..< count {
            XCTAssertEqual(allEntities[i].name, "\(i)")
            XCTAssertEqual(allEntities[i].age, i)
        }
        
        XCTAssertEqual(count, Int(try box.removeAll()))
        XCTAssertEqual(box.count, 0)
    }
    
    func testCountMax() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count(limit: 0), 0) // 0 == no limit
        XCTAssertEqual(box.count(limit: 1), 0)
        XCTAssertEqual(box.count(limit: 10000), 0)

        let count = 100
        var persons = [TestPerson]()
        for i in 0 ..< count {
            persons.append(TestPerson(name: "\(i)", age: i))
        }
        
        try box.put(persons)
        
        XCTAssertFalse(box.isEmpty)
        XCTAssertEqual(box.count(limit: 0), 100) // 0 == no limit
        XCTAssertEqual(box.count(limit: 1), 1)
        XCTAssertEqual(box.count(limit: 100), 100)
        XCTAssertEqual(box.count(limit: 101), 100)
        XCTAssertEqual(box.count(limit: 10000), 100)
    }

    func testRemoveById() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        XCTAssertEqual(box.count, 0)

        let person1Id = try box.put(TestPerson(name: "🤢", age: 123))
        let person2Id = try box.put(TestPerson(name: "🍒", age: 234))

        XCTAssertNotEqual(person1Id.value, 0)
        XCTAssertNotEqual(person2Id.value, 0)

        XCTAssertEqual(box.count, 2)
        XCTAssertNotEqual(person1Id, person2Id)
        
        XCTAssertNoThrow(try box.remove(person2Id))
        XCTAssertEqual(box.count, 1)
        XCTAssertEqual(box.all().first?.name, "🤢")
    }

    func testContains() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 10 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        XCTAssert(box.contains(persons[2].id))
        XCTAssert(box.contains([persons[6].id, persons[2].id, persons[5].id, persons[8].id]))
        try box.remove(persons[5].id)
        XCTAssertFalse(box.contains([persons[6].id, persons[2].id, persons[5].id, persons[8].id]))
    }

    // MARK: - visiting
    
    func testForEach() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 10 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 0
        box.forEach { person in
            XCTAssertEqual(currAge, person.age)
            currAge += 1
        }
        XCTAssertEqual(persons.count, currAge)
    }
    
    func testForEachThrows() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 4 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 0
        XCTAssertThrowsError(try box.forEach { person in
            XCTAssertEqual(currAge, person.age)
            currAge += 1
            throw BoxTestError.generalError
        })
        XCTAssertEqual(1, currAge)
    }
    
    func testVisit() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 10 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 0
        box.visit { person in
            XCTAssertEqual(currAge, person.age)
            currAge += 1
            return currAge < 5
        }
        XCTAssertEqual(5, currAge)
    }
    
    func testVisitThrows() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 2 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 0
        XCTAssertThrowsError(try box.visit { person in
            XCTAssertEqual(currAge, person.age)
            currAge += 1
            throw BoxTestError.generalError
        })
        XCTAssertEqual(1, currAge)
    }

    func testForIn() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 10 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 1
        box.for(persons.map { $0.id }.dropFirst().dropLast()) { person in
            XCTAssertEqual(currAge, person?.age)
            currAge += 1
        }
        XCTAssertEqual(persons.count - 1, currAge)
    }
    
    func testForInThrows() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 4 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 1
        XCTAssertThrowsError(try box.for(persons.map { $0.id }.dropFirst().dropLast()) { person in
            XCTAssertEqual(currAge, person?.age)
            currAge += 1
            throw BoxTestError.generalError
        })
        XCTAssertEqual(2, currAge)
    }
    
    func testVisitIn() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 10 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 1
        box.visit(persons.map { $0.id }.dropFirst().dropLast()) { person in
            XCTAssertEqual(currAge, person?.age)
            currAge += 1
            return currAge < 5
        }
        XCTAssertEqual(5, currAge)
    }
    
    func testVisitInThrows() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        var persons = [TestPerson]()
        for i in 0 ..< 4 {
            persons.append(TestPerson(name: "Johnny \(i)", age: i))
        }
        
        try box.put(persons)
        
        var currAge = 1
        XCTAssertThrowsError(try box.visit(persons.map { $0.id }.dropFirst().dropLast()) { person in
            XCTAssertEqual(currAge, person?.age)
            currAge += 1
            throw BoxTestError.generalError
            })
        XCTAssertEqual(2, currAge)
    }
    
    func testBoxDescription() throws {
        let box: Box<TestPerson> = store.box(for: TestPerson.self)
        
        let debugDescription = "\(box)"
        XCTAssert(debugDescription.hasPrefix("<ObjectBox.Box"))
        XCTAssert(debugDescription.contains("TestPerson"))
    }
}