# TravelTips 1.x 功能完善计划

> 版本约定：`v1.0` tag = 当前代码状态。1.x = 在 1.0 基础上完善功能，不以上线为目标。
> MVP2（智能导入）见 [MVP2-smart-import.md](MVP2-smart-import.md)。
> README 里历史上的 MVP1 / MVP2 / MVP3 指的是 1.0 内部的三个里程碑，与这里的 MVP2 不是一回事。

## 排序原则

1. 按实现难度从低到高，先做能一小时内完成的，建立节奏。
2. 所有要改 SwiftData 模型的事项集中在 C 组一次做完，只写一次迁移。
3. 上线专属事项（图标、隐私清单、商店素材）单独放 F 组，什么时候想上线什么时候做。
4. MVP2 依赖 C 组：导入功能要写日期和时间，必须先把日期模型修对。

## A 组：一小时内的小修

> 逐条执行说明（含代码片段和验收）见 [TODO-A.md](TODO-A.md)。

| ID | 事项 | 工作量 | 涉及文件 | 验收 |
|----|------|--------|----------|------|
| A1 | 删除行程二次确认 | 20 min | `Views/TripsListView.swift` | 滑动删除弹 confirmationDialog，确认后才级联删除 |
| A2 | About 页版本号从 Bundle 读取，产品名统一 | 20 min | `Views/SettingsView.swift` | 显示 `CFBundleShortVersionString` + build；先决定叫 TravelTips 还是 TripCard |
| A3 | 加 `NSCameraUsageDescription` | 10 min | `project.pbxproj` 的 `INFOPLIST_KEY_NSCameraUsageDescription` | 附件里点拍照不再闪退 |
| A4 | Todo 页行程提醒对已结束行程显示错误 | 15 min | `Views/RemindersView.swift` | 已结束的行程不再显示 "is now!"，改为隐藏或 "ended" |
| A5 | 只支持 iPhone 竖屏 | 10 min | `project.pbxproj`：`TARGETED_DEVICE_FAMILY = 1`，方向只留 Portrait | 横屏和 iPad 不再出现错位的自定义 TabBar |
| A6 | 行程列表空状态 | 30 min | `Views/TripsListView.swift` | 没有行程时显示引导文案和一个"创建行程"按钮 |

## B 组：半天级别，不改数据模型

| ID | 事项 | 工作量 | 说明 |
|----|------|--------|------|
| B1 | 附件级联清理 | 2–3 h | 新增 `AttachmentStore.deleteAll(linkedTo: [UUID])`，删除 Transport / Hotel / Place / Info / Trip 时调用，同时删 `Documents/attachments/` 里的文件。删 Trip 时要先收集所有子对象的 id |
| B2 | 错误提示 | 2 h | 附件保存失败、文件不存在、相机不可用时弹 alert，替换现在的 `try?` 静默失败 |
| B3 | 行程基本信息编辑 | 半天 | 名称、emoji、颜色（`Trip.colorHex` 已存在但 UI 没用到）。在行程总览页加编辑入口 |
| B4 | 行程日期编辑 | 半天–1 天 | 延长：按日追加 `TripDay`；缩短：被删掉的天如果有数据，先弹确认再级联删除 |
| B5 | 种子数据只在 Debug 下生效 | 1 h | `seedIfNeeded` / `seedPackingIfNeeded` 包在 `#if DEBUG`，Release 走 A6 的空状态。打包清单的个人条目一并清掉 |
| B6 | 时间输入改用时间选择器 | 2 h | Transport / Place / Timeline 的时间字段仍存 `String`，但 UI 用 `DatePicker(.hourAndMinute)` 写入统一的 `"HH:mm"`；加一个容错解析函数 `parseHHmm(_:) -> Int?` 供排序用。不改 schema |
| B7 | Daily 时间轴按时间自动排序 | 2 h | 依赖 B6。有合法时间的按时间排，没有的按 `sortOrder` 排在后面 |

## C 组：数据模型升级（集中一次做，一次迁移）

做之前先读 Apple 的 `VersionedSchema` / `SchemaMigrationPlan` 文档。顺序不能乱：C0 必须第一个。

| ID | 事项 | 工作量 | 说明 |
|----|------|--------|------|
| C0 | Schema 版本化 | 半天 | 把当前模型冻结为 `SchemaV1`，建 `MigrationPlan`，`ModelContainer` 改用 `migrationPlan:`。去掉 `TravelTipsApp.swift` 里"打不开就挪走 store"的兜底 |
| C1 | 日期跨时区修复 | 1 天 | `TripDay.date`、`Trip.startDate/endDate` 改为存日历日（推荐 `"yyyy-MM-dd"` 字符串 + 计算属性，或 `DateComponents`）。所有 `Calendar.current` 比较改走一个固定 UTC 日历的 helper。验收：把模拟器时区从 Asia/Shanghai 改到 America/New_York，行程日期不变 |
| C2 | 为 CloudKit 预留结构 | 半天 | 去掉 `@Attribute(.unique)`，所有属性给默认值，关系全部可选。即使 1.x 不开同步也先改，以后开只需加 `cloudKitDatabase` |
| C3 | 迁移测试 | 半天 | 用 1.0 的 store 文件做 fixture，跑 V1 → V2 迁移，验证数据完整 |

## D 组：新功能

| ID | 事项 | 工作量 | 依赖 | 说明 |
|----|------|--------|------|------|
| D1 | 本地通知真正生效 | 1 天 | B6, C1 | 行程开始前一天 20:00、行程期间每天 08:00 推"今日行程摘要"。设置页开关控制调度与取消。用 `UNCalendarNotificationTrigger` |
| D2 | 中英文本地化 | 2 天 | 无 | 用 String Catalog（`Localizable.xcstrings`）。语言开关通过 `.environment(\.locale)` 生效，不需要重启 |
| D3 | 总览页定位到"今天" | 2 h | C1 | 行程进行中时，总览自动滚到今天并高亮 |
| D4 | 行程卡片使用 `colorHex` | 2 h | B3 | 每个行程有自己的主色 |
| D5 | 分享行程 | 1 天 | 无 | 生成纯文本或简单 PDF，通过 ShareLink 分享。给同行的人看很实用 |
| D6 | 打包清单按行程复制 | 半天 | 无 | 当前 Packing 是全局的，加"从上次行程复制"或"重置已打包状态" |

## E 组：质量

| ID | 事项 | 工作量 | 说明 |
|----|------|--------|------|
| E1 | 核心逻辑单元测试 | 1–2 天 | 优先覆盖：linkedId 级联删除、酒店按晚生成 + 入住/退房 TimelineItem、交通换日、C1 的日期 helper。用内存 `ModelContainer` |
| E2 | Dynamic Type | 1–2 天 | 166 处 `.system(size:)` 换成语义字体或 `@ScaledMetric` |
| E3 | 无障碍标签 | 半天 | emoji 按钮和图标按钮加 `accessibilityLabel` |

## F 组：上线专属（想上线时再做）

| ID | 事项 | 工作量 |
|----|------|--------|
| F1 | App 图标 1024×1024 | 1 h |
| F2 | `PrivacyInfo.xcprivacy`：声明 UserDefaults（CA92.1） | 20 min |
| F3 | `ITSAppUsesNonExemptEncryption = NO` | 5 min |
| F4 | 部署目标降到 17.0（确认没用 18 专属 API） | 10 min |
| F5 | 隐私政策页面、商店截图、描述 | 1 天 |
| F6 | TestFlight 内测 | 持续 |

## 建议执行顺序

```
A1 → A2 → A3 → A4 → A5 → A6        （一个下午）
B1 → B2 → B5 → B6 → B7 → B3 → B4   （两到三天）
C0 → C1 → C2 → C3                   （两到三天，一个 PR）
D3 → D1 → D4 → D2 → D5 → D6         （一周）
E1 → E3 → E2                        （穿插做）
---- 此时可以开始 MVP2 Phase 0 ----
F 组                                （决定上线时）
```

## 不在 1.x 范围内

- iCloud 同步正式开启（C2 做好后随时可开，但要处理冲突和多设备测试）
- 行程模板、协作编辑
- 地图视图
