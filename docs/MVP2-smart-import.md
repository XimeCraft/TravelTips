# MVP2 · 智能导入（Smart Import）

> 状态：规划中。前置条件：1.x 的 C 组（日期模型修复）完成。
> 定位：探索性项目。目标是验证"PDF → 行程"在端侧能不能做到可用，顺带为后续的知识库 / Knowledge Bot 打底。
> 相关：[ROADMAP-1.x.md](ROADMAP-1.x.md)

---

## 1. 目标与范围

**用户故事**：我订完机票和酒店后，把邮件里的 PDF 一次性选进 App，App 自动识别每份是机票、酒店还是火车票，抽出日期、时间、地点，生成草稿让我确认，确认后自动出现在 Transport / Hotels / Places 对应的天里，原 PDF 挂为附件。

**MVP2 做的**

- 多选 PDF 导入（Files 选择器 + Share Extension 从邮件 / 微信直接分享进来）
- 自动分类：flight / train / bus / ferry / hotel / activity / unknown
- 字段抽取：见第 4 节的 schema
- 映射到现有模型：按日期找 `TripDay`，酒店按晚生成，多段航班拆多条
- 草稿确认页：逐条展示，可编辑，低置信度字段标红，用户确认后才入库
- 原 PDF 自动成为对应条目的 `Attachment`
- 行程不存在时，从 PDF 日期范围创建新行程

**MVP2 不做的**

- 自动入库不经确认（永远不做）
- 自动读邮件
- 后端服务、付费、账号体系
- 把航班时间转成统一时区（出发 / 到达时间保持各自机场的当地时间）

---

## 2. 用户流程

1. Transport / Hotels 任一页顶部出现"导入 PDF"按钮；或从邮件 / 微信分享 PDF 到 TravelTips
2. 选择 1 到 N 个 PDF
3. 进度页：逐份显示"提取文字 → 识别 → 生成草稿"
4. 确认页：每份 PDF 一张草稿卡，显示类型、关键字段、置信度；可编辑、可删除、可改类型
5. 点"全部导入"：写入模型，创建 TimelineItem 和 Attachment，跳回对应 tab
6. 失败的 PDF 单独列出，允许重试或手动录入

---

## 3. 架构

```
[PDF 文件]
   │
   ▼
PDFTextExtractor        PDFKit `PDFPage.string`；无文字层时用 Vision OCR 兜底
   │
   ▼
TextCleaner             去条款、去页眉页脚、合并空白、按 token 预算截断
   │
   ▼
DocumentExtractor       协议。输入清洗后的文本，输出 ExtractedDocument
   ├─ FoundationModelsExtractor   iOS 26 端侧，@Generable 保证结构
   ├─ LocalLLMExtractor           MLX / llama.cpp 跑开源小模型（研究项）
   ├─ ClaudeAPIExtractor          用户自带 key，URLSession 直连，结构化输出
   └─ RuleBasedExtractor          正则，只认机票；也用作校验层
   │
   ▼
ImportMapper            纯 Swift，零 token。ExtractedDocument → [DraftEntity]
   │                     找 TripDay、拆多段、酒店按晚、跨夜处理、创建行程
   ▼
ImportReviewView        草稿卡片、编辑、置信度、确认
   │
   ▼
ImportCommitter         复用现有新增路径，保证 linkedId 不变量；创建 Attachment
```

**关键设计决定**

- `DocumentExtractor` 是协议，模型后端可插拔。研究阶段换模型只换一个类。
- 分类和抽取是**同一次模型调用**，`kind` 是输出的一个字段。不存在"先问一次是什么类型，再问一次抽字段"的两步开销。
- 模型只做"文本 → 结构化 JSON"这一步。之后决定进哪个 tab、匹配哪一天、生成几条记录，全部是 Swift 代码，不消耗 token。
- 发给模型的是清洗后的**文本**，不是 PDF 本身。文本路径比 PDF 直传便宜 3 到 5 倍，也能装进端侧模型的 4k 上下文。

---

## 4. 抽取 Schema

```swift
struct ExtractedDocument: Codable {
    enum Kind: String, Codable { case flight, train, bus, ferry, hotel, activity, unknown }

    var kind: Kind
    var confidence: Double              // 0–1，模型自评；低于 0.6 在确认页标红
    var bookingReference: String?
    var passengerNames: [String]
    var segments: [TransportSegment]    // 往返、中转 → 多段
    var stay: HotelStay?
    var activity: ActivityInfo?
}

struct TransportSegment: Codable {
    var operatorName: String?   // "中国国际航空", "中国铁路12306"
    var serviceNumber: String?  // "CA981", "G1234"（完整航班号 / 车次）
    var fromCode: String?       // IATA / 车站代码
    var fromName: String        // "Beijing Capital T3"
    var toCode: String?
    var toName: String
    var departureDate: String   // "yyyy-MM-dd"
    var departureTime: String?  // "HH:mm"，出发地当地时间
    var arrivalDate: String?    // 跨夜航班与出发日不同
    var arrivalTime: String?    // "HH:mm"，到达地当地时间
    var seat: String?
}

struct HotelStay: Codable {
    var name: String
    var address: String?
    var checkInDate: String     // "yyyy-MM-dd"
    var checkOutDate: String
    var checkInTime: String?    // "HH:mm"
    var roomType: String?
    var confirmationNumber: String?
}

struct ActivityInfo: Codable {
    var name: String
    var address: String?
    var date: String?
    var time: String?
    var ticketPrice: String?
    var notes: String?
}
```

端侧用 Foundation Models 时，同一个结构加 `@Generable` 和 `@Guide(description:)`；端侧开源模型用 JSON Schema 约束解码；云端用 Claude 时，把它转成 JSON Schema 放进 `output_config.format`。三边输出保证符合结构，不需要手写 JSON 容错。

Phase 0 评测得出的三条 schema 规则（见 6.7）：
1. **所有字段 required 且允许 null**。小模型会直接省略可选字段。
2. **日期和时间加 regex pattern**（`^\d{4}-\d{2}-\d{2}$`、`^\d{2}:\d{2}$`），否则会出现 `"202:03-16"` 这类串。
3. **字段名自解释**。`carrier` / `number` 会被互换，`operatorName` / `serviceNumber` 不会。

---

## 5. Token 成本模型

假设一份两页的确认单，清洗后约 2,000 token 文本，系统提示 500 token，输出 JSON 约 400 token。

| 后端 | 每份 | 每 100 份 | 每 1,000 份 |
|------|------|-----------|-------------|
| Apple Foundation Models（端侧） | 0 | 0 | 0 |
| 开源小模型（端侧） | 0 | 0 | 0 |
| Claude Haiku 5.5 | ≈ $0.00045 | $0.045 | $0.45 |
| Claude Sonnet 5.5 | ≈ $0.009 | $0.9 | $9 |
| Claude Opus 5.5 | ≈ $0.018 | $1.8 | $18 |

价格基准（2026-10）：Haiku 5.5 $0.10 / $0.50，Sonnet 5.5 $2 / $10，Opus 5.5 $4 / $20，均为每百万输入 / 输出 token。

**结论**：

- 分类、抽取、后续处理加起来就是上表这一次调用的成本，没有隐藏的第二次调用。
- 云端如果只用 Haiku 5.5，1,000 个重度用户一年也就几十美元。费用本身不是问题，**问题是谁付、怎么收、key 放哪**。
- MVP2 期间不需要回答这个问题：端侧 0 成本，开发调试用自己的 API key 放在本地 `Secrets.xcconfig`（已加入 .gitignore），绝不打包进 App。

---

## 6. 模型路线调研（Phase 0 的核心工作）

### 6.1 候选

| 候选 | 参数量 | 4-bit 大小 | 运行时 | 中文能力 | 备注 |
|------|--------|-----------|--------|----------|------|
| Apple Foundation Models | ~3B | 系统自带，0 下载 | iOS 26 `FoundationModels` | 支持简中 | 免费离线；4,096 token 上下文；只在 Apple Intelligence 机型可用（iPhone 15 Pro 及以后、16 / 17 全系）；**国行机型目前不可用**，见 6.6 |
| Qwen3-4B-Instruct | 4B | ~2.5 GB | MLX Swift / llama.cpp | 强 | Apache 2.0。中文 OTA 确认单最可能表现好的开源选项 |
| Qwen3-1.7B-Instruct | 1.7B | ~1.1 GB | 同上 | 中 | 4 GB 内存机型也能跑 |
| Gemma 3n E2B / E4B | 2B / 4B 有效 | ~1.5 / 2.5 GB | llama.cpp / MLX | 中 | Google 专为移动端设计 |
| Phi-4-mini | 3.8B | ~2.3 GB | llama.cpp / MLX | 弱 | 英文结构化抽取不错，中文一般 |
| Claude Haiku 5.5 | 云 | 无 | URLSession | 强 | 准确率参考下限；大陆无法直连 |
| Claude Sonnet 5.5 | 云 | 无 | URLSession | 强 | 准确率天花板参考，不打算默认使用 |

### 6.2 可行性预估（实测前的判断，需要 Phase 0 验证）

任务是"清洗后的文本 → 固定 schema 的 JSON"，这是小模型最擅长的任务类型之一，前提是用约束解码（Foundation Models 的 guided generation、llama.cpp 的 GBNF grammar、MLX 的 structured generation）保证输出格式。

| 模型档位 | 文字层清晰的 PDF | OCR 噪声 / 复杂版式 |
|----------|------------------|---------------------|
| 3–4B 端侧 + 约束解码 | 关键字段 80–90% | 60–75% |
| 1.5–2B 端侧 | 65–80% | 50–65% |
| Haiku 5.5 | 90–95% | 85–90% |
| Sonnet 5.5 | 95%+ | 90%+ |

小模型典型翻车点：往返票拆段、DD/MM 和 MM/DD 歧义、跨夜到达日、中文 OTA 把多个订单塞一页、把"预订日期"当成"出发日期"。这些恰好都能靠确认页和规则校验兜住。

**判断**：3–4B 档位的开源模型配约束解码，加上确认页，做出可用的导入功能是现实的。不需要 Sonnet / Opus。

### 6.3 端侧运行时与机型

| 运行时 | 优点 | 缺点 |
|--------|------|------|
| Foundation Models | 零下载、零维护、Apple 做了约束解码 | 机型门槛高；大陆可用性存疑；不能换模型 |
| MLX Swift | Apple 官方维护，Qwen / Gemma 支持好，性能最好 | 要自己托管模型文件下载 |
| llama.cpp（Swift package） | 机型覆盖最广，GBNF grammar 成熟 | 集成稍重，更新快 |

内存：4B 4-bit 推理约需 3 GB 空闲内存，对应 iPhone 13 Pro / 14 Pro / 15 及以后（6 GB+）。1.7B 可以覆盖 4 GB 机型。模型文件走自有下载，首次使用时下载，不打进包体。

### 6.4 评测方案

1. **攒语料**：20 到 30 份真实 PDF。来源要覆盖：携程、飞猪、去哪儿、Trip.com、12306、航司直出（国航 / 东航 / 南航 / 国泰 / 新航）、Booking、Agoda、Airbnb、Klook。脱敏后放 `docs/eval-corpus/`（不入库，加 .gitignore）。
2. **标金标准**：每份手写一个 `ExtractedDocument` JSON。
3. **Mac 上先跑**：写一个 Swift 命令行脚本或 Python 脚本，PDFKit 抽文本 → 各模型抽取 → 和金标准比对。不碰 iOS 工程。
4. **指标**：关键字段准确率（kind、日期、出发 / 到达地、航班号、酒店名、入住 / 退房日），分模型、分来源统计。
5. **决策门槛**：关键字段 ≥ 85% 的模型进入 Phase 1；否则换模型或加规则层。
6. **再测端侧**：选定模型后在真机测延迟、内存、发热。目标：单份 PDF 10 秒内。

### 6.5 决策树

```
目标用户主要在中国大陆？
├─ 是 → 国行机型目前不可用（见 6.6）→ Qwen3-4B via MLX 为主，1.7B 覆盖低内存机型
│        └─ 12 月 iOS 27.3 后复查；若开发者接口开放，再把 Foundation Models 加为优先路径
└─ 否 → Foundation Models 优先，BYOK Claude 做兜底
```

### 6.6 Apple Intelligence 在中国大陆的现状（2026-10-21 查证）

- **尚未上线。** 苹果官方支持页写明：在中国大陆购买的设备目前无法使用 Apple Intelligence；在其他地区购买的设备，如果人在大陆且 Apple 账户地区也是大陆，同样不可用。
- **预计 2026 年 12 月随 iOS 27.3 上线**（彭博社 / SCMP 报道，苹果未官方确认）。7 月通过生成式 AI 备案，9 月 29 日取得上线许可，模型由阿里 Qwen 供货。
- **首批功能很窄**：写作工具、通知摘要、照片清理等，不含新 Siri 和 Image Playground。**没有任何报道提到第三方开发者的 Foundation Models 框架会同步开放。**
- **对本项目的影响**：如果目标用户是国行 iPhone，Foundation Models 路线在 12 月前确定不可用，12 月后也要再验证。决策树里"大陆为主"这一支默认走 Qwen3 via MLX。
- **复查时间**：iOS 27.3 发布后，在国行机上重跑 Settings → Debug → On-device model 检测。

### 6.7 Phase 0 初步结果（2026-10-21）

环境：Mac M1 16 GB，Ollama 0.33，temperature 0，thinking 关闭，JSON Schema 约束输出。样例是 5 份模拟确认单（携程往返机票、Booking 酒店、12306、飞猪酒店乱排版、Klook 活动），放在 `tools/eval/samples/`。

| 模型 | 关键字段正确率 | 每份延迟 | 结论 |
|------|---------------|---------|------|
| Qwen3-4B | 第一轮 87%，schema 修正后三轮 90–95% | 10–21 s | **可作主力** |
| Qwen3-1.7B | 约 75%：漏掉返程 +1 跨夜、飞猪酒店 `stay` 为空、编造三字码 | 5–14 s | 只能作低内存机型降级，确认页要更严 |

4B 做对的难点：往返拆两段、`15:40 +1` 推成次日、从机场名推出 PEK / CAI、无年份日期靠上下文补对年、乱排版的飞猪单完整抽出。

发现的问题和对策：

| 问题 | 出现情况 | 对策 | 状态 |
|------|---------|------|------|
| 可选字段被省略（航班号、地址整个没输出） | 第一轮 3/5 | schema 全部 required + null | 已改，有效 |
| 无年份日期猜成 2024 | 飞猪单 | 上下文给行程日期范围 | 已改，有效 |
| `carrier` / `number` 互换 | 第二轮 | 改名 `operatorName` / `serviceNumber` | 已改，有效 |
| 数字串偶发错位：`202:03-16`、`2021-03-16`、订单号中插冒号 | 每轮 1–2 处，固定在第一个日期或长数字串 | 日期加 regex 保证格式；**mapper 必须做范围校验**（不在行程 ±3 天内标红）；Phase 1 在 MLX 上复测是否为 Ollama 采样器特有 | 待验证 |
| 退房日被填成上下文里的行程结束日 | 第三轮 Booking 单 | 逻辑校验：退房 > 入住，晚数与文本一致 | 待实现 |
| hotel / activity 的 `segments` 塞垃圾 | 持续 | mapper 按 kind 忽略 | 无害 |
| `passengerNames` 出现 "Adult 1" 占位符 | 持续 | App 不用这个字段 | 无害 |

**结论**：4B 级别的开源模型配约束解码和确认页，能完成这个功能。剩余错误全部是"日期值不合理"这一类，正好是范围校验能抓住的。

复现：
```bash
ollama pull qwen3:4b
python3 tools/eval/extract_eval.py --model qwen3:4b
```

下一步（P0 剩余）：换成 20–30 份真实 PDF、写金标准、脚本自动打分；在 MLX Swift 真机复测 4B 的延迟和数字错位。

---

## 7. 收费与成本策略

**本阶段结论：不做支付，不做后端。**

| 模式 | 需要什么 | 本阶段 |
|------|----------|--------|
| 端侧模型 | 什么都不需要 | **默认** |
| BYOK（用户自带 API key） | 设置页一个输入框，Keychain 存储，URLSession 直连 | Phase 4 可选 |
| 自建代理 + 内购 | 见下 | 不做 |

"自建代理 + 内购"到底包含什么，列出来是为了说明它为什么不是 MVP2 的事：

- 一个后端（Cloudflare Workers / Vercel 之类），持有你的 API key，转发请求
- 设备认证（App Attest / DeviceCheck），否则别人可以绕过 App 直接刷你的代理
- 每用户配额和限流
- StoreKit 2 内购：免费 N 次之后买"导入次数包"（消耗型比订阅简单）
- 服务端收据校验（App Store Server API），否则越狱设备可以伪造购买
- 恢复购买、退款处理、客服
- 隐私政策要写明护照号和订单信息会经过你的服务器

估计 1 到 2 周开发加长期运维。只有在决定上线并且端侧方案确实覆盖不了目标用户时才值得做。端侧方案成立的话，这整个问题消失。

---

## 8. 分阶段 Todo

### Phase 0 · 研究（1 周）

| ID | 事项 | 产出 |
|----|------|------|
| P0-1 | 攒 20–30 份真实 PDF 语料并脱敏 | `docs/eval-corpus/`（gitignore） |
| P0-2 | 手写金标准 JSON | 同上 |
| P0-3 | Mac 评测脚本 | `tools/eval/extract_eval.py` 已有（Ollama 版）；还缺 PDFKit 抽文本和自动打分 |
| P0-4 | 跑 Qwen3-4B、Qwen3-1.7B（已跑，见 6.7）、Gemma 3n、Haiku 5.5；Foundation Models 需 macOS 26 | 准确率对比表 |
| P0-5 | ~~确认 Apple Intelligence 大陆可用性~~ 已查（2026-10-21），见 6.6；12 月后复查开发者接口是否开放 | 一行结论 |
| P0-6 | 决策备忘：选哪个后端、机型门槛、是否接受模型下载 | 写回本文档第 6.5 节 |

### Phase 1 · 抽取原型（1–2 周）

| ID | 事项 |
|----|------|
| P1-1 | `PDFTextExtractor`：PDFKit 文字层；无文字层时 Vision `VNRecognizeTextRequest` |
| P1-2 | `TextCleaner`：去条款模板、页眉页脚、合并空白、按 token 预算截断（端侧 ≤ 3,000 token） |
| P1-3 | `ExtractedDocument` schema + `DocumentExtractor` 协议 |
| P1-4 | 选定后端的 Extractor 实现 |
| P1-5 | `RuleBasedExtractor`：航班号、三字码、PNR、日期正则；同时作为校验层 |
| P1-6 | Debug 页面：选一个 PDF，打印清洗文本和抽取 JSON，看准确率 |

### Phase 2 · 映射引擎（1–2 周）

| ID | 事项 |
|----|------|
| P2-1 | `ImportMapper`：`ExtractedDocument` → `[DraftEntity]`，纯函数 |
| P2-2 | 日期匹配到 `TripDay`；日期不在行程范围内的处理（提示扩展行程 / 丢弃） |
| P2-3 | 多段 / 往返拆成多条 `TransportInfo` |
| P2-4 | 跨夜航班：到达日的 TimelineItem |
| P2-5 | 酒店：按晚生成 `Accommodation`，入住 / 退房 TimelineItem，复用 `AccommodationTab` 现有逻辑 |
| P2-6 | 无行程时从 PDF 日期范围创建 `Trip` |
| P2-7 | 去重：同一 PDF 导两次、同一航班已手动录入过 |
| P2-8 | 单元测试覆盖以上全部用例 |

### Phase 3 · UI（1 周）

| ID | 事项 |
|----|------|
| P3-1 | 多选 PDF 入口（Transport / Hotels 页 + 行程总览） |
| P3-2 | 进度页，逐份状态 |
| P3-3 | 确认页：草稿卡、编辑、置信度标红、改类型、删除 |
| P3-4 | 提交：写入模型 + Attachment，失败项单独列出 |
| P3-5 | Share Extension：从邮件 / 微信分享 PDF 直接进导入流程 |

### Phase 4 · 扩展（按需）

| ID | 事项 |
|----|------|
| P4-1 | `ClaudeAPIExtractor`（BYOK）：Keychain 存 key，URLSession 直连，`output_config.format` 结构化输出，默认 Haiku 5.5 |
| P4-2 | 截图导入：PhotosPicker → Vision OCR → 同一管线（微信截图场景） |
| P4-3 | 扫描件 PDF 的 OCR 质量优化 |
| P4-4 | 机型不支持端侧模型时的降级提示 |

### Phase 5 · 研究：Knowledge Bot / 行程知识库

探索性，Phase 3 之后再启动。目标是"问问这次旅行"：酒店几点退房、签证要带什么、第三天晚上住哪。

| ID | 事项 |
|----|------|
| P5-1 | 把 Info、Timeline、附件抽取出的文本切块，建索引 |
| P5-2 | 端侧 embedding：`NLContextualEmbedding`（NaturalLanguage 框架）或小模型自带 embedding；向量存 SwiftData `[Float]`，余弦检索，数据量小不需要向量库 |
| P5-3 | 复用 `DocumentExtractor` 同一个模型后端做问答生成 |
| P5-4 | 聊天 UI，答案带来源（哪条 Info、哪个附件） |
| P5-5 | 评估：20 个典型问题的命中率 |

---

## 9. 风险与未决问题

| 风险 | 应对 |
|------|------|
| Apple Intelligence 在大陆不可用 | Phase 0 第一件事确认；备选 Qwen3 via MLX |
| 小模型抽取准确率不够 | 规则校验层 + 确认页；Phase 0 用数据说话，不够就换模型 |
| 端侧 4k 上下文装不下长 PDF | `TextCleaner` 按页处理再合并；条款部分直接丢弃 |
| 模型文件 1–3 GB 下载用户不接受 | 首次使用时明确提示；1.7B 作为轻量选项 |
| 日期模型没修就开工 | 硬性前置：1.x C 组完成后再开 Phase 1 |
| 导错日期导致误机 | 永不自动入库；日期和时间字段在确认页默认展开 |

**需要你决定的**

1. 目标用户是否以中国大陆为主？决定模型路线。
2. 这个功能的最低 iOS 版本：26（Foundation Models）还是 17（自带模型）？
3. 是否接受 1–3 GB 的模型下载？
4. 产品名最终叫 TravelTips 还是 TripCard？影响 Share Extension 的显示名。

---

## 10. MVP2 验收标准

- 选 5 份不同来源的 PDF（2 机票、2 酒店、1 火车票），端侧完成导入，全程无网络
- 关键字段在确认页正确率 ≥ 85%，错误字段能在确认页改正
- 导入后 Transport / Hotels / Daily 三处数据一致，linkedId 级联删除正常
- 原 PDF 出现在对应条目的附件里
- 单份 PDF 从选中到草稿出现 ≤ 30 秒（iPhone 15 Pro 或同档；M1 Mac 上实测 10–21 秒），批量导入在后台跑并显示进度
