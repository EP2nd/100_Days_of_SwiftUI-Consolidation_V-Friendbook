//
//  ContentView.swift
//  Friendbook
//
//  Created by Edwin Przeźwiecki Jr. on 01/02/2023.
//

import SwiftUI

struct ContentView: View {
    
    /// Initial solution:
//    @StateObject var users = Users()
    
    /// Previous solution:
//    @State private var users = [User]()
    
    /// Core Data:
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var users: FetchedResults<CachedUser>
    
    var body: some View {
        NavigationView {
            List(users) { user in
                NavigationLink {
                    UserDetailsView(users: users, user: user)
                } label: {
                    HStack {
                        Text(user.wrappedName)
                        Spacer()
                        Text(user.isActive ? "Online" : "Offline")
                            .font(.system(size: 12))
                            .frame(maxWidth: 50, maxHeight: 30)
                            .background(user.isActive ? .green : .clear)
                            .clipShape(Capsule())
                    }
                }
            }
            .navigationTitle("Friendbook")
            .task {
                await fetchUsers()
            }
        }
    }
    
    func fetchUsers() async {
        
        guard users.isEmpty else { return }
        
        do {
            let url = URL(string: "https://www.hackingwithswift.com/samples/friendface.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            /* -> */ let users = try decoder.decode([User].self, from: data)
            
            await MainActor.run {
                updateCache(with: users)
            }
        } catch {
            print("Download error: \(error.localizedDescription)")
        }
    }
    
    func updateCache(with downloadedUsers: [User]) {
        
        for user in downloadedUsers {
            let cachedUser = CachedUser(context: moc)
            
            cachedUser.id = user.id
            cachedUser.isActive = user.isActive
            cachedUser.name = user.name
            cachedUser.age = Int16(user.age)
            cachedUser.company = user.company
            cachedUser.email = user.email
            cachedUser.address = user.address
            cachedUser.about = user.about
            cachedUser.registered = user.registered
            cachedUser.tags = user.tags.joined(separator: ",")
            
            for friend in user.friends {
                let cachedFriend = CachedFriend(context: moc)
                cachedFriend.id = friend.id
                cachedFriend.name = friend.name
                
                cachedUser.addToFriends(cachedFriend)
            }
        }
        
        try? moc.save()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
