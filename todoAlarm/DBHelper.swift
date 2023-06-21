//
//  DBHelper.swift
//  todoAlarm
//
//  Created by jmj on 2023/06/18.
//

import Foundation
import SQLite3

class DBHelper{
    var db:OpaquePointer?
    
    init(){
        self.db = createDB()
        createTable()
    }
    
    func createDB() -> OpaquePointer?{
        var db:OpaquePointer? = nil
        
        do{
            let dbPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathExtension("mydb.sqlite").path
            
            print("dbPath : \(dbPath)")
            if sqlite3_open(dbPath, &db) == SQLITE_OK{
                return db
            }
        }catch{
          print("error")
        }
        
        return nil
    }
    
    func createTable(){
        let query = """
            create table if not exists todos(
                id integer primary key autoincrement,
                content text not null,
                datetime text not null,
                isAlarm integer not null
            )
        """
        
        var statement:OpaquePointer? = nil
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK{
            if sqlite3_step(statement) == SQLITE_DONE{
                print("테이블 생성 성공")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func readTodos() -> [Todo]{
        let query = "select * from todos order by datetime"
        var statement:OpaquePointer? = nil
        var list:[Todo] = []
        var dateFmt = DateFormatter()
        
        dateFmt.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK{
            while sqlite3_step(statement) == SQLITE_ROW{
                let id = sqlite3_column_int(statement, 0)
                let content = String(cString: sqlite3_column_text(statement, 1))
                let datetime = String(cString: sqlite3_column_text(statement, 2))
                let isAlarm = sqlite3_column_int(statement, 3)
                
                print("id: \(id) content: \(content) datetime:\(datetime) isAlarm: \(isAlarm)")
                
                if let stringTodate = dateFmt.date(from: datetime) {
                    list.append(Todo(id: id, content: content, datetime: stringTodate, isAlarm: isAlarm))
                }
            }
        }
        
        sqlite3_finalize(statement)
        return list
    }
    
    func insertTodo(content:String, datetime:Date, isAlarm:Int32) -> Int64? {
        let query = "insert into todos(content, datetime, isAlarm) values(?,?,?)"
        var statement:OpaquePointer? = nil
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK{
            
            let cContent = content.cString(using: .utf8)
            let cDateTime = dateFmt.string(from: datetime).cString(using: .utf8)
            
            sqlite3_bind_text(statement, 1, cContent, -1, nil)
            sqlite3_bind_text(statement, 2, cDateTime, -1, nil)
            
            sqlite3_bind_int(statement, 3, isAlarm)
            
            if sqlite3_step(statement) == SQLITE_DONE{
                print("삽입 완료")
                let rowId = sqlite3_last_insert_rowid(self.db) //int64를 반환 
                
                return rowId
            }
        }
        sqlite3_finalize(statement)
        return nil
    }
    
    func deleteTodo(id:Int32){
        let query = "delete from todos where id = ?"
        var statement:OpaquePointer? = nil
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK{
            sqlite3_bind_int(statement, 1, id)
            
            if sqlite3_step(statement) == SQLITE_DONE{
                print("데이터 삭제에 성공함")
            }
        }
        
        sqlite3_finalize(statement)
        
    }
    
    func updateTodo(id:Int32,content:String, datetime:Date, isAlarm:Int32){
        let query = "update todos set content = ? , datetime = ?, isAlarm = ? where id = ?"
        var statement:OpaquePointer? = nil
        var dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK{
            
            let cContent = content.cString(using: .utf8)
            let cDatetime = dateFmt.string(from: datetime).cString(using: .utf8)
            
            sqlite3_bind_text(statement, 1, cContent, -1, nil)
            sqlite3_bind_text(statement, 2, cDatetime, -1, nil)
            sqlite3_bind_int(statement, 3, isAlarm)
            sqlite3_bind_int(statement, 4, id)
            
            if sqlite3_step(statement) == SQLITE_DONE{
                print("데이터 수정에 성공함")
            }
        }
        sqlite3_finalize(statement)
    }
    
    
}

class Todo{
    let id:Int32
    let content:String
    let datetime:Date
    let isAlarm:Int32
    
    init(id: Int32, content: String, datetime: Date, isAlarm: Int32) {
        self.id = id
        self.content = content
        self.datetime = datetime
        self.isAlarm = isAlarm
    }
}
