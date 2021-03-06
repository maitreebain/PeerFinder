//
//  GroupDetailViewController.swift
//  findYourPeers
//
//  Created by Howard Chang on 4/20/20.
//  Copyright © 2020 Howard Chang. All rights reserved.
//

import UIKit
import Kingfisher

class GroupDetailViewController: UIViewController {

    private var groupDetailView = GroupDetailView()
    private var groupPostView = GroupCommentPostView()
    var group: Group
    private var post: Bool = false
    
    override func loadView() {
           view = groupDetailView
       }
    
    private var posts = [Post]() {
        didSet {
            groupDetailView.tableView.reloadData()
        }
    }
    
    init(_ group: Group) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isFavorite = false {
        didSet {
            DispatchQueue.main.async {
                if self.isFavorite == true {
                    self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "person.badge.plus.fill")
            } else {
                    self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "person.badge.plus")
            }
            }
        }
    }
    
    lazy private var favorite: UIBarButtonItem = {
                    [unowned self] in
           return UIBarButtonItem(image: UIImage(systemName: "person.badge.plus"), style: .plain, target: self, action: #selector(configureFavorites(_:)))
                    }()
    
    @objc private func configureFavorites(_ sender: UIBarButtonItem) {
        if isFavorite {
            DatabaseService.manager.deleteGroupFromFavorites(group.self) { [weak self] (result) in
                       switch result {
                       case .failure(let error):
                           self?.showAlert(title: "error", message: error.localizedDescription)
                       case .success:
                           self?.isFavorite = false
                               }
                           }
               } else {
                   DatabaseService.manager.addGroupToFavorties(group) { [weak self] (result) in
                       switch result {
                       case .failure(let error):
                           self?.showAlert(title: "error", message: error.localizedDescription)
                       case .success:
                           self?.isFavorite = true
                       }
                   }
               }
    }
    
    private func isGroupFavorited(_ group: Group) {
        DatabaseService.manager.groupIsFavorited(group) { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "error", message: error.localizedDescription)
            case .success(let success):
                if success {
                    self?.isFavorite = true
                } else {
                    self?.isFavorite = false
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = group.groupName.capitalized
        navigationItem.rightBarButtonItem = favorite
        groupDetailView.tableView.delegate = self
        groupDetailView.tableView.dataSource = self
        groupDetailView.tableView.register(GroupDetailViewCell.self, forCellReuseIdentifier: "GroupDetailViewCell")
        configureDetails()
        navigationController?.navigationBar.tintColor = customBorderColor
        isGroupFavorited(group)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
            groupPostView.addGestureRecognizer(tap)
        getPosts()
    }

    @objc func dismissKeyboard() {
           view.endEditing(true)
       }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        isGroupFavorited(group)
    }
    
    private func configureDetails() {
        groupDetailView.photoImageView.kf.setImage(with: URL(string: group.groupPhotoURL))
        groupDetailView.categoryLabel.text = "Category: \(group.category.capitalized)"
        groupDetailView.descriptionLabel.text = "created by: \(group.createdBy) \n\(group.description)"
        groupDetailView.titleLabel.text = group.groupName
        groupDetailView.commentButton.addTarget(self, action: #selector(startPostButtonPressed(_:)), for: .touchUpInside)
        groupPostView.cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        groupPostView.submitButton.addTarget(self, action: #selector(submitPostButtonPressed(_:)), for: .touchUpInside)
    }

    @objc private func startPostButtonPressed(_ sender: UIButton) {
        post = true
        view = groupPostView
        navigationController?.navigationBar.isHidden = true
    }
    
    @objc private func cancelButtonPressed() {
        post = false
        groupPostView.descriptionLabel.text = ""
        groupPostView.descriptionLabel.placeholder = "Comment"
        view = groupDetailView
        navigationController?.navigationBar.isHidden = false
    }
    
    @objc private func submitPostButtonPressed(_ sender: UIButton) {
        let text = groupPostView.descriptionLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let finishedText = text, !finishedText.isEmpty else {
            sender.shake()
            return
        }
        let userName = "Antonio Flores"
        let userID = "6cy5BFsR14xyjGXWBvDq"
        let timePosted = Date()
        let id = UUID().uuidString
        let post = Post(userName: userName, userId: userID, timePosted: timePosted, postText: finishedText, id: id)
        DatabaseService.manager.createPost(post, group: group) { [weak self] (result) in
            DispatchQueue.main.async {
            switch result {
            case .failure(let error):
                self?.showAlert(title: "error creating post", message: "\(error)")
            case .success:
                self?.posts.append(post)
                self?.cancelButtonPressed()
            }
            }
        }
    }
    
    private func getPosts() {
        DatabaseService.manager.getPosts(item: Post.self, group: group) { [weak self] (result) in
            DispatchQueue.main.async {
            switch result {
            case .failure(let error):
                self?.showAlert(title: "error getting posts", message: "\(error)")
            case .success(let posts):
                self?.posts = posts
            }
        }
        }
    }
}

extension GroupDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupDetailViewCell", for: indexPath) as? GroupDetailViewCell else {
            fatalError("could not downcast to SearchViewTableViewCell")
        }
        let post = posts[indexPath.row]
        cell.configureCell(post: post)
        cell.isUserInteractionEnabled = false
        return cell
    }
    
    
}

