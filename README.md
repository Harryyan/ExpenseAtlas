# ExpenseAtlas

A privacy-first personal expense analysis app for Apple platforms. Imports bank statements (PDF), extracts transactions with on-device AI, and renders a categorized spending atlas.

All processing — text extraction, transaction parsing, categorization, monthly analysis — runs locally via Apple's **FoundationModels** framework. No data leaves the device.

---

## Requirements

| Item | Version |
| --- | --- |
| iOS / iPadOS | 26.2+ |
| macOS | 26.2+ |
| visionOS | supported (xros / xrsimulator) |
| Xcode | matching SDK for OS 26.2 |
| Swift | 6.0 |
| Apple Intelligence | **required** (iPhone 15 Pro+, M-series iPad, or M-series Mac) |

If Apple Intelligence is unavailable, the app launches but AI features are disabled. The reason is surfaced via `ModelAvailabilityService`.

---

## What it does today

- **Library** — folders + imported statement documents, three-column `NavigationSplitView`.
- **Document import** — pick PDF files; persisted under `Application Support/Statements/`.
- **AI extraction** — `PDFStatementProcessor` reads PDF text via `PDFKit`, sends up to 8000 chars to a `FoundationModels` `LanguageModelSession`, and decodes a structured `TransactionExtraction`. Falls back to a regex parser on AI failure.
- **Categorization** — streams transactions through the model into one of 15 fixed `CategoryEntity` cases (`groceries`, `dining`, `transport`, …).
- **Atlas** — per-document summary: transaction count, total debit, category breakdown.
- **Currency detection** — heuristic match for NZD / AUD / USD / EUR / GBP / CAD / CNY (defaults to NZD).

### Not yet implemented

The data model carries `FileType` cases for `csv`, `ofx`, `qif`, but only `pdf` has a working processor. The original prompt is also tuned specifically for **ANZ New Zealand** statement layouts; other banks may need prompt tuning.

There is no recurring-payment detection, anomaly detection, share-extension import, or drag-and-drop import in the current code. Monthly analysis exists as a prompt (`generateMonthlyAnalysis`) but is not wired into a UI surface yet.

---

## Architecture

Clean Architecture + MVVM. Outer layers depend on inner layers through protocols. See `.claude/policies/architecture.md` for the enforced contract.

```
UI (SwiftUI Views)
   ↓
Presentation (@Observable ViewModels)
   ↓
Domain (UseCases · Entities · Repository protocols · StatementProcessing)
   ↑
Data (SwiftData repositories · FoundationModelsService · PDFStatementProcessor)
```

Composition root: `ExpenseAtlasApp` → `AppEnvironment.live()` → `AppCore.live()` wires the AI service, model-availability service, and PDF processor into per-feature factories (`LibraryFeatureFactory`, `DetailFeatureFactory`, `AtlasFeatureFactory`).

### Persistence

SwiftData store at `Application Support/ExpenseAtlas.store`.

| Model | Notes |
| --- | --- |
| `Folder` | user-created groupings; cascades to docs |
| `StatementDoc` | imported file metadata + analysis status (`idle` / `processing` / `done` / `failed`); cascades to transactions |
| `Transaction` | date, amount (`Decimal`), currency, direction, category, optional merchant / balance / reference |

---

## Project layout

> Note: there is a double-nested `ExpenseAtlas/ExpenseAtlas/ExpenseAtlas/` directory because the Xcode project lives one level inside the repo. Source paths below are abbreviated.

```
ExpenseAtlas/                       # repo root (this README)
├── ExpenseAtlas.xcodeproj/         # workspace project (note: also nested copy below)
└── ExpenseAtlas/                   # Xcode project root
    ├── ExpenseAtlas.xcodeproj/
    ├── ExpenseAtlasTests/
    ├── ExpenseAtlasUITests/
    └── ExpenseAtlas/               # app source
        ├── App/                    # ExpenseAtlasApp, AppCore, AppEnvironment
        ├── DB/Model/               # SwiftData @Model types
        ├── Domain/
        │   ├── Entity/             # CategoryEntity, AI/* DTOs
        │   ├── Protocols/          # AIRepositoryProtocol
        │   ├── RepositoryProtocol/ # StatementRepository, FolderRepository
        │   ├── Services/           # StatementProcessing, PDFStatementProcessor
        │   └── Usecase/            # Statement / Folder / Categorization
        ├── Data/
        │   ├── Repositories/       # AIRepository
        │   ├── Services/           # FoundationModelsService, ModelAvailabilityService
        │   └── SwiftData/          # *RepositoryImpl
        └── Features/
            ├── Library/            # FolderSidebar + DocumentList
            ├── Detail/             # PDF preview + transactions tabs
            └── Atalas/             # summary view (folder typo preserved)
```

---

## Build & run

```bash
open ExpenseAtlas/ExpenseAtlas.xcodeproj
```

Select a destination on iOS 26.2 / macOS 26.2 with Apple Intelligence enabled, then run.

Tests: `Cmd+U` in Xcode (target `ExpenseAtlasTests`).

---

## Coding policies

This repo ships strict policies for Claude Code under `.claude/policies/`:

- **architecture.md** — Clean Architecture dependency rule, layer responsibilities, model-mapping rules, error-handling contract.
- **coding-style.md** — `@Observable` only (no `ObservableObject`); no force-unwrap; `final class` by default; no `Task` blocks inside `View` bodies; views render only via ViewModel.

Slash commands available: `/check-architecture`, `/check-style`, `/commit`.

---

## Privacy

All AI inference uses Apple's on-device `FoundationModels`. Statement files are stored under the app's `Application Support` directory; the SwiftData store is local. Nothing is uploaded.
