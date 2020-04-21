//
//  ViewController.swift
//  findYourPeers
//
//  Created by Howard Chang on 4/20/20.
//  Copyright © 2020 Howard Chang. All rights reserved.
//

import UIKit
import FirebaseFirestore

enum Category {
    case study
    case club
    case event
}

class FollowedGroupsController: UIViewController {

    private let followedGroupsView = FollowedGroupsView()
    
    override func loadView() {
        view = followedGroupsView
        followedGroupsView.backgroundColor = .white
    }
    private var listener: ListenerRegistration?
    private var followedGroups = [Group]() {
        didSet {
            DispatchQueue.main.async {
                self.followedGroupsView.collectionView.reloadData()
            }
        }
    }
    
    private var selectedCategory: Category = .study {
        didSet {
            DispatchQueue.main.async {
                self.followedGroupsView.collectionView.reloadData()
            }
        }
    }
     
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureSegmentControllerAndNavBar()
        fetchFollowedGroups()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
//        Firestore.firestore().collection(DatabaseService.userCollection).document(user.uid).collection(DatabaseService.artFavoritesCollection).addSnapshotListener { [weak self] (snapshot, error) in
//            if let error = error {
//                self?.showAlert(title: "error", message: error.localizedDescription)
//            } else if let snapshot = snapshot {
//                let items = snapshot.documents.compactMap { try? $0.data(as: ArtObject.self) }
//                self?.artPieces = items
//            }
//        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        listener?.remove()
    }
    private func fetchFollowedGroups() {
        DatabaseService.manager.getFavoriteGroups(item: Group.self, completion: { [weak self] (result) in
            switch result {
            case .failure(let error):
                print("could not get user's groups \(error.localizedDescription)")
            case .success(let groups):
                self?.followedGroups = groups
            }
            
        })
    }
    
    private func configureCollectionView() {
        followedGroupsView.collectionView.delegate = self
        followedGroupsView.collectionView.dataSource = self
        followedGroupsView.collectionView.register(GroupCell.self, forCellWithReuseIdentifier: "groupCell")
    }
    private func configureSegmentControllerAndNavBar() {
        followedGroupsView.categorySegmentedControl.addTarget(self, action: #selector(categorySelected(_:)), for: .valueChanged)
        navigationItem.title = "Your Groups"
    }
    @objc private func categorySelected(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedCategory = .study
            followedGroups = followedGroups.filter {$0.category == "study"}
        case 1:
            selectedCategory = .club
            followedGroups = followedGroups.filter {$0.category == "club"}
        case 2:
            selectedCategory = .event
           followedGroups = followedGroups.filter {$0.category == "event"}
        default:
            print("default case hit")
        }
    }
}
extension FollowedGroupsController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxsize: CGSize = UIScreen.main.bounds.size
        let itemWidth: CGFloat = maxsize.width * 0.9
        let itemHeight: CGFloat = maxsize.height * 0.20
        return CGSize(width: itemWidth, height: itemHeight)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
}
extension FollowedGroupsController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return followedGroups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = followedGroupsView.collectionView.dequeueReusableCell(withReuseIdentifier: "groupCell", for: indexPath) as? GroupCell else {
            fatalError("failed to cast to group cell")
        }
        cell.backgroundColor = #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //code to segue to group detail
    }
    
}
