//
//  ViewController.swift
//  todoAlarm
//
//  Created by jmj on 2023/06/18.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var myTable: UITableView!
    
    let current = Calendar.current
    
    var list:[Todo] = []
    var db = DBHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        myTable.dataSource = self
        myTable.delegate = self
        list = db.readTodos()
    }
    
    let customColor = UIColor(red: 1.0, green: 0.956, blue: 0.580, alpha: 1.0)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if list[indexPath.row].isAlarm == 0 { //알림설정안함
            guard let cell = myTable.dequeueReusableCell(withIdentifier: "defaultTodoCell", for: indexPath) as? DefaultTodoCell else{
                return UITableViewCell()
            }
            
            if current.isDateInToday(list[indexPath.row].datetime){
                cell.view.backgroundColor = customColor
            }
            
            cell.content.text = list[indexPath.row].content
            return cell
            
        }else{ //알림 설정 함
            guard let cell = myTable.dequeueReusableCell(withIdentifier: "alarmTodoCell", for: indexPath) as? AlarmTodoCell else{
                return UITableViewCell()
            }
            
            if current.isDateInToday(list[indexPath.row].datetime){
                cell.view.backgroundColor = customColor
            }
            
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "a hh시 mm분"
            
            cell.content.text = list[indexPath.row].content
            cell.alarmTime.text = dateFmt.string(from: list[indexPath.row].datetime)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    //추가
    @IBAction func addBtn(_ sender: Any) {
        showTodoAlert(type: .insert)
    }
    
    //삭제
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title: "삭제") { (UIContextualAction,UIView, success: @escaping (Bool) -> Void) in
            
            let id = self.list[indexPath.row].id
            
            self.db.deleteTodo(id: id)
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(id)])
            
            self.refresh()
            success(true)
        }
        
        delete.backgroundColor = .systemYellow
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    //업데이트
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showTodoAlert(type: .update, todo: list[indexPath.row])
    }
    
    func showTodoAlert(type:TodoViewType, todo:Todo?=nil){
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "TodoController") as? TodoController else{
            return
        }
        
        vc.type = type
        vc.todo = todo
        vc.delegate = self
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: false)
    }
}

extension ViewController:TodoDelegate{
    func insert(content:String, datetime:Date, isAlarm:Bool) {
        
        if isAlarm {
            UNUserNotificationCenter.current().getNotificationSettings{ settings in
                if settings.authorizationStatus == .authorized{ //권한을 혀용한 경우
                    
                    let id = self.db.insertTodo(content: content, datetime: datetime, isAlarm: 1)
                    
                    let timeInterval = datetime.timeIntervalSinceNow
                    
                    if timeInterval > 0 { // 설정 시간이 지금시간보다 미래인경우, 알림을 등록할 수 있음
                        let nContent = UNMutableNotificationContent()
                        nContent.title = "[할일] 알림"
                        nContent.body = content
                        nContent.sound = .default
                        
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                        let request = UNNotificationRequest(identifier: String(id!), content: nContent, trigger: trigger)
                        UNUserNotificationCenter.current().add(request) { error in
                            
                            //화면처리는 오직 메인쓰레드에서만 가능하기 떄문에
                            //DispatchQueue.main.async를 감싸줘야함 
                            DispatchQueue.main.async {
                                self.refresh()
                            }
                        }
                        
                    }else{
                        DispatchQueue.main.async {
                            self.refresh()
                        }
                    }
                    
                }else if settings.authorizationStatus == .denied{ //권한 거부시 허용할 수 있도록 세팅창을 띄움
                    if let url = URL(string: UIApplication.openSettingsURLString){
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }else{
            let id = self.db.insertTodo(content: content, datetime: datetime, isAlarm: 0)
            self.refresh()
        }
    }
    
    func update(id:Int32, content:String, datetime:Date, isAlarm:Bool) {
        
        //알림 삭제: 알림이 등록되어 있지 않아도 오류가 안남
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(id)])
        
        //알림을 설정한 경우
        if isAlarm {
            UNUserNotificationCenter.current().getNotificationSettings{ settings in
                if settings.authorizationStatus == .authorized{ //권한을 혀용한 경우
                    
                    self.db.updateTodo(id: id, content: content, datetime: datetime, isAlarm: 1)
                    
                    let timeInterval = datetime.timeIntervalSinceNow
                    
                    if timeInterval > 0 { // 시간이 지금시간보다 미래인경우, 알림을 등록
                        let nContent = UNMutableNotificationContent()
                        nContent.title = "[할일] 알림"
                        nContent.body = content
                        nContent.sound = .default
                        
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                        let request = UNNotificationRequest(identifier: String(id), content: nContent, trigger: trigger)
                        
                        UNUserNotificationCenter.current().add(request) { error in
                            DispatchQueue.main.async {
                                self.refresh()
                            }
                        }
                    }else{
                        DispatchQueue.main.async {
                            self.refresh()
                        }
                    }
                    
                }else if settings.authorizationStatus == .denied{ //권한 거부시 허용할 수 있도록 세팅창을 띄움
                    if let url = URL(string: UIApplication.openSettingsURLString){
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }else{
            db.updateTodo(id: id, content: content, datetime: datetime, isAlarm: 0)
            self.refresh()
        }
    }
    
    func refresh(){
        print("화면 갱신")
        list = db.readTodos()
        myTable.reloadData()
    }
}

protocol TodoDelegate{
    func insert(content:String, datetime:Date, isAlarm:Bool)
    
    func update(id:Int32, content:String, datetime:Date, isAlarm:Bool)
}

