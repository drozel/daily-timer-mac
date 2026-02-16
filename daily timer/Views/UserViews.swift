import SwiftUI
import UniformTypeIdentifiers

struct UserListView: View {
    @ObservedObject var userManager: UserManager
    @State private var draggedUserID: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Teammates")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: addUser) {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
            }
            
            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach($userManager.users) { $user in
                        UserRowView(user: $user, userManager: userManager)
                            .onDrag {
                                draggedUserID = user.id
                                return NSItemProvider(object: user.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: UserRowDropDelegate(
                                    targetUser: user,
                                    userManager: userManager,
                                    draggedUserID: $draggedUserID
                                )
                            )
                    }
                }
                .padding(.horizontal, 2)
            }
            .onDrop(
                of: [UTType.text],
                delegate: UserListDropDelegate(userManager: userManager, draggedUserID: $draggedUserID)
            )
            .accessibilityIdentifier("usersScrollView")
        }
    }
    
    private func addUser() {
        let newIndex = userManager.users.count + 1
        let newUser = User(name: "User \(newIndex)", isSelected: true, isFinalizer: false)
        userManager.users.append(newUser)
        userManager.saveUsers()
    }
}

struct UserRowView: View {
    @Binding var user: User
    let userManager: UserManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRenameSheetPresented = false
    @State private var draftName = ""
    
    private var rowFillColor: Color {
        if user.isSelected {
            return colorScheme == .dark ? .blue.opacity(0.22) : .blue.opacity(0.08)
        }
        return colorScheme == .dark ? .white.opacity(0.10) : .gray.opacity(0.10)
    }
    
    private var rowStrokeColor: Color {
        colorScheme == .dark ? .white.opacity(0.16) : .black.opacity(0.06)
    }
    
    private var unselectedIconColor: Color {
        colorScheme == .dark ? .white.opacity(0.75) : .secondary
    }
    
    var body: some View {
        AnimatedButton(action: {
            user.isSelected.toggle()
            userManager.saveUsers()
        }) {
            HStack(spacing: 10) {
                Image(systemName: user.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(user.isSelected ? .blue : unselectedIconColor)
                
                Text(user.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()

                if user.isFinalizer {
                    Text("FINALIZER")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.orange.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(rowFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(rowStrokeColor, lineWidth: 1)
                    )
            )
        }
        .contextMenu {
            Button("Rename") {
                draftName = user.name
                isRenameSheetPresented = true
            }
            Button("Move Up") {
                moveUser(by: -1)
            }
            .disabled(userIndex <= 0)
            Button("Move Down") {
                moveUser(by: 1)
            }
            .disabled(userIndex < 0 || userIndex >= userManager.users.count - 1)
            Divider()
            Button(user.isFinalizer ? "Unset Finalizer" : "Set as Finalizer") {
                user.isFinalizer.toggle()
                userManager.saveUsers()
            }
            Divider()
            Button("Delete User", role: .destructive) {
                if let index = userManager.users.firstIndex(where: { $0.id == user.id }) {
                    userManager.users.remove(at: index)
                    userManager.saveUsers()
                }
            }
        }
        .sheet(isPresented: $isRenameSheetPresented) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Rename User")
                    .font(.headline)
                TextField("Name", text: $draftName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Spacer()
                    Button("Cancel") {
                        isRenameSheetPresented = false
                    }
                    Button("Save") {
                        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            user.name = trimmed
                            userManager.saveUsers()
                        }
                        isRenameSheetPresented = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(18)
            .frame(width: 320)
        }
        .accessibilityIdentifier("userRow-\(user.name)")
    }
    
    private var userIndex: Int {
        userManager.users.firstIndex(where: { $0.id == user.id }) ?? -1
    }
    
    private func moveUser(by offset: Int) {
        let from = userIndex
        let to = from + offset
        guard from >= 0, to >= 0, to < userManager.users.count else { return }
        let movingUser = userManager.users.remove(at: from)
        userManager.users.insert(movingUser, at: to)
        userManager.saveUsers()
    }
}

private struct UserRowDropDelegate: DropDelegate {
    let targetUser: User
    let userManager: UserManager
    @Binding var draggedUserID: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggedUserID = nil
        userManager.saveUsers()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedUserID,
              draggedUserID != targetUser.id,
              let fromIndex = userManager.users.firstIndex(where: { $0.id == draggedUserID }),
              let toIndex = userManager.users.firstIndex(where: { $0.id == targetUser.id })
        else { return }

        withAnimation(.easeInOut(duration: 0.15)) {
            let movedUser = userManager.users.remove(at: fromIndex)
            userManager.users.insert(movedUser, at: toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct UserListDropDelegate: DropDelegate {
    let userManager: UserManager
    @Binding var draggedUserID: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggedUserID = nil
        userManager.saveUsers()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
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
