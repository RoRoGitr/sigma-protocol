---
name: youtube-transcription
description: "Transcribe YouTube videos using yt-dlp + Whisper, extract captions, and generate executive summaries with timestamps"
triggers:
  - transcript
  - youtube
  - video
  - transcribe
---

# YouTube Transcription Skill

Extract, transcribe, and analyze YouTube video content. Produces full transcripts with timestamps, executive summaries, key takeaways, and content angles for derivative work.

## When to Invoke

- Transcribing a YouTube video for research
- Extracting key insights from video content
- Creating written summaries from video sources
- Building a research corpus from video content
- Generating content ideas from existing videos

---

## Transcription Pipeline

### Method 1: YouTube Captions (Fastest)

```bash
# Download auto-generated captions
yt-dlp --write-auto-sub --sub-lang en --skip-download -o "%(title)s" "VIDEO_URL"

# Download manual captions (higher quality if available)
yt-dlp --write-sub --sub-lang en --skip-download -o "%(title)s" "VIDEO_URL"

# List available subtitles
yt-dlp --list-subs "VIDEO_URL"
```

**Pros**: Fast, no local compute needed
**Cons**: Auto-captions have errors, not all videos have captions

### Method 2: Whisper Transcription (Most Accurate)

```bash
# Download audio only
yt-dlp -x --audio-format mp3 --audio-quality 0 -o "audio.mp3" "VIDEO_URL"

# Transcribe with Whisper
whisper audio.mp3 --model medium --language en --output_format txt

# Or with timestamps
whisper audio.mp3 --model medium --language en --output_format vtt
```

**Pros**: Highest accuracy, works on any video
**Cons**: Requires local Whisper install, slower

### Method 3: Whisper via Python API

```python
import whisper

model = whisper.load_model("medium")
result = model.transcribe("audio.mp3")

# Full text
print(result["text"])

# With segments (timestamps)
for segment in result["segments"]:
    print(f"[{segment['start']:.1f}s] {segment['text']}")
```

### Fallback Chain

```
1. Try manual captions (--write-sub) → highest quality
2. Try auto-captions (--write-auto-sub) → fast, decent quality
3. Download audio + Whisper → most accurate, slowest
4. If Whisper not installed → inform user, offer to install
```

## Video Metadata Extraction

```bash
# Get video metadata as JSON
yt-dlp --dump-json "VIDEO_URL"

# Key fields:
# - title, description, upload_date, duration
# - channel, channel_id, view_count, like_count
# - tags, categories, chapters
```

### Chapter Extraction

Many YouTube videos have chapters. Extract them for structured transcripts:

```bash
yt-dlp --dump-json "VIDEO_URL" | jq '.chapters'
```

Use chapters as section headers in the transcript output.

## Output Format

### File Location

```
docs/research/transcripts/YYYY-MM-DD-youtube-[slug].md
```

### Standard Template

```markdown
# [Video Title]

**Source**: [YouTube URL]
**Channel**: [Channel Name]
**Duration**: [HH:MM:SS]
**Published**: [Date]
**Views**: [Count]
**Date Transcribed**: [YYYY-MM-DD]
**Method**: [Captions/Whisper]

---

## Executive Summary
[3-5 sentences capturing the essential message of the video]

## Key Takeaways
1. **[Takeaway]** — [timestamp] [brief explanation]
2. **[Takeaway]** — [timestamp] [brief explanation]
3. **[Takeaway]** — [timestamp] [brief explanation]

## Notable Quotes
> "[Exact quote]" — [Speaker] at [timestamp]

> "[Exact quote]" — [Speaker] at [timestamp]

## Chapter Breakdown
### [Chapter 1 Title] ([start] - [end])
[Summary of this section]

### [Chapter 2 Title] ([start] - [end])
[Summary of this section]

## Full Transcript
[Complete transcript with timestamps]

## Suggested Action Items
- [ ] [Action inspired by the content]
- [ ] [Action inspired by the content]

## Content Angles
- [Idea for derivative content]
- [Idea for derivative content]
- [Idea for derivative content]
```

## Tool Installation

### yt-dlp

```bash
# macOS
brew install yt-dlp

# pip
pip install yt-dlp

# Verify
yt-dlp --version
```

### ffmpeg (required for audio extraction)

```bash
# macOS
brew install ffmpeg

# Verify
ffmpeg -version
```

### Whisper (optional, for local transcription)

```bash
# OpenAI Whisper
pip install openai-whisper

# Or faster whisper.cpp
brew install whisper-cpp

# Verify
whisper --help
```

## Best Practices

### Accuracy
- Prefer manual captions over auto-generated when available
- Use Whisper `medium` or `large` model for important content
- Cross-reference timestamps with video chapters
- Always note the transcription method used

### Efficiency
- Check for captions first (faster than downloading + transcribing)
- Use `--audio-quality 5` (instead of 0) for faster downloads when quality isn't critical
- Cache audio files for re-processing with different models

### Output Quality
- Always include an executive summary — readers need the quick take
- Timestamp key moments for easy reference
- Extract chapters if available — they structure the transcript naturally
- Include metadata (views, channel, date) for research context
