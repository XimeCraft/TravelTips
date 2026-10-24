# A 组执行清单（交接给执行模型）

> ✅ 已于 2026-10-22 全部完成，本文仅作存档。当前进度看 [ROADMAP-1.x.md](ROADMAP-1.x.md)。

> 本文是 [ROADMAP-1.x.md](ROADMAP-1.x.md) A 组的逐条执行说明，写给接手的 AI 会话。按顺序做，每项一个 commit，做完一项再做下一项。

## 环境

- 仓库：`/Users/xiao/Projects/github/AppleApp/IOSApp/TravelTips`，分支 `develop`。所有 git 和构建命令都在这个目录执行。
- 这台 Mac 的 `xcode-select` 指向 Command Line Tools，`xcodebuild` 必须带 `DEVELOPER_DIR`：

```bash
cd /Users/xiao/Projects/github/AppleApp/IOSApp/TravelTips
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project TravelTips.xcodeproj -scheme TravelTips -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build 2>&1 \
  | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

- 工程用的是 Xcode 同步文件夹，新建 `.swift` 文件放进 `TravelTips/` 下对应目录即可，不用改 pbxproj。
- SwiftUI 组件在 `TravelTips/Components/SharedComponents.swift`：`CardView { }`、`CardView(action:) { }`、`SectionHeader(title:)`、`AddButton { }`、`SheetField`、`SheetSaveButton`。颜色在 `Theme.swift`：`Theme.primary`、`Theme.bg`、`Theme.textPrimary`、`Theme.textSec`、`Theme.textTer`。
- `List` 里每一行都要带这三个修饰符，否则样式会错：`.listRowInsets(EdgeInsets())`、`.listRowBackground(Theme.bg)`、`.listRowSeparator(.hidden)`。

## 规则

1. 每项做完先跑上面的构建命令，看到 `BUILD SUCCEEDED` 才 commit。
2. 每项一个 commit，信息格式 `feat(A1): ...`，用英文。
3. 只改该项列出的文件。不要顺手重构、不要改格式、不要删 `SettingsView.swift` 里的 `#if DEBUG` 段。
4. 不要 push。
5. 遇到和本文描述不符的代码，停下来说明，不要猜。

---

## Step 0：先把现有未提交的改动收掉

当前工作区有 6 项未提交内容，是上一个会话留下的，代码部分已经过构建验证：

- `TravelTips/Views/OnDeviceAIStatusView.swift`（新文件）
- `TravelTips/Views/SettingsView.swift`（加了 `#if DEBUG` 段）
- `docs/MVP2-smart-import.md`、`docs/ROADMAP-1.x.md`、`docs/TODO-A.md`（本文）
- `tools/eval/`（新目录）

执行：

```bash
git add -A
git commit -m "chore: on-device model debug check, MVP2 doc updates, phase-0 eval script"
```

然后确认 `git status` 干净。

---

## A1 · 删除行程前二次确认

**文件**：`TravelTips/Views/TripsListView.swift`

**现状**：`TripsListView` 里 `ForEach(trips)` 的 `.swipeActions` 直接调用 `modelContext.delete(trip)`，误触即级联删除整个行程。

**改法**：

1. 在 `TripsListView` 加两个状态：

```swift
@State private var tripToDelete: Trip? = nil
@State private var showDeleteConfirm = false
```

2. 把 swipe 按钮改成只记录，不删除：

```swift
Button(role: .destructive) {
    tripToDelete = trip
    showDeleteConfirm = true
} label: {
    Label("Delete", systemImage: "trash")
}
```

3. 在最外层 `ZStack` 上（`.sheet(isPresented: $showAddSheet)` 旁边）加确认框：

```swift
.confirmationDialog(
    "Delete this trip?",
    isPresented: $showDeleteConfirm,
    titleVisibility: .visible,
    presenting: tripToDelete
) { trip in
    Button("Delete \"\(trip.name)\"", role: .destructive) {
        modelContext.delete(trip)
        tripToDelete = nil
    }
    Button("Cancel", role: .cancel) { tripToDelete = nil }
} message: { trip in
    Text("All days, transport, hotels, places and info for \"\(trip.name)\" will be removed. This cannot be undone.")
}
```

**验收**：模拟器里左滑行程卡点 Delete，先弹底部确认，点 Cancel 行程还在，点 Delete 才消失。

**Commit**：`feat(A1): confirm before deleting a trip`

---

## A2 · About 页版本号从 Bundle 读取，产品名不写死

**文件**：`TravelTips/Views/SettingsView.swift`

**现状**：第 89 行附近 `Text("TripCard")`，第 92 行附近 `Text("Version 1.0.0")`，都是硬编码，而工程名和包名是 TravelTips。

**改法**：

1. 在 `SettingsView` 里加两个计算属性：

```swift
private var appName: String {
    (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? "TravelTips"
}

private var appVersion: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    return "Version \(version) (\(build))"
}
```

2. `Text("TripCard")` 改成 `Text(appName)`，`Text("Version 1.0.0")` 改成 `Text(appVersion)`。其余不动。

**验收**：About 卡片显示 "TravelTips" 和 "Version 1.0 (1)"（来自 pbxproj 的 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION`）。

**Commit**：`feat(A2): read app name and version from Bundle`

---

## A3 · 加相机权限描述

**文件**：`TravelTips.xcodeproj/project.pbxproj`

**现状**：工程用自动生成的 Info.plist，没有 `NSCameraUsageDescription`。附件里点拍照会被系统直接杀掉进程。

**改法**：pbxproj 里有两个属于 App target 的 build configuration 块，特征是块内有 `PRODUCT_BUNDLE_IDENTIFIER = XimeCraft.TravelTips;`（注意不是 `.TravelTipsTests` 或 `.TravelTipsUITests`）。当前大约在第 393 行的 `/* Debug */` 块和第 423 行的 `/* Release */` 块。在这两个块里，`INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;` 这一行之前各加一行：

```
				INFOPLIST_KEY_NSCameraUsageDescription = "TravelTips uses the camera to photograph tickets and documents for your trip attachments.";
```

缩进用 tab，和相邻行一致。两个块都要加。

**验收**：构建后检查生成的 Info.plist：

```bash
plutil -p "$(find ~/Library/Developer/Xcode/DerivedData -path '*Debug-iphonesimulator/TravelTips.app/Info.plist' | head -1)" | grep NSCamera
```

能看到这个 key。如果构建用了别的 `-derivedDataPath`，就到那个目录下找。

**Commit**：`feat(A3): add camera usage description`

---

## A4 · Todo 页不再对已结束行程显示 "is now!"

**文件**：`TravelTips/Views/RemindersView.swift`

**现状**：`tripReminders`（约第 112 行）只看 `daysLeft`：大于 0 显示 "starts in N days"，否则一律 "is now!"，所以已经结束的行程也显示 "is now!"。

**改法**：

1. 把 `tripReminders` 整个替换为：

```swift
private var tripReminders: [TripReminderItem] {
    trips.compactMap { trip in
        let toStart = trip.daysLeft
        let toEnd = daysUntil(trip.endDate)
        guard toEnd >= 0 else { return nil }          // ended trips are not reminders

        let title: String
        if toStart > 1 {
            title = "\(trip.name) starts in \(toStart) days"
        } else if toStart == 1 {
            title = "\(trip.name) starts tomorrow"
        } else {
            title = "\(trip.name) is now!"
        }
        return TripReminderItem(
            icon: trip.emoji,
            title: title,
            subtitle: "\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate))"
        )
    }
}
```

`daysUntil` 和 `fmtDate` 在 `Theme.swift`，已经是全局函数，直接用。

2. 在 `ForEach(tripReminders)` 之后、`SectionHeader(title: "My Tasks")` 之前，加空状态：

```swift
if tripReminders.isEmpty {
    Text("No upcoming trips")
        .font(.system(size: 13))
        .foregroundColor(Theme.textTer)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Theme.bg)
        .listRowSeparator(.hidden)
}
```

**验收**：种子的 Egypt 行程是 2026-03，已结束，Todo 页 Trip Reminders 下应显示 "No upcoming trips"。新建一个未来的行程后显示 "starts in N days"。

**Commit**：`feat(A4): hide ended trips from reminders, add empty state`

---

## A5 · 只支持 iPhone 竖屏

**文件**：`TravelTips.xcodeproj/project.pbxproj`

**现状**：App target 的 `TARGETED_DEVICE_FAMILY = "1,2"`（iPhone + iPad），iPhone 允许横屏。自定义 TabBar 和 `ignoresSafeArea(.bottom)` 在横屏和 iPad 上布局错位。

**改法**：只改 A3 里说的那两个 App target 块（有 `PRODUCT_BUNDLE_IDENTIFIER = XimeCraft.TravelTips;` 的），每块三处：

1. `TARGETED_DEVICE_FAMILY = "1,2";` 改为 `TARGETED_DEVICE_FAMILY = 1;`
2. `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "..."` 改为 `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;`
3. 删掉整行 `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "...";`

测试 target 的块不要动。

**验收**：构建通过；模拟器里 ⌘ + ← 旋转设备，App 保持竖屏。

**Commit**：`feat(A5): iPhone portrait only`

---

## A6 · 行程列表空状态

**文件**：`TravelTips/Views/TripsListView.swift`

**现状**：没有行程时列表只剩标题和 "Upcoming" 小标题，用户不知道该做什么。

**改法**：在 `SectionHeader(title: "Upcoming")` 那一行之后、`ForEach(trips)` 之前加：

```swift
if trips.isEmpty {
    CardView {
        VStack(spacing: 10) {
            Text("🧳")
                .font(.system(size: 40))
            Text("No trips yet")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text("Create your first trip to start planning.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSec)
                .multilineTextAlignment(.center)
            Button {
                showAddSheet = true
            } label: {
                Text("Create Trip")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Theme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Theme.bg)
    .listRowSeparator(.hidden)
}
```

**验收**：用 A1 的确认框把 Egypt 行程删掉，列表显示空状态卡片；点 "Create Trip" 弹出新建行程表单。（首次启动的种子数据只在没有任何行程时写入一次，删掉之后不会再回来。）

**Commit**：`feat(A6): empty state for trips list`

---

## 完成标准

- `git log --oneline -8` 能看到 Step 0 加 A1 到 A6 共 7 个新 commit，都在 `develop` 上。
- `git status` 干净。
- 最后再跑一次构建命令，`BUILD SUCCEEDED`。
- 没有 push。

做完后把 [ROADMAP-1.x.md](ROADMAP-1.x.md) A 组表格里对应行的"事项"列前面加 `✅`，一并提交，信息 `docs: mark A group done`。
