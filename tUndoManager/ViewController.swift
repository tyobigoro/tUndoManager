//
//  ViewController.swift
//  tUndoManager
//
//  Created by tyobigoro on 2020/07/21.
//  Copyright © 2020 tyobigoro. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editBtn  : UIButton!
    @IBOutlet weak var undoBtn  : UIButton!
    @IBOutlet weak var redoBtn  : UIButton!
    @IBOutlet weak var addBtn   : UIButton!
    @IBOutlet weak var removeBtn: UIButton!
    @IBOutlet weak var renameBtn: UIButton!
    
    var alert: UIAlertController?
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        dataSource = DataSource()
        dataSource.updataTableViewCellDelegate = self
        
        updateEditBtns()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    // state management / toggle Btns enable/disable
    func updateEditBtns() {
        addBtn.isEnabled = !tableView.isEditing
        removeBtn.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0 > 0) && tableView.isEditing
        renameBtn.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0 == 1)  && tableView.isEditing
        undoBtn.isEnabled = dataSource.undoManager.canUndo && !tableView.isEditing
        redoBtn.isEnabled = dataSource.undoManager.canRedo && !tableView.isEditing
    }
    
    // toggle okBtn enable/disable
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.alert?.actions.first?.isEnabled = !(self.alert?.textFields?.first?.text?.isEmpty ?? true)
        }
        return true
    }
    
    // state management tableViewEditing
    func updateTableViewIsEditing(isEditing: Bool) {
        if tableView.isEditing == isEditing { return }
        UIView.animate(withDuration: 0.4, animations: {
            self.tableView.isEditing = isEditing
        }, completion: { _ in
            self.tableView.allowsMultipleSelectionDuringEditing = self.tableView.isEditing
            self.editBtn.titleLabel?.text = self.tableView.isEditing ? "end" : "edit"
            self.updateEditBtns()
        })
    }
    
    // actions
    // changeTableViewEditMode
    @IBAction func editBtnDidTap(_ sender: Any) {
        updateTableViewIsEditing(isEditing: !tableView.isEditing)
    }
    
    @IBAction func addBtnDidTap(_ sender: Any) {
        let alert = UIAlertController(title: "addMember", message: "inputName", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (tf) in
            tf.delegate = self
        })
        
        let ok = UIAlertAction(title: "Add", style: .default, handler: { _ in
            let name = alert.textFields?.first?.text ?? ""
            let person = (index: self.dataSource.members.persons.endIndex, person: Person(name: name))
            self.dataSource.addMembers(persons: [person])
        })
        ok.isEnabled = false
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.alert = alert
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func removeBtnDidTap(_ sender: Any) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
        self.dataSource.removeMembers(indexPaths: indexPaths)
    }
    
    @IBAction func renameBtnDidTap(_ sender: Any) {
        guard let indexPath = tableView.indexPathsForSelectedRows?.first else { return }
        
        let person = dataSource.getPerson(indexPath: indexPath)
        
        let alert = UIAlertController(title: "renameMember", message: "editName", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (tf) in
            tf.delegate = self
            tf.text = person.name
        })
        
        let ok = UIAlertAction(title: "rename", style: .default, handler: { _ in
            let name = alert.textFields?.first?.text ?? ""
            self.dataSource.editPersonName(indexPath: indexPath, name: name)
        })
        ok.isEnabled = false
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.alert = alert
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func undoBtnDidTap(_ sender: Any) {
        dataSource.undoManager.undo()
        updateEditBtns()
    }
    
    @IBAction func redoBtnDidTap(_ sender: Any) {
        dataSource.undoManager.redo()
        updateEditBtns()
    }
    
}

extension ViewController: UpdataTableViewCellDelegate {
    
    func sortCell(from: IndexPath, to: IndexPath) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [from], with: .automatic)
        tableView.insertRows(at: [to], with: .automatic)
        tableView.endUpdates()
    }
    
    func addCells(indexPaths: [IndexPath]) {
        tableView.insertRows(at: indexPaths, with: .automatic)
    }
    
    func removeCells(indexPaths: [IndexPath]) {
        tableView.deleteRows(at: indexPaths, with: .automatic)
    }
    
    func reloadCell(indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
}

extension ViewController: UITableViewDataSource {
    
    // numOfCell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numOfCell
    }
    
    // generate Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataSource.getTitle(indexPath: indexPath)
        return cell
    }
    
    // sortable
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // sortData
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        dataSource.sortMembers(sourceIndexPath: sourceIndexPath, destinatiomIndexPath: destinationIndexPath)
    }
}

extension ViewController: UITableViewDelegate {
    
    // selectRow
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateEditBtns()
    }
    
    // deselectRow
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        updateEditBtns()
    }
    
    // indicateEditButton
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.init(rawValue: 3)!
    }
    
    // spaceOfEditIco
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPaht: IndexPath) -> Bool {
        return true
    }
    
}

protocol UpdataTableViewCellDelegate: AnyObject {
    func updateTableViewIsEditing(isEditing: Bool)
    func updateEditBtns()
    func sortCell(from: IndexPath, to: IndexPath)
    func addCells(indexPaths: [IndexPath])
    func removeCells(indexPaths: [IndexPath])
    func reloadCell(indexPath: IndexPath)
}

class DataSource {
    
    weak var updataTableViewCellDelegate: UpdataTableViewCellDelegate?
    
    let undoManager: UndoManager!
    
    var members = Members()
    
    var numOfCell: Int { members.persons.count }
    
    func getTitle(indexPath: IndexPath) -> String {
        return members.persons[indexPath.row].name
    }
    
    func getPerson(indexPath: IndexPath) -> Person {
        return members.persons[indexPath.row]
    }
    
    func addMembers(persons: [(index: Int, person: Person)]) {
        var indexPaths = [IndexPath]()
        persons.sorted { $0.index < $1.index}.forEach {
            members.persons.insert($0.person, at: $0.index)
            indexPaths.append($0.index.indexPath)
        }
        
        updataTableViewCellDelegate?.addCells(indexPaths: indexPaths)
        updataTableViewCellDelegate?.updateTableViewIsEditing(isEditing: false)
        
        undoManager.registerUndo(withTarget: self) {
            $0.removeMembers(indexPaths: indexPaths)
        }
        
        updataTableViewCellDelegate?.updateEditBtns()
    }
    
    func removeMembers(indexPaths: [IndexPath]) {
        var persons = [(index: Int, person: Person)]()
        indexPaths.sorted { $0.row > $1.row }.forEach {
            let person = members.persons.remove(at: $0.row)
            persons.append((index: $0.row, person: person))
        }
        
        updataTableViewCellDelegate?.removeCells(indexPaths: indexPaths)
        updataTableViewCellDelegate?.updateTableViewIsEditing(isEditing: false)
        
        undoManager.registerUndo(withTarget: self) {
            $0.addMembers(persons: persons)
        }
        
        updataTableViewCellDelegate?.updateEditBtns()
    }
    
    func editPersonName(indexPath: IndexPath, name: String) {
        let person = getPerson(indexPath: indexPath)
        let oldName = person.name
        person.name = name
        
        updataTableViewCellDelegate?.reloadCell(indexPath: indexPath)
        updataTableViewCellDelegate?.updateTableViewIsEditing(isEditing: false)
        
        undoManager.registerUndo(withTarget: self) {
            $0.editPersonName(indexPath: indexPath, name: oldName)
        }
        
        updataTableViewCellDelegate?.updateEditBtns()
    }
    
    func sortMembers(sourceIndexPath: IndexPath, destinatiomIndexPath: IndexPath) {
        let p = members.persons.remove(at: sourceIndexPath.row)
        members.persons.insert(p, at: destinatiomIndexPath.row)
        updataTableViewCellDelegate?.updateTableViewIsEditing(isEditing: false)
        
        undoManager.registerUndo(withTarget: self) {
            $0.sortMembers(sourceIndexPath: destinatiomIndexPath, destinatiomIndexPath: sourceIndexPath)
        }
        
        if undoManager.isUndoing || undoManager.isRedoing {
            updataTableViewCellDelegate?.sortCell(from: sourceIndexPath, to: destinatiomIndexPath)
        }
        
    }
    
    init() {
        undoManager = UndoManager()
    }
}

class Members {
    
    var typeOfGroup: String = ""
    var persons: [Person]
    
    init() {
        self.persons = [Person(name: "a"),
                        Person(name: "b"),
                        Person(name: "c"),
                        Person(name: "d"),
                        Person(name: "e"),
                        Person(name: "f")
        ]
    }
}

class Person {
    
    var name: String
    var memo: String
    
    init(name: String, memo: String = "") {
        self.name = name
        self.memo = memo
    }
}

extension Int {
    var indexPath: IndexPath { IndexPath(row: self, section: 0) }
}
