import SwiftUI

struct UserListView: View {
    @ObservedObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Teammates")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($userManager.users) { $user in
                        UserRowView(user: $user, userManager: userManager)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct UserRowView: View {
    @Binding var user: User
    let userManager: UserManager
    
    var body: some View {
        AnimatedButton(action: {
            user.isSelected.toggle()
            userManager.saveUsers()
        }) {
            HStack(spacing: 12) {
                Image(systemName: user.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(user.isSelected ? .blue : .secondary)
                
                Text(user.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()

                if user.isFinalizer {
                    Text("FINALIZER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.orange.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(user.isSelected ? .blue.opacity(0.05) : .gray.opacity(0.1))
            )
        }
    }
}

struct EditUserView: View {
    @ObservedObject var userManager: UserManager
    @FocusState private var focusedField: UUID?

    var body: some View {
        VStack {
            HStack {
                Text("User Management")
                    .font(.title)
            }
            .padding()

            ScrollViewReader { proxy in
                List {
                    ForEach($userManager.users) { $user in
                        HStack {
                            TextField("Name", text: $user.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: user.id)
                            Toggle("Finalizer", isOn: $user.isFinalizer)

                            Spacer()

                            Button(action: {
                                if let index = userManager.users.firstIndex(where: { $0.id == user.id }) {
                                    deleteUser(at: IndexSet(integer: index))
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .id(user.id)
                    }
                    .onDelete(perform: deleteUser)
                    .onMove(perform: moveUser)
                }

                Button("Add User") {
                    addUser(scrollProxy: proxy)
                }
                .padding()
            }
            .padding()
        }
        .padding()
        .onChange(of: userManager.users) { _ in
            userManager.saveUsers()
        }
    }

    func addUser(scrollProxy: ScrollViewProxy) {
        let newUser = User(name: "New User", isSelected: true, isFinalizer: false)
        userManager.users.append(newUser)
        userManager.saveUsers()
        
        // Focus on the newly added user's text field and scroll to it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = newUser.id
            withAnimation(.easeInOut(duration: 0.5)) {
                scrollProxy.scrollTo(newUser.id, anchor: UnitPoint.bottom)
            }
        }
    }
 
    func deleteUser(at offsets: IndexSet) {
        userManager.users.remove(atOffsets: offsets)
        userManager.saveUsers()
    }

    func moveUser(from source: IndexSet, to destination: Int) {
        userManager.users.move(fromOffsets: source, toOffset: destination)
        userManager.saveUsers()
    }
}
