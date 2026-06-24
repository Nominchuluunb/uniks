# Spec: Local Model Download in Settings

**Date:** 2026-06-24  
**Scope:** v1.0, Settings enhancement  
**Status:** Approved for implementation

## Goal

Let users download on-device LLM models from Settings, see whether each model is downloaded, and view the downloaded size and status.

## Requirements

1. **Model list**
   - Show a list of available local models in Settings.
   - Initial models:
     - `mlx-community/Llama-3.2-1B-Instruct-4bit` (~0.7 GB)
     - `mlx-community/Llama-3.2-3B-Instruct-4bit` (~1.9 GB)

2. **Status per model**
   - `notDownloaded` — model files are not present.
   - `downloading` — download is in progress.
   - `downloaded(size: UInt64)` — model files are present; show size in GB (e.g. "1.9 GB").

3. **Download action**
   - Each row has a **Download** button if not downloaded.
   - While downloading, show a progress indicator and disable the button.
   - On completion, update status to `downloaded` with the actual cache size.
   - On failure, revert to `notDownloaded` and show an error message.

4. **Cache size detection**
   - Locate the Hugging Face cache directory via `HubCache.default.cacheDirectory`.
   - Check for the model-specific folder (`models--<namespace>--<repo>`).
   - Recursively sum file sizes in that folder.

5. **Download implementation**
   - Trigger `huggingFaceLoadModelContainer(configuration:)` for the selected model.
   - This downloads weights, config, and tokenizer into the Hugging Face cache.
   - After success, refresh the status.

6. **No functional changes to engines**
   - `MLXLLMEngine` continues to use the configured `modelID`.
   - The downloaded model can be selected as the active model in a future iteration.

## Files to create/modify

- Create: `uniks/Core/Services/LocalModelManager.swift`
- Create: `uniks/Core/Models/LocalModel.swift`
- Modify: `uniks/UI/Settings/SettingsView.swift`
- Create: `uniksTests/LocalModelManagerTests.swift`

## Testing

- Unit tests:
  - `checkStatus` returns `.notDownloaded` when cache folder is absent.
  - `checkStatus` returns `.downloaded` with correct size when cache folder exists.
  - `download` updates status to `.downloading` and then `.downloaded` (using a mock downloader).
- Manual verification:
  1. Open Settings → Local Models.
  2. Tap Download on the 1B model.
  3. Wait for completion → status shows "Downloaded · 0.7 GB".
