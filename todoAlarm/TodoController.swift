//
//  TodoController.swift
//  todoAlarm
//
//  Created by jmj on 2023/06/19.
//

import UIKit

class TodoController : UIViewController{
    
    @IBOutlet weak var alartTitle: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var datetime: UIDatePicker!
    @IBOutlet weak var swich: UISwitch!
    
    
    var type:TodoViewType = .insert
    var todo:Todo?
    
    var isAlarm = false
    
    var delegate:TodoDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if type == .insert{
            alartTitle.text = "추가"
        }else{
            alartTitle.text = "수정"
            textField.text = todo?.content
            datetime.date = todo?.datetime ?? Date()
            if todo?.isAlarm == 1 {
                isAlarm = true
                swich.setOn(true, animated: false)
            }
            
        }
    }
    
    @IBAction func swichBtn(_ sender: Any) {
        if swich.isOn{
            isAlarm = true
        }else{
            isAlarm = false
        }
    }
    
    
    @IBAction func cancelBtnTouched(_ sender: Any) {
        self.dismiss(animated: false)
    }
    
    
    @IBAction func okBtnTouched(_ sender: Any) {
        
        if let text = textField.text, !text.isEmpty{
            if type == .insert{
                delegate?.insert(content: text, datetime: datetime.date, isAlarm: isAlarm)
            }else{
                delegate?.update(id: todo!.id, content: text, datetime: datetime.date, isAlarm: isAlarm)
            }
            self.dismiss(animated: false)
        }
    }
    
}

enum TodoViewType{
    case update, insert
}

