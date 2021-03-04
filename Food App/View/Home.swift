//
//  Home.swift
//  Food App
//
//  Created by Ahda  Dzia Ulhaq on 01/03/21.
//

import SwiftUI

struct Home: View {
    
    @StateObject var HomeModel = HomeViewModel()
    
    var body: some View {
        ZStack{
            VStack(spacing: 10){
                HStack(spacing: 15){
                    Button(action: {withAnimation(.easeIn){ HomeModel.showMenu.toggle()}
                    }, label: {
                        Image(systemName: "line.horizontal.3")
                            .font(.title)
                            .foregroundColor(.pink)
                    })
                    
                    Text(HomeModel.userLocation == nil ? "Locating..." : "Deliver to")
                        .foregroundColor(.black)
                    
                    Text(HomeModel.userAddress)
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(.pink)
                    
                    Spacer(minLength: 0)
                }
                .padding([.horizontal, .top])
                
                Divider()
                
                HStack(spacing: 15){
                    
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    TextField("Search", text: $HomeModel.search)
                    
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Divider()
                
                // Spacer() di ganti sama scrollView
                if HomeModel.items.isEmpty{
                    Spacer()
                    ProgressView()//loading
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false, content: {
                        VStack(spacing: 25){
                            ForEach(HomeModel.filtered){ item in
                                
                                ZStack(alignment: Alignment(horizontal: .center, vertical: .top), content: {
                                    
                                    ItemView(item: item)
                                    
                                    HStack{
                                        Text("FREE DELIVERY")
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal)
                                            .background(Color.pink)
                                        
                                        Spacer(minLength: 0)
                                        
                                        Button(action: {
                                            HomeModel.addToCart(item: item)
                                        }, label: {
                                            Image(systemName: item.isAdded ? "checkmark" : "plus")
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(item.isAdded ? Color.green : Color.pink)
                                                .clipShape(Circle())
                                        })
                                    }
                                    .padding(.trailing, 10)
                                    .padding(.top, 10)
                                    
                                })
                                .frame(width: UIScreen.main.bounds.width - 30)
                            }
                        }
                        .padding(.top, 10)
                    })
                }
            }
            
            HStack{
                Menu(homeData: HomeModel)
                    .offset(x: HomeModel.showMenu ? 0 : -UIScreen.main.bounds.width / 1.6)
                
                Spacer(minLength: 0)
            }
            .background(Color.black.opacity(HomeModel.showMenu ? 0.3 : 0)
                            .ignoresSafeArea()
                            .onTapGesture(perform: {
                                withAnimation(.easeIn){ HomeModel.showMenu.toggle()}
                            })
            )
            if HomeModel.noLocation{
                Text("Please enable location access in settings to further move on!")
                    .foregroundColor(.black)
                    .frame(width: UIScreen.main.bounds.width - 100, height: 120)
                    .background(Color.white)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3).ignoresSafeArea())
            }
        }
        .onAppear(perform: {
            HomeModel.locationManager.delegate = HomeModel
        })
        .onChange(of: HomeModel.search, perform: { value in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                
                if value == HomeModel.search && HomeModel.search != ""{
                    // search data
                    HomeModel.filterData()
                }
            }
            
            if HomeModel.search == "" {
                // reset all data
                withAnimation(.linear){ HomeModel.filtered = HomeModel.items }
            }
        })
    }
}

