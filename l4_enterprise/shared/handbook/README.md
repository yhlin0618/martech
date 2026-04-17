# l4_enterprise Handbook

> **受眾:工讀生與新人**
>
> 本 handbook 針對剛加入團隊的工讀生與新成員,提供「具體怎麼做」的 operational guidance(操作指南)。

## 這份 handbook 是什麼

這是一份 **operational guidance**(操作手冊),告訴你在 l4_enterprise 專案中:

- 怎麼提交 commit、建 PR
- 怎麼跑 ETL / DRV pipeline
- 遇到 bug 時怎麼 debug
- 新人第一週、第一個月該做什麼

**不包含**:

- 框架內部的程式碼實作細節(framework code internals)— 工讀生不需要懂
- 架構原則的設計理由(rationale)— 那是給資深工程師看的
- 業務術語的定義(儀表板指標、公式)— 那是給客戶與老闆看的

## 與既有文件系統的分工

l4_enterprise 有四個受眾分層的文件系統。看哪邊,取決於你在找什麼:

| 如果你想找... | 去哪看 | 受眾 |
|-------------|------|------|
| **怎麼做**(commands、workflow、debug 流程) | **這份 handbook**(你在這裡) | 工讀生、新人 |
| **為什麼**(MP/P/R 原則、架構理由) | `shared/global_scripts/00_principles/docs/` | 資深工程師 |
| **業務術語**(儀表板指標、公式) | GitHub Wiki(principles 的 wiki) | 客戶、老闆 |
| **Claude Code 指引** | `CLAUDE.md`(各層都有) | AI 助手 |

handbook 的內容**不會**複製其他系統的內容 — 需要更深入理解時,會 link 過去。

## 目錄

- [`coding-standards/`](./coding-standards/) — R 命名慣例、commit message 格式、函數組織規則
- [`workflows/`](./workflows/) — git workflow、ETL pipeline 怎麼跑、debug 流程、部署流程
- [`onboarding/`](./onboarding/) — 新人 Day 1 / Week 1 / Month 1 任務

*(目前這些目錄是空的 stub;內容會由 follow-up PRs 分批填入。見 [`CONTRIBUTING.md`](./CONTRIBUTING.md) 學如何貢獻。)*

## 本 handbook 假設你會什麼

你需要有:

- git 的基本操作(clone、add、commit、push)
- shell / bash 的基本操作
- R 語言基礎(若剛接觸 R 也沒關係,`onboarding/` 會有 resources)

你 **不需要** 有:

- 懂框架內部實作
- 讀過 MP/P/R 原則
- 理解 DuckDB / Shiny / ETL 架構細節

遇到 framework 專有術語時(例如 "DRV"、"ETL phase"、"tbl2"),handbook 會 inline 解釋或指向 handbook 自己的 glossary。你**不需要**另外打開 principles docs 才能讀懂這份文件。

## 如何貢獻

見 [`CONTRIBUTING.md`](./CONTRIBUTING.md) — 教你 clone、commit、push、開 PR 的完整流程。工讀生的第一個任務通常是改 handbook 本身(例如補一個 typo、補一個 example),這本身就是 git workflow 的絕佳練習。

## 技術細節

本 handbook 是 l4_enterprise 專案的 **Track 5(Handbook Layer)**,定義於 MP122 Penta-Track Subrepo Architecture。

- 在 l4_enterprise 內的路徑:`shared/handbook/`(git submodule)
- 獨立 repo:`kiki830621/ai_martech_handbook`(private)
- 技術棧:純 markdown,無 build system — GitHub 網頁直接 render

想深入理解 Penta-Track 架構,見 `shared/global_scripts/00_principles/docs/en/part1_principles/CH00_fundamental_principles/02_structure_organization/MP122_penta_track_subrepo_architecture.qmd`。
