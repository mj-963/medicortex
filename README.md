# MediCortex

**AI Research System with Verified Knowledge Retrieval**

> Medical AI that cites every claim — no hallucinations, no guessing.

MediCortex answers medical questions by searching 50,000+ peer-reviewed PubMed papers in real time and grounding every response in what the research actually says. Every fact links to the source paper. Every answer is reproducible.

🌐 **[Try It Live](http://medicortex.appwrite.network/)** | 🎥 **[Watch Demo](https://youtu.be/fvXn2LLjlIQ)**

![MediCortex Demo](docs/images/main_ui.png)

---

## The Problem with Medical AI Today

General-purpose AI models are trained on internet text — which includes misinformation, outdated advice, and content that confidently states things that are simply wrong. In healthcare, that is not acceptable.

MediCortex takes a different approach: **the AI never generates claims it cannot back up with a source**. If the research doesn't support it, the answer says so.

---

## How It Works

MediCortex implements a RAG (Retrieval-Augmented Generation) pipeline purpose-built for scientific literature:

```
User Question
     │
     ▼
Vertex AI text-embedding-004
     │  768-dimensional query vector
     ▼
Qdrant Vector Search  ←──────── 50,000+ indexed PubMed abstracts
     │  Top-k semantically similar papers
     ▼
Context Assembly
     │  Title · Abstract · PMID · Authors · Year
     ▼
Google Gemini  (grounded prompt — citation required for every claim)
     │
     ▼
Answer with [PMID: xxx] citations → verifiable on PubMed
```

**The constraint is the point.** Gemini is instructed it may only use information from the retrieved papers. If the top results are weak, the answer reflects that uncertainty rather than fabricating a confident response.

---

## Features

| Feature | Description |
|---|---|
| **Cited Q&A** | Every factual claim links to its PubMed source — click any `[PMID]` to verify |
| **Semantic Search** | 768-dim vector embeddings find conceptually related papers, not just keyword matches |
| **Multi-Paper Synthesis** | Select several papers and get a structured analysis of where researchers agree and disagree |
| **Study Comparison** | Side-by-side breakdown of methodology, sample size, findings, and limitations |
| **Key Insight Extraction** | Distill the most actionable clinical findings from a set of papers |
| **Cross-Platform** | Flutter — runs on web, macOS, Windows, and Linux from a single codebase |

---

## Technical Architecture

### AI Stack

**Google Gemini** — Response generation with a grounding constraint system prompt that forces citation of all claims and flags when evidence is insufficient.

**Vertex AI `text-embedding-004`** — Converts both queries and documents into 768-dimensional semantic vectors. Uses separate task types (`RETRIEVAL_QUERY` vs `RETRIEVAL_DOCUMENT`) for optimized similarity scoring.

**Qdrant** — Vector database hosting 50,000+ article embeddings. Handles cosine similarity search for vector queries and payload text-index scroll for keyword fallback when embeddings are unavailable.

### RAG Pipeline

```dart
// 1. Embed the query
final embedding = await vertexAI.generateQueryEmbedding(question);

// 2. Retrieve the most relevant papers
final papers = await qdrant.hybridSearch(
  query: question,
  queryEmbedding: embedding,
  size: 5,
);

// 3. Build grounded context
final context = buildContext(papers); // title, abstract, PMID, year

// 4. Generate with citation constraint
final answer = await gemini.generate(
  systemPrompt: "Answer ONLY using the papers below. Cite [PMID: x] for every claim.",
  context: context,
  question: question,
);
```

### Data

- **Source:** PubMed via NCBI E-utilities (free, public API)
- **Scale:** 50,000+ articles across 100+ medical topics
- **Fields:** PMID, title, abstract, authors, publication date, journal, article type
- **Vectors:** 768-dim Vertex AI embeddings, indexed in Qdrant with cosine similarity
- **Coverage:** Chronic disease, oncology, mental health, neurology, infectious disease, autoimmune, respiratory, nutrition, preventive care, pediatrics, women's health, geriatrics, precision medicine, emerging therapies

### Stack

| Layer | Technology |
|---|---|
| UI | Flutter · Material Design 3 · Riverpod |
| AI | Google Gemini API · Vertex AI Embeddings |
| Search | Qdrant Cloud (vector DB) |
| Proxy | Appwrite Functions (CORS handling for web) |
| Ingestion | Python · NCBI E-utilities · google-auth |
| Architecture | Clean Architecture · Repository pattern |

---

## Self-Hosting

### Prerequisites

- Flutter SDK
- Google Cloud project with Gemini API and Vertex AI enabled
- Qdrant Cloud account (free tier supports this dataset)
- Appwrite account (for web deployment proxy)

### Setup

```bash
git clone https://github.com/mj-963/medicortex.git
cd medicortex

cp env.example.json env.json
# Fill in: qdrant, vertex_ai, service_account, gemini_api_key
```

### Run

```bash
flutter pub get
flutter run --dart-define-from-file=env.json -d chrome
```

### Index Data

```bash
pip install requests google-auth
python scripts/ingest_pubmed_enhanced.py        # ~50k articles, with Vertex AI embeddings
python scripts/ingest_pubmed_enhanced.py --no-embed   # faster, keyword search only
```

The ingestion script is resumable — if interrupted, re-running skips already-indexed articles.

---

## Design Decisions

**Why RAG instead of fine-tuning?**
Fine-tuning bakes knowledge into weights that go stale. RAG retrieves live knowledge from a corpus that can be updated, audited, and cited. For a medical system, auditability is not optional.

**Why Qdrant?**
Qdrant is purpose-built for vector search with a clean REST API and a free cloud tier that handles this dataset comfortably. It replaced an earlier Elasticsearch implementation when the managed ES subscription ended.

**Why force citations in the prompt?**
Without a hard constraint, LLMs blend retrieved facts with training-set knowledge in ways that are invisible to the user. The citation constraint makes the grounding verifiable — you can check every claim against its source.

**Why 768 dimensions?**
Vertex AI `text-embedding-004` at 768 dims balances retrieval quality with storage cost. Qdrant's free tier holds this corpus at full precision.

---

## Limitations

- Answers are bounded by what is in the indexed corpus. If a topic is underrepresented in the dataset, retrieval quality suffers.
- Abstract-level search: full paper text is not indexed, only abstracts. Some nuance is lost.
- This is a research and education tool. It is not a medical device and does not provide medical advice.

---

## License

MIT — fork, extend, deploy.

---

**⚠️ MediCortex is an educational tool, not a substitute for professional medical advice. Always consult a qualified healthcare provider for medical decisions.**
