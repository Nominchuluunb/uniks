# SOUL.md — Uniks Project Manifesto

> *The soul of Uniks is not in the cloud. It is in your device, in your rhythms, in your data.*

## Guiding Principles

Uniks is a premium, open-source, ultra-low-latency personal event and habit logger for macOS and iOS. Every line of code, every design decision, and every contributor conversation is measured against the principles below.

### 1. Privacy Is Not a Feature — It Is the Foundation
- **Zero outbound telemetry.** No analytics SDKs, no crash reporters that phone home, no behavioral tracking.
- **Your data is yours.** It lives on your devices, in a local database you can inspect, export, and delete at any time.
- **Cloud is opt-in and encrypted.** If CloudKit synchronization is offered, it will be end-to-end encrypted and owned entirely by the user. We cannot read it. No one else can either.

### 2. Anti-SaaS, Pro-Ownership
- Uniks will never become a subscription service that holds your data hostage.
- The codebase is open-source so that the community can audit, fork, and sustain it independently.
- Business models, if any, must align with user ownership: one-time purchase, donations, or self-hosted extensions — never rent-seeking on personal data.

### 3. Local AI Autonomy
- Natural-language parsing runs locally on your device or via a localhost endpoint you control (Ollama, LM Studio, etc.).
- No cloud LLM APIs. No token metering. No vendor lock-in.
- The default engine is Apple MLX Swift for native Apple Silicon performance. A fallback exists for power users, but the happy path is fully on-device.

### 4. Ultra-Low Latency
- The input path must feel instantaneous. From keystroke to visual confirmation: **< 80 ms**.
- Heavy work — parsing, indexing, model loading — is asynchronously decoupled from ingestion.
- We optimize for perceived speed first, then throughput.

### 5. Human Interface, Not Machine Interface
- Visual density is high, but scannability is higher.
- Native SF Symbols, dynamic colors, and Apple Human Interface Guidelines are the baseline.
- The app should feel like it was built by Apple craftsmen who happen to care about privacy.

## Core Design Thesis

> **Capture first, understand later.**

A user should be able to open Uniks, type or speak a thought, and dismiss the input within a heartbeat. Whether the AI parsing succeeds or fails, the raw memory is already saved. Over time, the local model learns the user's patterns and improves extraction without ever sending those patterns anywhere.

## Non-Negotiables

The following are absolute. They are not up for debate in pull requests.

1. No third-party analytics or telemetry.
2. No cloud LLM endpoints as default behavior.
3. No blocking of the main thread for persistence, parsing, or search.
4. No proprietary data formats without an open, documented export path.
5. No feature that requires an account or a server we control.

## Open-Source Contributor Vision

Uniks is a commons. We welcome contributors who share these values.

- **Code quality over velocity.** Prefer small, well-tested, well-explained changes.
- **Auditability.** Every privacy-sensitive path must be readable and reviewable.
- **Inclusivity.** Good first issues, clear documentation, and respectful review.
- **Sustainability.** Decisions should make the project easier to maintain in five years, not harder.

## Data Ownership Pledge

We will never:
- Sell user data.
- Use user data to train proprietary models.
- Require an internet connection for core functionality.
- Obfuscate the location or format of user data.

## Amendments

This document is intentionally hard to change. Proposed amendments must be discussed in a public issue and approved by the project maintainer. The spirit of the document — user sovereignty, privacy, and local-first design — is immutable.

---

*Uniks — your life, your device, your rules.*
