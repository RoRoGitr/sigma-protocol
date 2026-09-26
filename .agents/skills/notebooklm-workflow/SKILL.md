---
name: notebooklm-workflow
description: "Convert documents to optimized NotebookLM format for AI podcast generation — angle selection, conversational structure, and upload workflow"
triggers:
  - notebooklm
  - podcast
  - audio-overview
  - audio
---

# NotebookLM Workflow Skill

Convert any document into optimized NotebookLM format for AI podcast (Audio Overview) generation. Covers content restructuring, angle selection, conversational formatting, and upload workflow.

## When to Invoke

- Converting a document for NotebookLM Audio Overview
- Structuring content for AI podcast generation
- Preparing multiple sources for a NotebookLM notebook
- Optimizing existing content for conversational format

---

## Conversion Process

### Step 1: Analyze Source Content

Read the source document and identify:
- **Main thesis**: What is the central argument or topic?
- **Key themes**: 3-5 major themes or sections
- **Discussion points**: What would two hosts debate or explore?
- **Interesting tensions**: Where are there disagreements, trade-offs, or surprises?
- **Data points**: Concrete numbers, examples, or case studies

### Step 2: Choose an Angle

| Angle | When to Use | What It Produces |
|-------|-------------|-----------------|
| **Deep Dive** | Technical docs, research papers | Thorough exploration, expert conversation |
| **Debate** | Strategy docs, decision analyses | Two perspectives arguing their case |
| **Interview** | How-to guides, tutorials | Q&A with an expert |
| **Story** | Case studies, retrospectives | Narrative with beginning/middle/end |
| **Comparison** | Tech evaluations, framework choices | Side-by-side analysis |
| **Explainer** | Complex concepts, academic papers | Break down into simple terms |

### Step 3: Restructure Content

Transform the document from reading format to conversation format:

**Reading format** (bad for audio):
```
## Section 1
Facts, data, bullet points...

## Section 2
More facts, tables, code...
```

**Conversation format** (good for audio):
```
## The Problem Nobody Talks About
[Start with a hook — why should the listener care?]

Worth noting: [interesting aside that hosts can explore]

The surprising part is... [build tension]

## What the Data Actually Shows
[Lead with the insight, not the methodology]

Here's where it gets interesting: [transition to next topic]
```

### Step 4: Format for NotebookLM

Apply these formatting rules:

#### Headers
- Use `##` headers as topic transitions (hosts naturally pause at these)
- Make headers conversational, not academic
- Bad: "3.2 Implementation Details"
- Good: "How They Actually Built It"

#### Bold Text
- Bold key terms and names (hosts will emphasize them)
- Bold surprising statistics or claims

#### Questions
- End sections with open questions — drives conversation forward
- "But does this actually work in practice?"
- "The real question is: who benefits?"

#### Callouts
- Use "Worth noting:" prefix for interesting asides
- Hosts love these as natural tangents

#### Length
- Sweet spot: 3,000-5,000 words per source
- Minimum: 2,000 words (shorter produces thin conversations)
- Maximum: 10,000 words (longer should be split)

---

## Output Template

```markdown
# [Topic Title] — NotebookLM Source

## Overview
[2-3 sentences framing the topic — this sets the tone for the entire conversation]

## [First Discussion Topic]
[Lead with the most interesting or surprising aspect]

**Key insight**: [the main takeaway from this section]

Worth noting: [interesting aside or counterpoint]

[Transition question or statement to next topic]

## [Second Discussion Topic]
[Continue the conversation flow]

The data shows... [concrete evidence]

But here's the tension: [introduce complexity]

## [Third Discussion Topic]
[Build toward the most impactful point]

## Interesting Angles to Explore
- [Provocative question that could spark debate]
- [Connection to a current trend]
- [Surprising implication of the findings]

## Context & Background
[Supporting information the hosts might reference]
[Definitions, statistics, or historical context]

---
*Formatted for NotebookLM Audio Overview*
*Upload to: notebooklm.google.com → New Notebook → Add Source*
```

---

## What NotebookLM Does Well

- Natural conversation between two hosts about your content
- Exploring different angles and perspectives
- Making technical content accessible
- Highlighting surprising or interesting findings
- Creating engaging "podcast-style" audio

## What NotebookLM Struggles With

| Avoid | Why | Instead |
|-------|-----|---------|
| Dense tables | Hosts can't read tables aloud naturally | Convert to narrative comparisons |
| Code blocks | Can't meaningfully discuss syntax | Describe what the code does conceptually |
| Excessive bullet lists | Sounds like reading a grocery list | Convert to flowing paragraphs |
| Jargon without context | Hosts trip over undefined terms | Define terms inline |
| Very long documents | Conversation loses focus | Split into multiple sources |
| Images/diagrams | Audio-only format | Describe visual concepts in words |

## Multi-Source Notebooks

When combining multiple documents:

1. **Identify overlaps**: Remove redundant content across sources
2. **Ensure variety**: Each source should cover a distinct angle
3. **Order matters**: NotebookLM weights earlier sources more
4. **Add bridges**: Include transitional content that connects sources
5. **Stay under limits**: 50 sources max, 500K characters per source

## Upload Instructions

### Manual Upload (Consumer Tier)

1. Go to https://notebooklm.google.com
2. Click "New Notebook"
3. Click "Add Source" → "Upload" → select your `.md` file
4. Wait for processing (1-2 minutes per source)
5. Click "Audio Overview" → "Generate"
6. Wait for generation (5-15 minutes depending on source length)
7. Play or download the generated audio

### Automated Upload (Optional)

If `notebooklm-py` is installed:

```python
from notebooklm import NotebookLM

nlm = NotebookLM()
notebook = nlm.create_notebook("My Topic")
notebook.add_source("path/to/formatted-doc.md")
overview = notebook.generate_audio_overview()
overview.download("output.mp3")
```

Note: This uses the unofficial `teng-lin/notebooklm-py` library. It may break with Google API changes.
