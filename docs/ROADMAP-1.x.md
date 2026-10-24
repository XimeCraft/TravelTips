# TravelTips 计划与进度

> 最后更新：2026-10-24 收工时。
> 这是总入口：现在做到哪、下次从哪开始、还有什么要决定，都看这一份。
> MVP2（PDF 智能导入）的细节在 [MVP2-smart-import.md](MVP2-smart-import.md)。
> README 里的 MVP1 / MVP2 / MVP3 是 1.0 内部的旧里程碑，和这里的 MVP2 不是一回事。

---

## 1. 现在到哪了

| 分组 | 内容 | 状态 |
|------|------|------|
| v1.0 | 冻结当时的代码，打 tag | ✅ 10-21 |
| A 组 | 一小时内的小修 | ✅ 10-22 |
| B 组 | 半天级功能，不改数据模型 | ✅ 10-24 |
| C 组 | 数据模型升级与迁移 | ✅ 10-24，手机已迁移并核对 |
| D 组 | 新功能 | ✅ 10-24，D6 只做了一半 |
| 额外 | 自定义行程颜色、PDF 分享 | ✅ 10-24 |
| **G 组** | **下次的待办（含两项需要改数据模型）** | ⏭ 未开始 |
| E 组 | 质量 | ⏭ 未开始 |
| F 组 | 上线专属 | 暂不做 |
| MVP2 | PDF 智能导入 | Phase 0 进行中 |

**当前状态**

- 分支 `develop`。到 `07c17fa` 为止的代码都已 push 到 GitHub，只有这份文档整理的提交还没 push。
- 单元测试 49 个用例全部通过，Debug 和 Release 都能编译。
- 手机上已经是 SchemaV2（日期存成日历日），数据核对无误。

---

## 2. 下次从这里开始

按顺序做。前三项来自 10-24 收工时的记录。

| 顺序 | ID | 事项 | 工作量 | 说明 |
|------|----|------|--------|------|
| 1 | G1 | 分享 PDF 时显示进度 | 2 h | **你提的**。现在点分享后要等一两秒，期间没有任何反应，像卡住了。原因是 PDF 在选好分享去处之后才在主线程生成。做法：先盖一层“正在生成 PDF… 3/6 页”的进度条，按页渲染并更新进度，可取消；生成完再弹分享面板，面板缩略图显示第一页 |
| 2 | E4 | 行程列表分“即将出发 / 已结束” | 1 h | 已结束的行程还排在“即将出发”下，而且显示成 “-215 天前”。分成两段，已结束的显示 “215 天前” |
| 3 | E5 | 补上 Egypt 缺的 3/23 | 10 min | 范围 12 天但只有 11 天。在编辑表单把结束日改成 3/22 保存，再改回 3/23 保存即可 |
| 4 | — | 决定是否要“导出时隐藏备注” | 30 min | PDF 会原样带出地点备注里的预订码、票码、订票人姓名。是否加一个开关，等你决定 |
| 5 | G2 | 打包清单按行程复制（D6 剩下的一半） | 1 天 | **要改数据模型**。打包物品现在所有行程共用，要加上“属于哪个行程”（或做“清单模板 → 行程清单”两层），新建 SchemaV3 迁移，旧清单转成模板 |
| 6 | G3 | iCloud 同步预留（C2 剩下的一半） | 半天 | **要改数据模型**。所有关系改成可选并补反向关系，约 126 处代码。只有决定开 iCloud 时才做，和 G2 合成一次迁移 |
| 7 | E1 | 补单元测试 | 1 天 | 还没覆盖：交通换日、酒店按晚生成和入住退房条目、linkedId 级联删除 |
| 8 | E3 | 无障碍标签 | 半天 | 图标按钮加 `accessibilityLabel`，部分已在 D 组补上 |
| 9 | E2 | 动态字体 | 1–2 天 | 约 166 处固定字号换成可缩放的写法 |
| 10 | MVP2 | Phase 0 继续 | 1 周 | 见第 4 节 |

**改数据模型的规则（G2、G3 必须遵守）**

1. 先从手机备份数据（方法见第 6 节）。
2. 新建 `SchemaV3`，把 V2 原样冻结，加迁移步骤。
3. 用最新的手机备份跑真实库迁移测试，核对每张表数量。
4. 在模拟器里用备份数据真实启动一次，确认正常。
5. 最后才装到手机，装完再拷回来核对一次。

---

## 3. 等你决定的事

| 事项 | 影响 | 现状 |
|------|------|------|
| PDF 导出要不要隐藏备注 | 分享给别人时会不会带出票码、预订号 | 目前全部导出 |
| 要不要做 iCloud 同步 | 决定 G3 做不做 | 未决定 |
| 设置页的调试卡片 | 只在 Xcode 装的版本出现，正式版没有 | 保留，可以改成折叠或隐藏 |
| 产品名 TravelTips 还是 TripCard | 关于页、分享扩展的显示名 | 关于页现在读包名，显示 TravelTips |
| MVP2：导入功能最低 iOS 版本 | 26 才有苹果端侧模型，17 要自带模型 | 未决定 |
| MVP2：是否接受 1–3 GB 模型下载 | 决定用 Qwen3-4B 还是 1.7B | 未决定 |
| ~~MVP2：目标用户是否以中国大陆为主~~ | ~~决定模型路线~~ | 已定：国行机用不了苹果端侧模型，默认走 Qwen3 via MLX |

---

## 4. MVP2 · PDF 智能导入

详细设计在 [MVP2-smart-import.md](MVP2-smart-import.md)。

| Phase | 内容 | 状态 |
|-------|------|------|
| 0 | 研究：语料、评测、选模型 | 进行中 |
| 1 | 抽取原型 | 未开始，前置条件 C 组已满足 |
| 2 | 映射引擎（PDF 内容 → 行程数据） | 未开始 |
| 3 | 导入界面、确认页、分享扩展 | 未开始 |
| 4 | 扩展：自带 API key、截图导入 | 按需 |
| 5 | 研究：行程知识库 / 问答 | 以后 |

**Phase 0 已完成**

- ✅ 查清苹果端侧模型在中国大陆的情况：国行机目前不能用，预计 12 月 iOS 27.3 上线，开发者接口是否开放未知。
- ✅ 写了 Mac 上的评测脚本，放在 `tools/eval/extract_eval.py`，附 5 份模拟订单。
- ✅ 用 Qwen3-4B 和 1.7B 跑了第一轮：4B 关键字段正确率 90–95%，可以当主力；1.7B 约 75%，只能做低内存机型的降级。
- ✅ 总结出三条 schema 规则：所有字段必填但允许为空；日期和时间用正则约束；字段名要能看出含义。

**Phase 0 还剩**

- 收集 20–30 份真实订单 PDF，脱敏后手写标准答案。
- 评测脚本加上 PDF 抽文本和自动打分。
- 再测 Gemma 3n，和 Haiku 做对照。
- 在真机上用 MLX 测 4B 的速度和内存。
- 写决策备忘。

---

## 5. 已完成明细

### 10-21 · v1.0 和规划

| 提交 | 内容 |
|------|------|
| `9b68a38` | 打包页、时间轴地址、数据库打不开时备份而不是删除 → 打 tag `v1.0` |
| `b5afeb8` | 写路线图和 MVP2 计划 |
| — | MVP2 Phase 0：查证大陆可用性、本地模型评测、设置页加端侧模型检测卡片（`6933b52`，10-22 提交） |

### 10-22 · A 组

| 提交 | ID | 内容 |
|------|----|------|
| `c65de76` | A1 | 删除行程前二次确认 |
| `d84acd5` | A2 | 关于页的名称和版本号从包里读 |
| `259be97` | A3 | 相机权限说明，拍照不再闪退 |
| `3b71aac` | A4 | 待办页不再对已结束行程显示“进行中”，加空状态 |
| `3670d1b` | A5 | 只支持 iPhone 竖屏 |
| `8ff8943` | A6 | 行程列表空状态和“创建行程”按钮 |

### 10-24 · B 组

| 提交 | ID | 内容 |
|------|----|------|
| `5234613` | B1 | 删除行程、交通、酒店、地点、信息时一起删附件；编辑酒店不再丢附件 |
| `7f55c65` | B2 | 附件导入失败、文件丢失、没有相机时弹提示 |
| `75f42b3` | B5 | 示例数据只在 Debug 版写入；去掉打包清单里的个人条目 |
| `c11473a` | B6 | 时间改用选择器；地点支持时间段和“全天” |
| `146c27e` | B7 | 每日时间轴按时间排序 |
| `78fa466` | B3 | 编辑行程名称、emoji、颜色 |
| `a8d5c00` | B4 | 编辑行程日期，删除有内容的日期前先确认 |

### 10-24 · C 组：数据模型升级

| 提交 | ID | 内容 |
|------|----|------|
| `e339381` | C0 | 模型版本化：V1 冻结，V2 为当前；首次升级前自动复制数据库；打不开时保留原库并提示 |
| 同上 | C1 | 日期改存日历日，换时区不再错一天（Japan 行程在日本曾显示晚一天） |
| 同上 | C2 | 去掉唯一约束、字段加默认值。关系改可选没做，见 G3 |
| 同上 | C3 | 迁移测试：合成数据加你手机的真实数据，数量逐项一致 |
| — | — | 手机已装 V2 并核对：3 个行程、27 天、79 条时间轴，全部一致 |

### 10-24 · D 组

| 提交 | ID | 内容 |
|------|----|------|
| `244ab8a` | D3 | 行程进行中时，总览自动滚到今天并高亮 |
| `4f6ca90` | D1 | 行程提醒通知：出发前一晚 20:00、行程中每天 08:00。开关默认关，打开时才申请权限 |
| `92805c2` | D4 | 行程内的按钮、徽章、tab 栏用行程主色 |
| `6c7b25f` | D2 | 简体中文。语言跟随 iOS 的“按 App 设置语言” |
| `46cffa1` | D5 | 分享行程（纯文本版，后来被 PDF 取代） |
| `8d5c0ed` | D6 | 打包清单一键取消全部勾选。按行程复制没做，见 G2 |
| `d31307c` | D7 | 改日期时可选择整体平移，所有安排一起挪 |
| `f7cbb32` | — | 补中文翻译，加翻译合并工具 |

### 10-24 · 额外

| 提交 | 内容 |
|------|------|
| `ec3a4da` | 自定义行程颜色：取色器、记住用过的颜色、长按删除；浅色自动保证文字可读 |
| `bbf9097` | 分享改成排版过的 PDF：行程一览表、交通表、酒店表、每日卡片、页码 |
| `ffa4653` | 去掉 Markdown 选项，只保留 PDF |
| `07c17fa` | 记录下次待办 |

---

## 6. 工作方式备忘

**位置**

- 仓库：`/Users/xiao/Projects/github/AppleApp/IOSApp/TravelTips`，分支 `develop`。VSCode 默认打开的 `Projects/AppleApp/...` 是空壳目录。
- 手机数据备份：`~/Documents/TravelTips-Backups/`，最新一份是 `2026-10-24-1513-phone-postV2`。
- PDF 导出样例：`~/Documents/TravelTips-Exports/2026-10-24-samples/`。

**常用命令**

这台 Mac 的命令行工具指向 Command Line Tools，所以每条 `xcodebuild` 都要带 `DEVELOPER_DIR`。

```bash
cd /Users/xiao/Projects/github/AppleApp/IOSApp/TravelTips
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# 编译
xcodebuild -project TravelTips.xcodeproj -scheme TravelTips -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

# 单元测试（iPhone 16 / iOS 18.4 模拟器）
xcodebuild test -project TravelTips.xcodeproj -scheme TravelTips \
  -destination 'id=A7841EE0-91A6-4E78-B05E-909FA46D50FB' -only-testing:TravelTipsTests \
  CODE_SIGNING_ALLOWED=NO

# 推送
git push origin develop
```

**从手机备份数据**（Xcode 的 Download Container 在这台机器上会报错，用这个）

```bash
B=~/Documents/TravelTips-Backups/$(date +%Y-%m-%d-%H%M)-phone
for sub in Library Documents; do
  xcrun devicectl device copy from --device 9027A0A1-EC78-5186-BFB5-BF2AB6D42EAB \
    --domain-type appDataContainer --domain-identifier XimeCraft.TravelTips \
    --source "$sub" --destination "$B/$sub"
done
```

**验证工具**

| 工具 | 用途 | 怎么用 |
|------|------|--------|
| 截图巡检 `TravelTipsUITests/ScreenshotTour` | 在模拟器里自动点一遍，截下列表、总览、分享面板、编辑表单、设置页 | 测试命令加 `TEST_RUNNER_TRAVELTIPS_SCREENSHOT_TOUR=1`，中文再加 `TEST_RUNNER_TRAVELTIPS_TOUR_LANG=zh-Hans` |
| 真实库迁移测试 | 用手机备份验证数据迁移 | 加 `TEST_RUNNER_TRAVELTIPS_STORE_FIXTURE=<含 default.store 的目录>` |
| 真实库导出 PDF | 看真实行程导出的排版 | 加 `TEST_RUNNER_TRAVELTIPS_EXPORT_STORE=<目录>` 和 `TEST_RUNNER_TRAVELTIPS_EXPORT_DIR=<输出目录>`，中文加 `-testLanguage zh-Hans` |
| 翻译合并 `tools/i18n/add_translations.py` | 把新文字的中文翻译补进字符串目录，不覆盖已有的 | 见脚本开头说明 |
| 模型评测 `tools/eval/extract_eval.py` | MVP2 本地模型抽取评测 | `python3 tools/eval/extract_eval.py --model qwen3:4b` |

**注意**

- 模拟器里的数据是你手机数据的副本，其中 Spain 被挪到 10/20–10/31、颜色改成了浅黄，是为了测试“今天”和浅色效果，不影响手机。
- 导出相关的测试按英文写断言，在中文环境下失败属于预期。

---

## 7. 不在近期范围

- 正式开启 iCloud 同步（G3 做完后才具备条件，还要处理冲突和多设备测试）
- 行程模板、多人协作
- 地图视图
- F 组上线事项：App 图标、隐私清单、加密声明、部署目标降到 17.0、商店素材、TestFlight
