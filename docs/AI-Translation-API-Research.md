# LiveTitles: AI Translation & NLU API Research Report

**Date:** February 25, 2026
**Purpose:** Evaluate real-time translation and NLU APIs for the LiveTitles Mac desktop app
**Requirements from PRD:** < 2s translation latency, 8+ language support, name extraction from speech, streaming preferred, open-source/free app (cost-sensitive)

---

## Table of Contents

1. [Provider Deep Dives](#1-provider-deep-dives)
2. [Head-to-Head Comparison Tables](#2-head-to-head-comparison-tables)
3. [Cost Modeling for 1,000 Hours/Month](#3-cost-modeling-for-1000-hoursmonth)
4. [Recommendations](#4-recommendations)
5. [Recommended Architecture](#5-recommended-architecture)
6. [Sources](#6-sources)

---

## 1. Provider Deep Dives

### 1.1 OpenAI

#### Models Available

| Model | Input | Output | Best For |
|-------|-------|--------|----------|
| **GPT-4o** | $2.50/1M tokens | $10.00/1M tokens | Highest quality translation |
| **GPT-4o-mini** | $0.15/1M tokens | $0.60/1M tokens | Cost-effective translation |
| **gpt-realtime** (audio) | $32.00/1M audio tokens | $64.00/1M audio tokens | End-to-end speech translation |

#### Streaming API Support
- Full streaming support via Chat Completions API (SSE) for text-based translation.
- The Realtime API provides WebSocket-based bidirectional audio streaming for combined STT + translation.
- OpenAI has a published cookbook example for "Multi-Language One-Way Translation with the Realtime API" -- this is almost exactly the LiveTitles use case.

#### Latency
- **GPT-4o-mini TTFT:** ~0.44-0.48 seconds (among the fastest)
- **GPT-4o-mini output speed:** ~54.5 tokens/second
- For a typical 15-word sentence translation, expect ~0.7-1.2 seconds total via streaming (TTFT + generation)

#### Translation Quality
- GPT-4o: Strong across 50+ languages. Redesigned tokenizer in 2025 reduced token inflation by 30-40% for CJK languages and 25-35% for Indic scripts.
- Excellent for European languages (EN, DE, ES, FR, PT). Good for CJK (JA, ZH, KO).
- Some reports of issues with Russian translations specifically; otherwise robust.
- GPT-4o-mini: Slightly lower quality but still strong for common language pairs.

#### Realtime API (Combined STT + Translation)
- The `gpt-realtime` model can take audio in, understand it, and produce translated text or audio out.
- Preserves emotion, tone, and pace in speech-to-speech mode.
- Supports 57+ languages.
- **Major downside for LiveTitles:** Very expensive for continuous use. At $32/1M audio input tokens, with audio consuming ~600 tokens/minute for input, this costs roughly $0.019/minute for input alone.
- Better suited for conversational agents, not passive captioning of hours of audio.

#### Name Extraction / NER
- GPT-4o and GPT-4o-mini both handle zero-shot NER well.
- GPT-4o-mini can reliably extract "Hi, I'm Sarah" patterns with a simple system prompt.
- No dedicated NER endpoint; done via prompt engineering on the Chat Completions API.

#### Verdict for LiveTitles
GPT-4o-mini is the strongest candidate for text-based translation: extremely cheap ($0.15/$0.60 per 1M tokens), fast (0.44s TTFT), and good quality. The Realtime API is too expensive for a passive captioning app. Use GPT-4o-mini for translation of already-transcribed text.

---

### 1.2 Anthropic (Claude)

#### Models Available

| Model | Input | Output | Best For |
|-------|-------|--------|----------|
| **Claude Opus 4.5** | $5.00/1M tokens | $25.00/1M tokens | Highest quality, complex reasoning |
| **Claude Sonnet 4.5** | $3.00/1M tokens | $15.00/1M tokens | Strong quality, moderate cost |
| **Claude Haiku 4.5** | $1.00/1M tokens | $5.00/1M tokens | Fast, cost-efficient |

#### Streaming API Support
- Full streaming support via the Messages API (SSE).
- Anthropic's streaming is mature and well-documented.
- No audio/speech API -- text only. Claude cannot process audio directly.

#### Latency
- **Claude Haiku 4.5 TTFT:** ~0.48-0.58 seconds
- **Claude Haiku 4.5 output speed:** ~110-116 tokens/second (2x faster output than GPT-4o-mini)
- Haiku 4.5 runs 4-5x faster than Sonnet 4.5 in practice.
- For a 15-word translation, expect ~0.6-1.0 seconds total via streaming.

#### Translation Quality
- **Claude 3.5 ranked #1 in WMT24 translation competition** for 9 out of 11 language pairs (Lokalise blind study).
- Claude rated "good" 78% of the time by professional translators (vs. lower for GPT-4).
- Particularly strong for European languages (FR, DE, ES, PT) with natural, nuanced prose.
- Claude 4.5 Opus and Sonnet described as "excellent for beautiful prose, tone, and style."
- Weakness: Haiku 4.5 at $1/$5 per 1M tokens is 6.7x more expensive than GPT-4o-mini for the same task.

#### Name Extraction / NER
- Claude Haiku 4.5 is explicitly described as "ideal for structured content generation, entity extraction, and quick summarization."
- Few-shot prompting with 2-3 examples of "Hi, I'm [Name]" patterns would work very well.
- Haiku's speed (110+ tokens/sec) makes it suitable for real-time NER on transcribed text.

#### Haiku vs. Sonnet for Translation
- **Haiku 4.5:** Faster (4-5x), cheaper ($1/$5 vs $3/$15), sufficient quality for real-time subtitle translation.
- **Sonnet 4.5:** Better translation quality, especially for nuanced/literary content. Overkill for real-time subtitles.
- **Recommendation:** Haiku 4.5 for LiveTitles' real-time use case. Sonnet only if quality falls short.

#### Verdict for LiveTitles
Claude has the best translation quality benchmarks, especially Sonnet. Haiku 4.5 is fast enough for real-time use but is 6.7x more expensive than GPT-4o-mini per token. Claude has no audio API, so it can only process already-transcribed text. Best considered as the "quality premium" option or for the NER/name extraction task specifically.

---

### 1.3 Google (Gemini)

#### Models Available

| Model | Input | Output | Best For |
|-------|-------|--------|----------|
| **Gemini 2.5 Flash-Lite** | $0.10/1M tokens | $0.40/1M tokens | Ultra-cheap, ultra-fast |
| **Gemini 2.5 Flash** | $0.30/1M tokens | $1.50/1M tokens | Balanced quality/cost |
| **Gemini 3 Flash** | $0.50/1M tokens | $3.00/1M tokens | High quality, still fast |
| **Google Cloud Translation API v3** | $20/1M chars | N/A | Dedicated translation engine |

#### Streaming API Support
- Full streaming support via the Gemini API (SSE).
- **Gemini Live API:** WebSocket-based real-time audio streaming, similar to OpenAI Realtime.
- Audio input pricing: 2-3x text pricing depending on model (e.g., $0.30/1M for Flash-Lite audio input vs. $0.10 for text).
- Audio tokenization: 25 tokens per second of audio (1,500 tokens per minute).

#### Latency
- **Gemini 2.5 Flash-Lite TTFT:** 0.23-0.33 seconds (FASTEST of all options)
- **Gemini 2.5 Flash-Lite output speed:** ~359 tokens/second (FASTEST of all options -- 3x faster than Haiku, 6.5x faster than GPT-4o-mini)
- For a 15-word translation, expect ~0.3-0.6 seconds via streaming. This is extraordinary.

#### Translation Quality
- Gemini 2.5 Flash-Lite specifically highlights "improved translation quality" in its release notes.
- Strong in regional/Asian languages (a 2025 study found Gemini beat GPT-4 for Telugu-to-English).
- Generally considered slightly below Claude and GPT-4o for European language nuance, but competitive.
- Flash-Lite is a "lightweight" model -- translation quality may not match GPT-4o or Claude Sonnet for complex text, but is likely sufficient for conversational speech subtitles.

#### Google Cloud Translation API v3 (Dedicated)
- **$20 per 1 million characters** (roughly equivalent to ~$5/1M tokens).
- Free tier: 500,000 characters/month (never expires).
- Not a streaming API -- request/response model. Each translation is a separate HTTP call.
- Optimized specifically for translation (not a general LLM). Very fast response times.
- Supports 100+ languages vs. ~50 for LLMs.
- No "streaming token by token" -- returns full translated sentence at once.
- Quality: Google NMT is mature and reliable. Not as nuanced as LLM translation for literary text, but excellent for conversational content.

#### Free Tier
- **Gemini API Free Tier:** 15 RPM, 1,000 RPD, 250,000 TPM for Flash-Lite. This is useful for development/testing but insufficient for production use of a captioning app.
- **Cloud Translation API Free Tier:** 500,000 chars/month. For an open-source free app, this could cover light personal use (~8-10 hours of conversation/month).

#### Gemini's Multimodal Capabilities
- Gemini Live API can accept audio input directly and produce text output, potentially combining STT + translation in one call.
- Audio input costs 2-3x text input, but avoids needing a separate STT service.
- Still significantly cheaper than OpenAI's Realtime API.

#### Verdict for LiveTitles
Gemini 2.5 Flash-Lite is the speed and cost champion: 0.23s TTFT, 359 tokens/sec output, at $0.10/$0.40 per 1M tokens (cheapest of all LLMs). Google Cloud Translation API v3 is a strong dedicated alternative with a useful free tier. The Gemini Live API is interesting for combined audio+translation but adds complexity. Flash-Lite for text translation is likely the best cost/performance ratio.

---

### 1.4 DeepL

#### API Plans

| Plan | Cost | Character Limit |
|------|------|-----------------|
| **API Free** | $0 | 500,000 chars/month |
| **API Pro** | $5.49/month + $25/1M chars | Unlimited |
| **Voice API** | Enterprise pricing (on request) | Streaming audio |

#### Key Developments
- **DeepL Voice API (launched Feb 2, 2026):** Brand new, allows streaming audio input with real-time transcription and translation into up to 5 target languages simultaneously via WebSocket. This is almost purpose-built for the LiveTitles use case.
- Voice API available only to API Pro and Enterprise customers (not free tier).
- Supports 30+ languages for voice, 33 on free tier (text), 100+ on Pro (text).

#### Translation Quality
- Historically considered the gold standard for European language pairs (EN-DE, EN-FR, EN-ES, EN-PT).
- Recent 2025-2026 user feedback suggests some quality regression ("getting dumber," awkward sentences, literal idiom translations).
- Still strong for conversational content; quality concerns are more about complex/literary text.
- **Missing languages:** DeepL's language coverage for Asian languages is more limited. Japanese, Chinese, Korean are supported but not their strongest pairs.

#### Latency
- Text API: Very fast (dedicated translation engine, not a general LLM). Typical response in 100-300ms for a sentence.
- Voice API: Designed for real-time, low-latency streaming. Specific latency figures not yet published (too new).

#### Streaming
- Text API: No true streaming (returns complete translation per request). But response is fast enough that this rarely matters for sentence-level translation.
- Voice API: True WebSocket streaming with incremental results.

#### Verdict for LiveTitles
The new DeepL Voice API is extremely compelling -- it does exactly what LiveTitles needs (streaming audio in, translated text out). However, it is enterprise-priced and not free. The text API at $25/1M chars is roughly equivalent to $6.25/1M tokens, making it more expensive than GPT-4o-mini or Gemini Flash-Lite, but with potentially better quality for European pairs. The 500K chars/month free tier is useful for light personal use.

---

### 1.5 Bonus: LibreTranslate (Open Source)

- **Free, self-hosted, offline-capable** translation API.
- Built on Argos Translate (OpenNMT under the hood).
- Supports ~30 languages.
- Quality: Noticeably below all commercial options. Adequate for basic conversational content but struggles with nuance, idioms, and technical vocabulary.
- Latency: Depends on hardware. On Apple Silicon, translations are fast (sub-second for sentences).
- **Key advantage:** Zero cost, works offline, no API keys needed.
- **Key disadvantage:** Translation quality gap is significant vs. GPT-4o-mini or Google Translate.

---

## 2. Head-to-Head Comparison Tables

### 2.1 Latency Comparison (Streaming Text Translation)

| Provider/Model | Time to First Token | Output Speed (tok/s) | Est. Total for 15-word sentence |
|----------------|---------------------|----------------------|---------------------------------|
| **Gemini 2.5 Flash-Lite** | **0.23s** | **359 tok/s** | **~0.3-0.6s** |
| GPT-4o-mini | 0.44s | 54.5 tok/s | ~0.7-1.2s |
| Claude Haiku 4.5 | 0.48s | 110 tok/s | ~0.6-1.0s |
| Google Cloud Translation v3 | N/A (not streaming) | N/A | ~0.1-0.3s (full response) |
| DeepL Text API | N/A (not streaming) | N/A | ~0.1-0.3s (full response) |

**Winner: Gemini 2.5 Flash-Lite** for streaming. Google Cloud Translation v3 and DeepL for non-streaming (fastest total response).

> **Note:** For LiveTitles, the translation input is a completed sentence/phrase from the STT engine. A non-streaming API that returns the full translation in 100-300ms may actually feel faster than a streaming API with 0.4s TTFT + token-by-token output. Streaming is more important for the *display experience* (words appearing progressively) than for raw speed.

### 2.2 Translation Quality Ranking

| Language Pair | Best Quality | Runner-Up | Notes |
|---------------|-------------|-----------|-------|
| EN <-> DE | Claude / DeepL | GPT-4o | Claude won 9/11 WMT24 pairs |
| EN <-> FR | Claude / DeepL | GPT-4o | DeepL historically strongest for European |
| EN <-> ES | Claude / GPT-4o | DeepL | All very close |
| EN <-> PT | DeepL / Claude | GPT-4o | DeepL's core strength |
| EN <-> JA | GPT-4o | Gemini | OpenAI's improved CJK tokenizer helps |
| EN <-> ZH | GPT-4o | Gemini | Strong across all providers |
| EN <-> KO | GPT-4o | Gemini | Google's regional language strength |
| Mixed/Informal speech | GPT-4o / Claude | Gemini | LLMs handle slang/informal better than NMT |

**Winner: Claude (Sonnet/Opus) for peak quality; GPT-4o for broadest language coverage; DeepL for European pairs.**

> **For LiveTitles (conversational subtitles):** Quality differences between GPT-4o-mini, Haiku 4.5, and Flash-Lite are minimal for everyday speech. The quality gap matters more for literary/technical content.

### 2.3 Cost Comparison (Per 1M Tokens)

| Provider/Model | Input Cost | Output Cost | Relative Cost (vs. cheapest) |
|----------------|-----------|-------------|-------------------------------|
| **Gemini 2.5 Flash-Lite** | **$0.10** | **$0.40** | **1.0x (baseline)** |
| GPT-4o-mini | $0.15 | $0.60 | 1.5x |
| Claude Haiku 4.5 | $1.00 | $5.00 | 10-12.5x |
| Gemini 2.5 Flash | $0.30 | $1.50 | 3-3.75x |
| GPT-4o | $2.50 | $10.00 | 25x |
| Claude Sonnet 4.5 | $3.00 | $15.00 | 30-37.5x |
| Google Cloud Translation v3 | ~$5.00 equiv | N/A | ~12.5x (chars-based) |
| DeepL Pro | ~$6.25 equiv | N/A | ~15.6x (chars-based) |

**Winner: Gemini 2.5 Flash-Lite** by a significant margin. GPT-4o-mini is a close second.

### 2.4 Feature Comparison

| Feature | OpenAI | Anthropic | Google | DeepL |
|---------|--------|-----------|--------|-------|
| Streaming text translation | Yes | Yes | Yes | No (text), Yes (Voice API) |
| Audio input (combined STT+translate) | Yes (Realtime API) | No | Yes (Live API) | Yes (Voice API) |
| Name/entity extraction | Yes (via prompt) | Yes (via prompt) | Yes (via prompt) | No |
| Free tier | No | No | Yes (limited) | Yes (500K chars/month) |
| Languages supported | 57+ | 50+ | 100+ | 33 (free) / 100+ (Pro) |
| Sentence-level translation API | Yes | Yes | Yes | Yes |
| Token-by-token streaming | Yes | Yes | Yes | No |

---

## 3. Cost Modeling for 1,000 Hours/Month

### Assumptions
- Average conversation: ~150 words/minute spoken
- 1 hour = 9,000 words = ~12,000 tokens (input, English)
- Translation output: roughly equal to input (~12,000 tokens per hour)
- 1,000 hours/month = 12M input tokens + 12M output tokens
- For character-based APIs: 9,000 words/hour * 5 chars/word = 45,000 chars/hour, or 45M chars/month

### Monthly Cost Estimates (Translation Only, Text-to-Text)

| Provider/Model | Input Cost | Output Cost | **Total/Month** |
|----------------|-----------|-------------|-----------------|
| **Gemini 2.5 Flash-Lite** | $1.20 | $4.80 | **$6.00** |
| GPT-4o-mini | $1.80 | $7.20 | **$9.00** |
| Gemini 2.5 Flash | $3.60 | $18.00 | **$21.60** |
| Claude Haiku 4.5 | $12.00 | $60.00 | **$72.00** |
| Google Cloud Translation v3 | $900 (45M chars @ $20/M) | -- | **$900** |
| DeepL Pro | $1,125 (45M chars @ $25/M) + $5.49 | -- | **$1,130** |
| GPT-4o | $30.00 | $120.00 | **$150.00** |
| Claude Sonnet 4.5 | $36.00 | $180.00 | **$216.00** |

### Key Insight
**LLM-based translation is dramatically cheaper than dedicated translation APIs** at high volume. The per-token pricing of Gemini Flash-Lite ($6/month) and GPT-4o-mini ($9/month) for 1,000 hours is remarkably affordable compared to Google Cloud Translation ($900/month) or DeepL ($1,130/month).

This is because LLM token pricing includes the "intelligence" in the per-token cost, while dedicated translation APIs charge per character at a much higher rate.

### Cost of STT (Transcription) -- For Context
The transcription cost is separate from translation:

| STT Provider | Cost/Minute | 1,000 Hours/Month |
|--------------|-------------|-------------------|
| OpenAI Whisper | $0.006/min | $360 |
| GPT-4o Transcribe (w/ diarization) | $0.006/min | $360 |
| GPT-4o Mini Transcribe | $0.003/min | $180 |
| Deepgram Nova-2 | $0.0043/min | $258 |

**Total system cost (STT + Translation) for 1,000 hrs/month:**
- Cheapest: GPT-4o Mini Transcribe ($180) + Gemini Flash-Lite translation ($6) = **$186/month**
- Balanced: Whisper w/ diarization ($360) + GPT-4o-mini translation ($9) = **$369/month**

> **Note:** For an open-source free app where each user pays their own API costs, the per-user cost matters more. A single user doing 2 hours/day of captioning (~60 hrs/month) would pay:
> - STT: $10.80/month (Whisper) or $5.40/month (Mini Transcribe)
> - Translation: $0.36/month (Flash-Lite) or $0.54/month (GPT-4o-mini)
> - **Total: ~$6-11/month per user** -- very affordable.

---

## 4. Recommendations

### 4.1 Best Option for Real-Time Streaming Translation

**Primary: Gemini 2.5 Flash-Lite**
- Fastest TTFT (0.23s), fastest output (359 tok/s), cheapest ($0.10/$0.40 per 1M tokens)
- Adequate translation quality for conversational subtitles
- Free tier available for development and light use

**Runner-up: GPT-4o-mini**
- Slightly slower but more proven translation quality
- Better ecosystem and documentation
- Only 1.5x the cost of Flash-Lite (still extremely cheap)

**Premium fallback: Claude Haiku 4.5**
- Best translation quality at the "small model" tier
- 10x more expensive than Flash-Lite -- hard to justify for subtitles
- Consider only if translation quality is noticeably better in user testing

### 4.2 Best Option for Name/Entity Extraction

**Primary: GPT-4o-mini**
- Cheapest option that reliably handles NER ($0.15/$0.60 per 1M tokens)
- Zero-shot NER with a simple system prompt: "Extract any person names from self-introductions in the following transcribed text"
- Fast enough for real-time use (0.44s TTFT)

**Runner-up: Claude Haiku 4.5**
- Described as "ideal for entity extraction" by Anthropic
- Faster output speed (110 tok/s vs 54.5), but higher cost
- Slightly overkill for simple name extraction

**Budget option: Regex + simple heuristics**
- For patterns like "I'm [Name]", "My name is [Name]", "call me [Name]" -- a regex-based approach works 80% of the time with zero API cost.
- Use LLM only as a fallback for ambiguous cases.

### 4.3 Most Cost-Effective Approach for an Open-Source Free App

The app is open-source and free. Users will need to provide their own API keys. The architecture should:

1. **Minimize API calls** -- batch translation by sentence/phrase, not word-by-word.
2. **Use the cheapest viable model** -- Gemini 2.5 Flash-Lite for translation.
3. **Cache translations** -- repeated phrases in meetings ("Can you hear me?", "Let me share my screen") should be cached locally.
4. **Make the translation provider configurable** -- let users choose OpenAI, Anthropic, Google, or DeepL based on their existing subscriptions.
5. **Offer regex-based name extraction first** -- fall back to LLM only when regex is uncertain.
6. **Leverage free tiers** -- Google Cloud Translation's 500K chars/month free tier covers ~11 hours of conversation/month at zero cost. Gemini API free tier covers development and light use.

### 4.4 Recommended Architecture: Best-of-Breed Combination

**Do NOT use a single provider.** A best-of-breed approach is recommended:

```
                            +------------------+
                            |   System Audio   |
                            |   / Microphone   |
                            +--------+---------+
                                     |
                                     v
                     +-------------------------------+
                     |   STT Layer (Provider Choice)  |
                     |   - OpenAI Whisper/Transcribe  |
                     |   - Deepgram Nova-2            |
                     |   - Apple Speech (free/local)  |
                     +-------------------------------+
                                     |
                          Transcribed text + speaker ID
                                     |
                    +----------------+----------------+
                    |                                 |
                    v                                 v
        +---------------------+           +----------------------+
        | Translation Layer   |           | NLU Layer            |
        | (Provider Choice)   |           | (Name Extraction)    |
        | - Gemini Flash-Lite |           | - Regex first        |
        | - GPT-4o-mini       |           | - GPT-4o-mini        |
        | - Claude Haiku 4.5  |           |   fallback           |
        | - DeepL API         |           +----------------------+
        | - Google Translate   |                    |
        +---------------------+           Speaker name detected
                    |                               |
             Translated text                        v
                    |                     +-------------------+
                    v                     | Speaker Profile   |
        +---------------------+           | Manager (local)   |
        | Subtitle Renderer   |           +-------------------+
        | (Cinema-style       |
        |  floating overlay)  |
        +---------------------+
```

**Why best-of-breed:**
- STT and Translation are fundamentally different workloads with different cost structures.
- The best STT provider (OpenAI Whisper/Transcribe with diarization) is not the cheapest translator.
- The cheapest translator (Gemini Flash-Lite) does not offer STT with diarization.
- Name extraction is a rare event (happens maybe 2-3 times per session) and can use a separate, more capable model or simple heuristics.

---

## 5. Recommended Architecture

### Tier 1: Default Configuration (Cheapest)

| Component | Provider | Est. Cost (60 hrs/month user) |
|-----------|----------|-------------------------------|
| STT + Diarization | OpenAI GPT-4o Transcribe w/ diarization | ~$10.80/month |
| Translation | Gemini 2.5 Flash-Lite | ~$0.36/month |
| Name Extraction | Local regex + GPT-4o-mini fallback | ~$0.01/month |
| **Total** | | **~$11.17/month** |

### Tier 2: Quality Configuration

| Component | Provider | Est. Cost (60 hrs/month user) |
|-----------|----------|-------------------------------|
| STT + Diarization | OpenAI GPT-4o Transcribe w/ diarization | ~$10.80/month |
| Translation | GPT-4o-mini or Claude Haiku 4.5 | ~$0.54-$4.32/month |
| Name Extraction | Claude Haiku 4.5 | ~$0.05/month |
| **Total** | | **~$11.39-$15.17/month** |

### Tier 3: Premium Configuration

| Component | Provider | Est. Cost (60 hrs/month user) |
|-----------|----------|-------------------------------|
| STT + Diarization | OpenAI GPT-4o Transcribe w/ diarization | ~$10.80/month |
| Translation | Claude Sonnet 4.5 or GPT-4o | ~$9.00-$12.96/month |
| Name Extraction | Same model as translation | included |
| **Total** | | **~$19.80-$23.76/month** |

### Implementation Notes

1. **Provider abstraction layer:** Build a `TranslationProvider` protocol/interface so any provider can be swapped in. The app should ship with support for at least OpenAI, Google (Gemini + Cloud Translate), and optionally Anthropic and DeepL.

2. **Sentence buffering:** Do not translate word-by-word. Buffer the STT output into sentence-sized chunks (using punctuation detection or a short silence gap), then translate the full sentence. This reduces API calls and improves translation quality.

3. **Translation caching:** Maintain a local LRU cache of recent translations. Common phrases in meetings repeat frequently.

4. **Streaming display vs. streaming API:** Even if the translation API returns a full sentence at once (like Google Translate or DeepL), the subtitle renderer can still animate the text word-by-word for the "cinema feel." Streaming from the LLM is a nice-to-have, not a requirement.

5. **Name extraction pipeline:** Run a lightweight regex check on every transcribed sentence. Patterns: `"I'm [Name]"`, `"My name is [Name]"`, `"call me [Name]"`, `"this is [Name]"`. Only call the LLM if the regex detects a potential name introduction but cannot confidently extract the name.

6. **Rate limiting and error handling:** All API calls should have retry logic with exponential backoff. If translation fails, show the original untranslated text (graceful degradation).

7. **User-provided API keys:** Since LiveTitles is open-source and free, users provide their own API keys. The app should have a clear setup wizard for entering keys and selecting preferred providers.

---

## 6. Sources

### OpenAI
- [OpenAI API Pricing](https://openai.com/api/pricing/)
- [OpenAI Realtime API - gpt-realtime](https://openai.com/index/introducing-gpt-realtime/)
- [Multi-Language One-Way Translation Cookbook](https://developers.openai.com/cookbook/examples/voice_solutions/one_way_translation_using_realtime_api/)
- [GPT-4o-mini Performance Analysis](https://artificialanalysis.ai/models/gpt-4o-mini)
- [OpenAI Audio Models Updates](https://developers.openai.com/blog/updates-audio-models/)
- [OpenAI Transcription Pricing](https://costgoat.com/pricing/openai-transcription)
- [GPT-4o-mini Pricing (2026)](https://pricepertoken.com/pricing-page/model/openai-gpt-4o-mini)

### Anthropic (Claude)
- [Anthropic API Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Claude Haiku 4.5 Announcement](https://www.anthropic.com/news/claude-haiku-4-5)
- [Claude Haiku 4.5 Performance Analysis](https://artificialanalysis.ai/models/claude-4-5-haiku)
- [Anthropic Latency Reduction Guide](https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/reduce-latency)
- [Claude Haiku 4.5 Pricing (2026)](https://pricepertoken.com/pricing-page/model/anthropic-claude-haiku-4.5)

### Google (Gemini)
- [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [Gemini 2.5 Flash-Lite GA Announcement](https://developers.googleblog.com/en/gemini-25-flash-lite-is-now-stable-and-generally-available/)
- [Gemini 2.5 Flash-Lite Performance](https://artificialanalysis.ai/models/gemini-2-5-flash-lite)
- [Gemini Live API Overview](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/live-api)
- [Gemini 3 Flash Announcement](https://blog.google/products/gemini/gemini-3-flash/)
- [Google Cloud Translation Pricing](https://cloud.google.com/translate/pricing)
- [Gemini API Rate Limits](https://ai.google.dev/gemini-api/docs/rate-limits)

### DeepL
- [DeepL API Plans](https://support.deepl.com/hc/en-us/articles/360021200939-DeepL-API-plans)
- [DeepL Voice API Launch (Feb 2026)](https://www.prnewswire.com/news-releases/deepl-launches-voice-api-for-real-time-speech-transcription-and-translation-enabling-instant-multilingual-communication-302675810.html)
- [DeepL Voice API Documentation](https://developers.deepl.com/api-reference/voice)
- [DeepL Supported Languages](https://developers.deepl.com/docs/resources/supported-languages)
- [DeepL Pricing Guide](https://www.eesel.ai/blog/deepl-pricing)

### Translation Quality & Comparisons
- [Best LLMs for Translation (2025)](https://www.getblend.com/blog/which-llm-is-best-for-translation/)
- [Best LLM for Translation (2026 Tested & Ranked)](https://nutstudio.imyfone.com/llm-tips/best-llm-for-translation)
- [AI API Pricing Comparison (2026)](https://intuitionlabs.ai/articles/ai-api-pricing-comparison-grok-gemini-openai-claude)
- [LLM Latency Benchmark by Use Cases (2026)](https://research.aimultiple.com/llm-latency-benchmark/)

### NER / Entity Extraction
- [GPT-NER: Named Entity Recognition via Large Language Models](https://aclanthology.org/2025.findings-naacl.239/)

### Open Source / Cost Optimization
- [LibreTranslate](https://libretranslate.com/)
- [Open-Source Translation Models for Mobile & Embedded (2025)](https://picovoice.ai/blog/open-source-translation/)
- [Best Free Translation APIs (2026)](https://langbly.com/blog/best-free-translation-api-2026)
