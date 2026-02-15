# AGENTS.md - LLM Agent Guide

This document provides essential information for LLM agents working on the Daily Timer macOS application.

## 📋 Project Overview

**Daily Timer** is a SwiftUI-based macOS application designed for managing daily standup meetings. It features a modern "liquid glass" transparent design (macOS 26 style) and provides timer functionality for team members.

### Key Characteristics
- **Platform**: macOS 12+
- **Framework**: SwiftUI
- **Design Language**: macOS 26 Liquid Glass (transparent, glassmorphic)
- **Architecture**: MVVM-like with SwiftUI state management
- **Persistence**: UserDefaults for user list storage

---

## 🏗️ Project Structure

```
daily timer/
├── daily_timerApp.swift          # App entry point
├── ContentView.swift              # Main coordinator view (handles app modes)
├── Models/
│   └── UserModel.swift           # User data model & UserManager
├── Views/
│   ├── MainView.swift            # Main screen (user selection, settings)
│   ├── TimerViews.swift          # Timer display & session end views
│   ├── UserViews.swift           # User list & editing views
│   ├── SettingsViews.swift       # Timer settings & session info
│   └── SharedStyles.swift        # Reusable glass UI components
└── Assets.xcassets/              # App icons & assets
```

---

## 🎨 Design System: Liquid Glass

The app uses a **macOS 26 Liquid Glass** design system with the following principles:

### Core Materials
- **`.ultraThinMaterial`**: Primary glass effect for containers
- **`.thinMaterial`**: Secondary glass effect for buttons
- **`.regularMaterial`**: Standard material (used sparingly)

### Glass Component Pattern
All glass components follow this structure:
1. **Base Material**: `.ultraThinMaterial` or `.thinMaterial`
2. **Inner Glow**: Gradient overlay for depth
3. **Gradient Border**: Multi-color stroke with opacity
4. **Multi-layered Shadows**: Depth through shadow stacking
5. **Adaptive Styling**: Responds to light/dark mode

### Example Glass Component
```swift
RoundedRectangle(cornerRadius: 20, style: .continuous)
    .fill(.ultraThinMaterial)
    .overlay(/* inner glow gradient */)
    .overlay(/* gradient border */)
    .shadow(/* primary shadow */)
    .shadow(/* secondary shadow */)
```

### Key Glass Components
- `GlassContainer`: Main container for timer views
- `GlassCard`: Card container with glass effect
- `GlassButton`: Interactive button with glass styling
- `GlassBackground`: Background material for main views

---

## 🔄 Application Modes

The app operates in three distinct modes managed by `ContentView`:

### 1. Main Mode (`.main`)
- **Purpose**: User selection and session configuration
- **Window**: Normal window, resizable, with title bar
- **Features**: 
  - User list with selection checkboxes
  - Timer duration settings
  - Session info display
  - Start/Edit buttons

### 2. Timer Mode (`.timer`)
- **Purpose**: Active timer display during standup
- **Window**: Floating, borderless, transparent background
- **Features**:
  - Current user name display
  - Countdown timer with visual feedback
  - Color-coded status (green → red as time decreases)
  - Next button to advance to next user
- **Window Configuration**:
  - `level = .floating`
  - `backgroundColor = .clear`
  - `isOpaque = false`
  - `styleMask = [.borderless, .fullSizeContentView]`
  - Fixed size: 240x300

### 3. Edit Users Mode (`.editUsers`)
- **Purpose**: Manage team member list
- **Window**: Normal window (same as main mode)
- **Features**:
  - Add/remove users
  - Edit user names
  - Toggle finalizer status
  - Reorder users

---

## 📊 State Management

### App-Level State (`ContentView`)
- `@StateObject var userManager`: Manages user list persistence
- `@State private var mode`: Current app mode
- `@State private var currentUser`: Active user in timer
- `@State private var sessionUsers`: Working copy for current session
- `@State private var timeRemaining`: Countdown value
- `@State private var isTimerRunning`: Timer state
- `@AppStorage`: Persists timer duration and window size

### User Management (`UserManager`)
- `@Published var users: [User]`: Observable user list
- Persists to `UserDefaults` with key `"userList"`
- Methods: `loadUsers()`, `saveUsers()`

### User Model
```swift
struct User: Identifiable, Codable {
    var id: UUID
    var name: String
    var isSelected: Bool      // Selected for current session
    var isFinalizer: Bool     // Always appears at end
}
```

---

## 🎯 Key Components

### ContentView
**Role**: Main coordinator and window manager
- Manages app mode transitions
- Configures window properties per mode
- Handles timer lifecycle
- Manages session flow (start → timer → end)

**Key Methods**:
- `configureWindowForMode(_:)`: Sets window properties
- `startSession()`: Initializes timer session
- `nextUser()`: Advances to next team member
- `finishSession()`: Returns to main mode

### TimerViews.swift
**Components**:
- `GlassContainer`: Liquid glass wrapper for timer content
- `TimerContent`: Timer display (user name, countdown, next button)
- `SessionEndContent`: Completion screen
- `TimerView`: Public view combining container + content
- `SessionEndView`: Public view for session completion

**Timer Visual States**:
- **Green Zone** (>20% time): Green/mint colors
- **Red Zone** (≤20% time): Red/pink colors with urgency
- **Time's Up** (0 seconds): Fire emoji with pulsing animation

### SharedStyles.swift
**Reusable Components**:
- `GlassCard<Content>`: Glass card container
- `GlassButton<Content>`: Glass-styled button with press animation
- `GlassBackground`: Background material for main views
- `UltraGlassCard<Content>`: Enhanced glass card with sunglass effect
- `FirstMouseAcceptingView`: NSView wrapper for first-click handling

### UserViews.swift
**Components**:
- `UserListView`: Displays selectable user list
- `UserRowView`: Individual user row with checkbox
- `EditUserView`: User management interface
- `UserEditRow`: Editable user row with actions

---

## 🎨 Design Patterns

### 1. View Composition
Views are composed of smaller, reusable components:
```swift
TimerView {
    GlassContainer {
        TimerContent(...)
    }
}
```

### 2. Material-Based Styling
Uses SwiftUI materials for glass effects rather than custom blur:
- Materials adapt to system appearance
- Automatically handle transparency
- Respect accessibility settings

### 3. Adaptive Color Schemes
All glass components check `@Environment(\.colorScheme)`:
- Light mode: Higher opacity, darker tints
- Dark mode: Lower opacity, lighter tints

### 4. Window Configuration Pattern
Window properties are set per mode in `configureWindowForMode(_:)`:
- Main/Edit: Normal window with title bar
- Timer: Floating, transparent, borderless

---

## 🔧 Common Tasks

### Adding a New View
1. Create view in appropriate `Views/` file
2. Use `GlassCard` or `GlassContainer` for glass effect
3. Follow existing glass styling patterns
4. Add to mode switch in `ContentView` if needed

### Modifying Timer Display
- Edit `TimerContent` in `TimerViews.swift`
- Timer circle styling is in the `ZStack` with conditional rendering
- Color zones: Modify `isRedZone` threshold or colors

### Changing Glass Effect
- Modify `GlassContainer` in `TimerViews.swift`
- Adjust material type, opacity, gradients, or shadows
- Ensure adaptive styling for light/dark mode

### Adding New User Properties
1. Update `User` struct in `UserModel.swift`
2. Ensure `Codable` conformance
3. Update `UserDefaults` persistence if needed
4. Modify UI components that display/edit users

### Window Configuration Changes
- Edit `configureWindowForMode(_:)` in `ContentView.swift`
- Window properties are set via `NSApp.keyWindow`
- Timer mode requires special transparency setup

---

## ⚠️ Important Conventions

### 1. Timer Session Flow
- `startSession()` creates a **working copy** (`sessionUsers`)
- Original user list is **never modified** during session
- Session ends when all users are processed or manually finished

### 2. User Selection
- `isSelected` determines who participates in session
- Selection state persists between app launches
- Finalizers always appear at end, regardless of order

### 3. Window Size Persistence
- Main window size is saved to `@AppStorage`
- Timer window is always fixed size (240x300)
- Size is restored when returning to main mode

### 4. Drag Handling
- Timer view is draggable via `DragGesture`
- Window origin is updated directly via `NSApp.keyWindow`
- `isMovableByWindowBackground = false` to prevent conflicts

### 5. Material Usage
- **Never** use solid colors for backgrounds in timer mode
- Always use materials (`.ultraThinMaterial`, `.thinMaterial`)
- Materials provide automatic vibrancy and transparency

---

## 🐛 Common Issues & Solutions

### Timer Not Transparent
- Check `window.backgroundColor = .clear`
- Verify `window.isOpaque = false`
- Ensure `contentView.layer?.backgroundColor = NSColor.clear.cgColor`

### Glass Effect Not Visible
- Verify material is applied (`.ultraThinMaterial`)
- Check that window background is transparent
- Ensure proper shadow layering for depth

### Window Not Draggable
- Verify `DragGesture` is attached to timer view
- Check `window.isMovableByWindowBackground = false`
- Ensure gesture coordinate space is `.global`

### User List Not Persisting
- Check `UserManager.saveUsers()` is called after changes
- Verify `User` struct conforms to `Codable`
- Check `UserDefaults` key is `"userList"`

---

## 🚀 Best Practices

1. **Always use glass components** for timer mode views
2. **Preserve session state** - don't modify original user list during session
3. **Adaptive styling** - always check `colorScheme` for glass effects
4. **Window configuration** - update in `configureWindowForMode(_:)` only
5. **Material over solid colors** - use materials for transparency
6. **Multi-layered shadows** - use 2-3 shadow layers for depth
7. **Gradient borders** - use multi-color gradients for glass borders

---

## 📝 Code Style Notes

- Views are organized by functionality, not by type
- Glass components use `@ViewBuilder` for content
- State is managed at appropriate levels (local vs. app-level)
- Window configuration uses `DispatchQueue.main.async` for safety
- Timer uses `Timer.scheduledTimer` with 1-second intervals

---

## 🔍 Key Files Reference

| File | Purpose |
|------|---------|
| `ContentView.swift` | Main coordinator, window management, app flow |
| `TimerViews.swift` | Timer display components with glass styling |
| `SharedStyles.swift` | Reusable glass UI components |
| `UserModel.swift` | Data model and persistence |
| `MainView.swift` | Main screen layout |
| `UserViews.swift` | User list and editing interfaces |
| `SettingsViews.swift` | Timer settings and session info |

---

## 💡 Design Philosophy

This app prioritizes:
1. **Visual Clarity**: Transparent design that doesn't obstruct desktop
2. **Simplicity**: Minimal UI, focused on timer functionality
3. **Modern Aesthetics**: macOS 26 liquid glass design language
4. **User Experience**: Smooth transitions, clear visual feedback
5. **Persistence**: User preferences and list saved automatically

---

## 🎓 Learning Resources

For LLM agents working on this codebase:
- SwiftUI Materials: Use system materials for glass effects
- Window Management: `NSWindow` properties for transparency
- State Management: `@State`, `@StateObject`, `@AppStorage`
- View Composition: Build complex views from simple components
- Adaptive Design: Respond to system appearance changes

---

**Last Updated**: After macOS 26 liquid glass implementation
**Maintainer Notes**: This is a personal project, code may be non-idiomatic in places. Focus on functionality and user experience over perfect Swift patterns.

