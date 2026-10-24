# TravelTips 1.x 功能完善计划

> 版本约定：`v1.0` tag = 当前代码状态。1.x = 在 1.0 基础上完善功能，不以上线为目标。
> MVP2（智能导入）见 [MVP2-smart-import.md](MVP2-smart-import.md)。
> README 里历史上的 MVP1 / MVP2 / MVP3 指的是 1.0 内部的三个里程碑，与这里的 MVP2 不是一回事。

## 排序原则

1. 按实现难度从低到高，先做能一小时内完成的，建立节奏。
2. 所有要改 SwiftData 模型的事项集中在 C 组一次做完，只写一次迁移。
3. 上线专属事项（图标、隐私清单、商店素材）单独放 F 组，什么时候想上线什么时候做。
4. MVP2 依赖 C 组：导入功能要写日期和时间，必须先把日期模型修对。

## ⏭ 下次从这里开始（2026-10-24 收尾时记录）

| ID | 事项 | 工作量 | 说明 |
|----|------|--------|------|
| G1 | 分享 PDF 时显示进度 | 2 h | **现象**：点分享后，生成 PDF 要等一两秒，期间界面没有任何反应，像卡住了。**原因**：PDF 是选好分享去处之后才在主线程生成的（`TripPDFFile` 的 `FileRepresentation`）。**做法**：分享按钮改成普通按钮，点击后先盖一层“正在生成 PDF… 3/6 页”的进度条（按页渲染，每页之间让出主线程刷新进度），生成完再弹系统分享面板，传入现成的 PDF 文件；生成期间可取消。顺便让分享面板的缩略图显示第一页 |
| G2 | 打包清单按行程复制（D6 剩余部分）| 1 天 | **要改数据模型**：打包物品现在是全局共用的，要给 `PackingItem` 加所属行程（或做“清单模板 → 行程清单”两层），新建 `SchemaV3` 加迁移，旧的全局清单迁移为模板。按 C 组规则：先备份手机数据、模拟器里用真实数据跑迁移，核对后再装手机 |
| G3 | iCloud 同步预留（C2 剩余部分）| 半天 | **要改数据模型**：所有关系改为可选并补反向关系（约 126 处调用）。只有决定开 iCloud 同步时才做，可以和 G2 合进同一次 `SchemaV3` 迁移 |

G2 和 G3 都要改数据模型，如果都做，合成一次迁移，只装一次手机。

## A 组：一小时内的小修

> 逐条执行说明（含代码片段和验收）见 [TODO-A.md](TODO-A.md)。

| ID | 事项 | 工作量 | 涉及文件 | 验收 |
|----|------|--------|----------|------|
| A1 | ✅ 删除行程二次确认 | 20 min | `Views/TripsListView.swift` | 滑动删除弹 confirmationDialog，确认后才级联删除 |
| A2 | ✅ About 页版本号从 Bundle 读取，产品名统一 | 20 min | `Views/SettingsView.swift` | 显示 `CFBundleShortVersionString` + build；先决定叫 TravelTips 还是 TripCard |
| A3 | ✅ 加 `NSCameraUsageDescription` | 10 min | `project.pbxproj` 的 `INFOPLIST_KEY_NSCameraUsageDescription` | 附件里点拍照不再闪退 |
| A4 | ✅ Todo 页行程提醒对已结束行程显示错误 | 15 min | `Views/RemindersView.swift` | 已结束的行程不再显示 "is now!"，改为隐藏或 "ended" |
| A5 | ✅ 只支持 iPhone 竖屏 | 10 min | `project.pbxproj`：`TARGETED_DEVICE_FAMILY = 1`，方向只留 Portrait | 横屏和 iPad 不再出现错位的自定义 TabBar |
| A6 | ✅ 行程列表空状态 | 30 min | `Views/TripsListView.swift` | 没有行程时显示引导文案和一个"创建行程"按钮 |

## B 组：半天级别，不改数据模型

| ID | 事项 | 工作量 | 说明 |
|----|------|--------|------|
| B1 | ✅ 附件级联清理 | 2–3 h | 新增 `AttachmentStore.deleteAll(linkedTo: [UUID])`，删除 Transport / Hotel / Place / Info / Trip 时调用，同时删 `Documents/attachments/` 里的文件。删 Trip 时要先收集所有子对象的 id |
| B2 | ✅ 错误提示 | 2 h | 附件保存失败、文件不存在、相机不可用时弹 alert，替换现在的 `try?` 静默失败 |
| B3 | ✅ 行程基本信息编辑 | 半天 | 名称、emoji、颜色（`Trip.colorHex` 已存在但 UI 没用到）。在行程总览页加编辑入口 |
| B4 | ✅ 行程日期编辑 | 半天–1 天 | 延长：按日追加 `TripDay`；缩短：被删掉的天如果有数据，先弹确认再级联删除 |
| B5 | ✅ 种子数据只在 Debug 下生效 | 1 h | `seedIfNeeded` / `seedPackingIfNeeded` 包在 `#if DEBUG`，Release 走 A6 的空状态。打包清单的个人条目一并清掉 |
| B6 | ✅ 时间输入改用时间选择器 | 2 h | Transport / Place / Timeline 的时间字段仍存 `String`，但 UI 用 `DatePicker(.hourAndMinute)` 写入统一的 `"HH:mm"`；加一个容错解析函数 `parseHHmm(_:) -> Int?` 供排序用。不改 schema |
| B7 | ✅ Daily 时间轴按时间自动排序 | 2 h | 依赖 B6。有合法时间的按时间排，没有的按 `sortOrder` 排在后面 |

## C 组：数据模型升级（集中一次做，一次迁移）

> 已完成（commit e339381）。手机上的真实数据已备份在 `~/Documents/TravelTips-Backups/`，迁移已用这份数据在单元测试和模拟器真实启动两种方式下验证，数量逐项一致。

| ID | 事项 | 状态与说明 |
|----|------|------------|
| C0 | ✅ Schema 版本化 | `SchemaV1`（冻结，勿改）+ `SchemaV2` + `TravelTipsMigrationPlan`。**调整**：保留"打不开就挪走"的兜底，但改为先自动复制一份 `StoreBackups/pre-v2`，失败时挪到 `failed-<时间>` 并弹出恢复提示，绝不删除 |
| C1 | ✅ 日期跨时区修复 | 存 `startKey` / `endKey` / `dayKey`（`"yyyy-MM-dd"`），`startDate` / `endDate` / `date` 改为按当前时区计算。迁移按**迁移那一刻设备的时区**把旧时间点换算成日历日，所以首次在手机上安装 V2 时，手机时区应为规划行程时的时区（中国） |
| C2 | ✅ 部分完成：CloudKit 预留 | 已去掉 `@Attribute(.unique)`、所有属性有默认值。**未做**：关系改可选 + 反向关系（约 126 处调用，且有"可选数组 append 静默失效"风险）。开 iCloud 时再做，届时是一次不改数据内容的轻量迁移 |
| C3 | ✅ 迁移测试 | 合成 V1 库迁移测试常驻；真实库测试需传 `TEST_RUNNER_TRAVELTIPS_STORE_FIXTURE=<含 default.store 的目录>`，不传则跳过 |

**以后每次改模型的规则**：新建 `SchemaV3`，把 V2 原样冻结，加迁移 stage，用最新的手机备份跑真实库测试，通过后才装手机。

## D 组：新功能

> 已完成（2026-10-24）。界面效果用 `TravelTipsUITests/ScreenshotTour` 在模拟器里截图验证，中英文各跑一遍。

| ID | 事项 | 状态与说明 |
|----|------|------------|
| D1 | ✅ 本地通知 | 行程前一天 20:00、行程中每天 08:00（当地时间）推送当天安排。只排最近 60 条（iOS 上限 64）。打开或切出 App 时重排，重排排队执行防止竞争。开关默认关闭，打开时才申请权限 |
| D2 | ✅ 简体中文 | **调整**：不在 App 内切换语言，改用 iOS 的“按 App 设置语言”（设置 → TravelTips → 语言），文字、日期格式、通知全部跟随。设置页的语言行显示当前语言并跳转到系统设置。新文字的翻译用 `tools/i18n/add_translations.py` 合并进 `Localizable.xcstrings` |
| D3 | ✅ 总览定位到今天 | 行程进行中时自动滚到今天，边框、徽章、TODAY 标签用行程色 |
| D4 | ✅ 行程主色 | 返回按钮、总览徽章、今天高亮、行程内 tab 栏选中色 |
| D5 | ✅ 分享行程 | 纯文本，按天列出日期、城市、概要、时间轴和地址。**不含 Info**（可能有护照号等）。PDF 版未做 |
| D6 | ✅ 部分完成：打包清单 | 做了“一键取消全部勾选”。“按行程复制清单”需要把打包物品挂到行程上，要改数据模型，留到以后 |
| D7 | ✅ 整体平移行程 | 天数不变、起始日期变化时，询问“整体平移”还是“只修改日期” |

## E 组：质量

| ID | 事项 | 工作量 | 说明 |
|----|------|--------|------|
| E1 | 核心逻辑单元测试 | 1–2 天 | 已有 28 个：附件清理、时间解析、时间轴排序、日期增减与酒店重锚。还需覆盖：linkedId 级联删除、酒店按晚生成 + 入住/退房 TimelineItem、交通换日、C1 的日期 helper。用内存 `ModelContainer` |
| E2 | Dynamic Type | 1–2 天 | 166 处 `.system(size:)` 换成语义字体或 `@ScaledMetric` |
| E3 | 无障碍标签 | 半天 | emoji 按钮和图标按钮加 `accessibilityLabel` |
| E4 | 行程列表小问题 | 1 h | 已结束的行程仍在 UPCOMING 标题下；倒计时显示成 “-215 days ago”（负号和 ago 重复）。建议分 Upcoming / Past 两段，Past 显示 “215 days ago” |
| E5 | Egypt 行程缺最后一天 | 10 min | 范围 3/12–3/23 共 12 天，但只有 11 个 TripDay（缺 3/23）。在编辑表单把结束日期改到 3/22 保存，再改回 3/23 保存即可补上；或在 History 功能里统一校验 |

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
D3 → D1 → D4 → D2 → D5 → D6 → D7         （✅ 已完成）
E1 → E3 → E2                        （穿插做）
---- 此时可以开始 MVP2 Phase 0 ----
F 组                                （决定上线时）
```

## 不在 1.x 范围内

- iCloud 同步正式开启（C2 做好后随时可开，但要处理冲突和多设备测试）
- 行程模板、协作编辑
- 地图视图
