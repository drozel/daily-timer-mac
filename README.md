# Daily Timer for macOS


![](screenshots/flow.gif)

A simple macOS timer app built in Swift using SwiftUI.
Designed to run daily standups efficiently by timing each team member.

> ⚠️ This was my first Swift project — developed quickly to improve my daily life as engineering manager. I’m not a professional Swift or UI developer, so some parts may be hacky or non-idiomatic. Pull requests and suggestions are welcome!

---

## ✨ Features

- ✅ Editor mode: allows to define the team members, the list is persisted between sessions
- ✅ Idle mode: choose who is present today, configure the counter value and start the daily as soon as the team is ready
- ✅ Run mode: picks the next random member from the list and counts down his time. Click NEXT to choose the next team member
- ✅ Finalizer members: members who always reports at the end. Helpful for team leads or product owners

---

## 🧠 Usage

1. Launch the app.
2. Select users for today’s session.
3. Set timeout (default: 90 seconds).
4. Press **START** to begin.
5. Each person is selected randomly (finalizers appear at the end).
6. A countdown shows the remaining time; turns end manually by pressing **Next**.

---

## 🛠 Development Notes

- Currently built for the local run only

---

## 🔧 Requirements

- macOS 12+
- Xcode 14+

---

## 🚀 Getting Started

1. Clone this repo.
2. Open in Xcode.
3. Press ▶️ Run.
4. Build your own `.app` via Product → Archive if needed.

---

## 🙏 Credits

Thanks to ChatGPT for helping me fill in Swift gaps quickly.

---

## 📬 Feedback

Feel free to open issues or PRs — especially Swift improvements!
