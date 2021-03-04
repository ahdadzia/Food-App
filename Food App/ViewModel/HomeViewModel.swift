//
//  HomeViewModel.swift
//  Food App
//
//  Created by Ahda  Dzia Ulhaq on 01/03/21.
//

import SwiftUI
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class HomeViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
  
  @Published var locationManager = CLLocationManager()
  @Published var search = ""
  
  @Published var userLocation: CLLocation!
  @Published var userAddress = ""
  @Published var noLocation = false
  
  @Published var showMenu = false
  
  @Published var items: [Item] = [] // untuk semua data
  @Published var filtered: [Item] = [] // untuk data yang dicari
    
    @Published var cartItems: [Cart] = []
    @Published var ordered = false
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse:
      print("authorized")
      self.noLocation = false
      manager.requestLocation()
      
    case .denied:
      print("denied")
      self.noLocation = true
    
    default:
      print("Unknown")
      self.noLocation = false
      locationManager.requestWhenInUseAuthorization()
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print(error.localizedDescription)
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    self.userLocation = locations.last
    self.extractLocation()
    self.login()
  }
  
  func extractLocation(){
    CLGeocoder().reverseGeocodeLocation(self.userLocation) { (res, err) in
      
      guard let safeData = res else { return }
      
      var address = ""
      
      address += safeData.first?.name ?? ""
      address += ", "
      address += safeData.first?.locality ?? ""
      
      self.userAddress = address
    }
  }
  
  func login(){
    Auth.auth().signInAnonymously{ (res, err) in
      
      if err != nil {
        print(err!.localizedDescription)
        return
      }
      
      print("Success = \(res!.user.uid)")
      
      self.fetchData()
    }
  }
  
  func fetchData(){
    
    let db = Firestore.firestore()
    
    db.collection("Items").getDocuments{ (snap, err) in
      
      guard let itemData = snap else { return }
      
      self.items = itemData.documents.compactMap({ (doc) -> Item? in
        
        let id = doc.documentID
        let name = doc.get("item_name") as! String
        let cost = doc.get("item_cost") as! NSNumber
        let ratings = doc.get("item_ratings") as! String
        let image = doc.get("item_image") as! String
        let details = doc.get("item_details") as! String
        
        return Item(id: id, item_name: name, item_cost: cost, item_details: details, item_image: image, item_ratings: ratings)
                
      })
      
      self.filtered = self.items
    }
  }
  
  func filterData(){
    withAnimation(.linear){
      self.filtered = self.items.filter{
        return $0.item_name.lowercased().contains(self.search.lowercased())
      }
    }
  }
    
    func addToCart(item: Item){
        // udah di add ke cart belom?
        self.items[getIndex(item: item, isCartIndex: false)].isAdded = !item.isAdded
        
        // update filter yg di search
        let filterIndex = self.filtered.firstIndex{ (item1) -> Bool in
            return item.id == item1.id
        } ?? 0
        
        self.filtered[filterIndex].isAdded = !item.isAdded
        
        if item.isAdded {
            // menghapus dari list
            self.cartItems.remove(at: getIndex(item: item, isCartIndex: true))
            return
        }
        
        // baru kita tambahkan ke cart
        self.cartItems.append(Cart(item: item, quantity: 1))
    }
    
    func getIndex(item: Item, isCartIndex: Bool) -> Int{
        
        let index = self.items.firstIndex{ (item1) -> Bool in
            return item.id == item1.id
        } ?? 0
        
        let cartIndex = self.items.firstIndex{ (item1) -> Bool in
            return item.id == item1.id
        } ?? 0
        
        return isCartIndex ? cartIndex : index
    }
    
    func calculatedTotalPrice() -> String {
        
        var price: Float = 0
        
        cartItems.forEach{ (item) in
            price += Float (item.quantity) * Float(truncating: item.item.item_cost)
        }
        
        return getPrice(value: price)
    }
    
    // fungsi untuk merubah angka harga ke string
    func getPrice(value: Float) -> String {
        let format = NumberFormatter()
        format.numberStyle = .currency
        
        return format.string(from: NSNumber(value: value)) ?? ""
    }
    
    // fungsi mengupdate orderan ke firebase
    func updateOrders(){
        let db = Firestore.firestore()
        
        if ordered{
            ordered = false
            db.collection("Users").document(Auth.auth().currentUser!.uid).delete(){ (err) in
                if err != nil {
                    self.ordered = true
                }
            }
            
            return
        }
        
        // membuat data dari detail makanan dalam dictionary
        var details: [[String: Any]] = []
        
        cartItems.forEach{ (cart) in
            details.append([
                "item_name": cart.item.item_name,
                "item_cost": cart.item.item_cost,
                "item_quantity": cart.quantity
            ])
        }
        
        ordered = true
        
        db.collection("Users").document(Auth.auth().currentUser!.uid).setData([
            "ordered_food": details,
            "total_cost": calculatedTotalPrice(),
            "location": GeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        ]){ (err) in
            if err != nil{
                self.ordered = false
                return
            }
            print("Success")
        }
    }
}
