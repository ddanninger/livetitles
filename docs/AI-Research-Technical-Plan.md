# LiveTitles - AI Model Research & Technical Plan

## Research Summary

Two independent research tracks were conducted to identify the best AI models and APIs for LiveTitles across five capability areas: real-time STT, speaker diarization, voice fingerprinting, real-time translation, and name extraction.

**Key finding: No single provider can deliver all capabilities. A best-of-breed hybrid architecture is required.**

---

## 1. Provider Evaluation Matrix

### Real-Time Speech-to-Text

| Provider | Model | Latency | Streaming | Diarization | Cost/min |
|----------|-------|---------|-----------|-------------|----------|
| **Deepgram** | Nova-3 | Sub-300ms | WebSocket | Built-in (free) | $0.0065-$0.0077 |
| **AssemblyAI** | Universal-2 | Low | WebSocket | 2.9% error rate | ~$0.0028 |
| OpenAI | Realtime API | Sub-second | WebSocket/WebRTC | No | ~$0.06 |
| OpenAI | gpt-4o-transcribe-diarize | Batch only | No | Yes (4 speakers) | $0.006 |
| Google | Cloud STT v2 (Chirp 3) | 500ms-1s | StreamingRecognize | Limited in streaming | $0.024-$0.036 |
| Anthropic | Claude | N/A | N/A | N/A | N/A (no audio API) |

### Real-Time Translation

| Provider | Model | Speed (tok/s) | TTFT | Cost (per 1M tokens in/out) |
|----------|-------|---------------|------|-----------------------------|
| **Google** | Gemini 2.5 Flash-Lite | 359 tok/s | 0.23s | $0.10 / $0.40 |
| OpenAI | GPT-4o-mini | 55 tok/s | ~0.5s | $0.15 / $0.60 |
| Anthropic | Claude Haiku 4.5 | ~80 tok/s | ~0.4s | $1.00 / $5.00 |
| DeepL | Translation API | Fast | Low | ~$25/1M chars |
| Google | Cloud Translation v3 | Fast | Low | $20/1M chars |

### Voice Fingerprinting (Cross-Session Speaker Re-identification)

| Provider | Product | On-Device | Cross-Session | Status |
|----------|---------|-----------|---------------|--------|
| **Picovoice** | Eagle SDK | Yes (macOS) | Yes | Active |
| Azure | Speaker Recognition | No (cloud) | Yes | **Deprecated (Oct 2025)** |
| OpenAI | known_speaker_references | No | Partial (4 speakers) | Batch only |

### Name Extraction from Speech

| Approach | Cost | Latency | Accuracy |
|----------|------|---------|----------|
| **Local regex patterns** | $0 | <1ms | ~80% of cases |
| GPT-4o-mini fallback | $0.15/1M tokens | ~0.5s | ~99% |
| Claude Haiku fallback | $1.00/1M tokens | ~0.4s | ~99% |

---

## 2. Recommended Architecture

```
                        ┌─────────────────────────┐
                        │    Mac Menu Bar Icon     │
                        │  (Start/Stop, Settings)  │
                        └────────────┬────────────┘
                                     │
                        ┌────────────▼────────────┐
                        │     Audio Capture        │
                        │  (Mic + System Audio)    │
                        └────────────┬────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                 │
          ┌─────────▼──────┐  ┌─────▼──────┐  ┌──────▼──────────┐
          │  Deepgram       │  │ Picovoice  │  │  (Audio stored  │
          │  Nova-3         │  │ Eagle      │  │   for session)  │
          │  (Cloud)        │  │ (On-Device)│  │                 │
          │                 │  │            │  │                 │
          │ • Real-time STT │  │ • Speaker  │  └─────────────────┘
          │ • Diarization   │  │   embedding│
          │ • WebSocket     │  │ • Voice ID │
          │ • Interim words │  │ • Persist  │
          └────────┬───────┘  └─────┬──────┘
                   │                │
          ┌────────▼────────────────▼───────┐
          │      Speaker Merge Layer         │
          │                                  │
          │  Map Deepgram speaker labels     │
          │  (A, B, C) to Eagle's persistent │
          │  speaker IDs via timestamps      │
          └────────────────┬─────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Transcript  │
                    │  with named  │
                    │  speakers    │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │                         │
    ┌─────────▼─────────┐   ┌──────────▼──────────┐
    │ Claude 3.5 Sonnet  │   │ Name Extraction      │
    │ (Anthropic)        │   │ (Local Regex +       │
    │ (Translation)      │   │  GPT-4o-mini         │
    │                    │   │  fallback)            │
    │ • Streaming output │   │                      │
    │ • Multi-language   │   │ "Hi I'm Sarah" →     │
    │ • Best quality     │   │  {name: "Sarah"}     │
    └─────────┬─────────┘   └──────────┬───────────┘
              │                         │
              └────────────┬────────────┘
                           │
                  ┌────────▼────────┐
                  │  Subtitle        │
                  │  Renderer        │
                  │                  │
                  │  • Movie-style   │
                  │  • Speaker color │
                  │  • Translation   │
                  │  • Fade in/out   │
                  └─────────────────┘
```

---

## 3. Recommended Stack (Per Capability)

| Capability | Primary Choice | Reason |
|------------|---------------|--------|
| **Real-time STT + Diarization** | Deepgram Nova-3 | Sub-300ms, cheapest, built-in diarization, WebSocket streaming, interim word results |
| **Voice Fingerprinting** | Picovoice Eagle | Only viable option, on-device (privacy+speed), cross-session persistence, macOS native |
| **Real-time Translation** | Claude 3.5 Sonnet (Anthropic) | Best translation quality per user research; streaming API support; strong multi-language accuracy |
| **Name Extraction** | Local regex + GPT-4o-mini fallback | Free for 80% of cases, LLM only when needed |
| **Anthropic Claude** | **Used for translation (Claude 3.5 Sonnet)** | Best translation quality per user testing. No audio API but excels at text translation. |

---

## 4. Cost Estimates

### Per Session (1 hour continuous)
| Component | Cost |
|-----------|------|
| Deepgram Nova-3 (STT + diarize) | ~$0.39-$0.46 |
| Picovoice Eagle (voice ID) | $0 (on-device) |
| Claude 3.5 Sonnet (translation) | ~$0.05-$0.10 |
| GPT-4o-mini (name extraction, rare) | ~$0.001 |
| **Total per hour** | **~$0.45-$0.56** |

### Per User Per Month (60 hrs/month = 2 hrs/day)
| Component | Cost |
|-----------|------|
| Deepgram | ~$23-$28 |
| Claude 3.5 Sonnet (translation) | ~$3-$6 |
| Name extraction | ~$0.01 |
| **Total per month** | **~$27-$34** |

### At Scale (1,000 hrs/month)
| Component | Cost |
|-----------|------|
| Deepgram (volume pricing) | ~$390-$460 |
| Translation (Gemini Flash-Lite) | ~$6 |
| **Total** | **~$400-$470** |

> Note: Since LiveTitles is free/open-source, users will need to provide their own API keys. The app should make this easy via a setup wizard.

---

## 5. API Key Model for Open Source

Since LiveTitles is free and open source, the app cannot subsidize cloud API costs. Users bring their own API keys:

| Service | Key Needed | Free Tier Available? |
|---------|-----------|---------------------|
| Deepgram | Yes | Yes (up to $200 credit for new accounts) |
| Anthropic (Claude 3.5 Sonnet) | Yes | Pay-as-you-go |
| OpenAI (GPT-4o-mini) | Optional | Pay-as-you-go only |
| Picovoice Eagle | License key | Free for non-commercial use |

The app settings should include an **API Keys** section where users enter their credentials. A first-run wizard should guide through this.

---

## 6. Key Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Deepgram diarization quality in noisy environments | Speakers misattributed | Eagle's on-device fingerprinting as secondary validation |
| Eagle voice matching accuracy for similar voices | Wrong speaker name assigned | Confidence threshold + user confirmation prompt |
| Translation latency spikes | Subtitles feel laggy | Buffer sentences, show original immediately, translation follows |
| Picovoice Eagle licensing for open-source distribution | May need commercial license | Free for non-commercial; document as optional premium feature |
| WebSocket connection drops during long sessions | Transcription interruption | Auto-reconnect with exponential backoff |
| API key management UX complexity | Poor onboarding for non-technical users | Step-by-step setup wizard with links to sign-up pages |

---

## 7. Alternative Considered: AssemblyAI

AssemblyAI Universal-2 was a strong contender with the best diarization accuracy (2.9% error rate) at even lower cost (~$0.0028/min). It could replace Deepgram if:
- Diarization accuracy proves insufficient with Deepgram
- AssemblyAI's WebSocket API has better developer experience

Recommendation: **Start with Deepgram, evaluate AssemblyAI as fallback.** Build a `TranscriptionProvider` protocol so swapping is easy.

---

*This document complements the PRD (docs/PRD.md). Next step: Technical architecture & implementation plan (stack, frameworks, project structure).*
