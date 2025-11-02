# MediCortex 🧠

**Stop Being Scared of WebMD - Get Real Medical Answers, With Citations**

> Built for LuminHacks 2025 | Powered by Google Gemini & Vertex AI

You know that feeling when you Google a symptom and suddenly think you're dying? Yeah, I got tired of that too. So I built MediCortex - an AI assistant that answers medical questions using **actual peer-reviewed research** instead of random internet articles.

🌐 **[Try It Live](http://medicortex.appwrite.network/)** | 🎥 **[Watch Demo (3 min)](https://youtu.be/fvXn2LLjlIQ)**

![MediCortex Demo](docs/images/main_ui.png)

---

## 💡 The Problem

Let's be real - finding trustworthy medical information online is a mess:

- **WebMD scares you to death** with worst-case scenarios
- **Research papers are locked behind paywalls** or written in impossible jargon
- **AI chatbots hallucinate** medical facts without any sources
- **You can't trust what's real** and what's made up

I wanted something that actually **shows its work** - like a good math teacher, but for medical research.

---

## ✨ What MediCortex Does

MediCortex is like having a medical librarian who's read 50,000+ research papers and can instantly find answers to your questions - **with citations for every single claim**.

### Here's how it works:

1. **You ask a medical question** (anything from "What helps with migraines?" to "Latest research on cancer treatment")
2. **AI searches 50,000+ PubMed articles** using smart hybrid search (finds exact terms + understands meaning)
3. **Gemini reads the papers and writes an answer** - but here's the catch: it can ONLY use info from those papers
4. **Every fact has a citation** - click any [PMID: xxx] to verify on PubMed yourself

**No hallucinations. No guessing. Just real research.**

### Cool Features

🔍 **Smart Search** - Combines vector embeddings (768 dimensions!) with keyword matching to find the most relevant papers

🤖 **AI That Shows Its Work** - Using Google Gemini with a custom RAG pipeline that forces citations

📚 **One-Click Synthesis** - Select multiple papers and AI will identify where researchers agree vs. debate

⚖️ **Compare Studies** - Side-by-side analysis of different research approaches

💡 **Extract Insights** - Get the key takeaways from multiple papers instantly

📱 **Works Everywhere** - Web, macOS, Windows, Linux (built with Flutter)

---

## 🎯 Why I Built This (LuminHacks Submission)

**The Goal:** Make AI accessible for solving real problems - in this case, health literacy.

I wanted to show that AI isn't just for experts. Anyone can:
- Use Google's Gemini API to build something useful
- Combine multiple AI models (Gemini + Vertex AI embeddings)
- Create tools that help real people with real problems

**Privacy First:** You can run this with your own API keys. No data collection, no tracking. Your medical questions stay between you and the AI.

---

## 🚀 Try It Yourself

### Quick Start (5 minutes)

1. **Clone the repo**
   ```bash
   git clone https://github.com/mj-963/medicortex.git
   cd medicortex
   ```

2. **Get your free API keys** (both have generous free tiers)
   - [Google Gemini API](https://aistudio.google.com/app/apikey) - For the AI responses
   - [Elasticsearch Cloud](https://cloud.elastic.co/) - For search (free 14-day trial)
   - [Vertex AI](https://console.cloud.google.com/vertex-ai) - For embeddings (300 free credits)

3. **Set up environment**
   ```bash
   cp env.example.json env.json
   # Edit env.json with your API keys
   ```

4. **Install and run**
   ```bash
   flutter pub get
   flutter run -d chrome  # or macos, windows, linux
   ```

5. **Optional: Index your own data**
   ```bash
   python3 scripts/ingest_pubmed_enhanced.py
   ```
   This grabs 50K articles from PubMed and indexes them (takes ~90 minutes)

---

## 🛠️ How It Actually Works (The Technical Bits)

### The AI Stack

**Google Gemini** - The brain that reads papers and writes answers
- Uses function calling to search papers
- Custom system prompt forces citation of sources
- Streaming responses for that instant-feedback feel

**Vertex AI Embeddings** - The semantic understanding
- Converts text into 768-dimensional vectors
- Lets us find papers that *mean* the same thing, not just match keywords
- Model: `text-embedding-004`

**Elasticsearch** - The search engine
- Hybrid search combining vector similarity + keyword matching
- Using Reciprocal Rank Fusion (RRF) to merge results
- Indexes 50K+ PubMed articles with full abstracts

### The RAG Pipeline

RAG = Retrieval-Augmented Generation (fancy way of saying "look it up first, then answer")

```dart
// 1. User asks question
"What are the latest treatments for diabetes?"

// 2. Generate embedding (Vertex AI)
final embedding = await vertexAI.embed(question);

// 3. Hybrid search (Elasticsearch)
final papers = await elastic.hybridSearch(
  query: question,
  embedding: embedding,
  size: 5
);

// 4. Build context with papers
final context = buildContext(papers);

// 5. Ask Gemini with strict instructions
final answer = await gemini.generate(
  "Based ONLY on these papers: $context\n\nQuestion: $question"
);

// Result: Answer with [PMID: xxx] citations
```

### Why This Approach Works

1. **No Hallucinations** - AI can only use info from the papers we give it
2. **Verifiable** - Every citation links to actual PubMed papers
3. **Comprehensive** - Searches both meaning (vectors) and exact terms (keywords)
4. **Fast** - Sub-second search through 50K articles
5. **Scalable** - Could easily handle millions of papers

---

## 📊 What's Inside

### Data
- **50,000+ PubMed articles** covering major medical topics
- Chronic diseases, cancer, mental health, neurology, infectious diseases
- Each article has title, abstract, authors, publication date
- Plus 768-dim vector embedding for semantic search

### Tech Stack

**Frontend**
- Flutter (cross-platform UI)
- Material Design 3
- Markdown rendering with syntax highlighting
- Riverpod for state management

**AI/ML**
- Google Gemini API (gemini-flash-latest)
- Vertex AI text-embedding-004
- Custom RAG implementation
- Function calling for tool orchestration

**Backend**
- Elasticsearch 8.x with hybrid search
- Appwrite Functions (serverless proxy for web)
- Clean Architecture pattern

**Languages**
- Dart (main app)
- Python (data ingestion scripts)

---

## 🎓 What I Learned Building This

### AI Integration Challenges

1. **RAG is harder than it looks** - You need good prompt engineering to prevent hallucinations
2. **Context windows are real** - Can't just dump 50 papers into Gemini. Had to learn ranking and truncation.
3. **Function calling is powerful** - Let Gemini decide when to search, what to search for
4. **Embeddings are magical** - 768 numbers that capture *meaning*? Mind blown.

### Technical Wins

1. **Hybrid search > pure vector search** - Medical terms need exact matching + semantic understanding
2. **Clean architecture pays off** - Easy to test, easy to change
3. **Flutter is amazing for cross-platform** - One codebase, runs everywhere
4. **Citations build trust** - Users actually click through to verify. Transparency matters.

### Surprises

1. **PubMed API is generous** - Free access to millions of papers!
2. **Vector similarity actually works** - "diabetes treatment" finds "insulin therapy" even though words don't match
3. **Users want synthesis** - Not just search results, but "what do these papers agree on?"
4. **Medical disclaimers are important** - This is education, not medical advice!

---

## 🏆 LuminHacks Judging Criteria

### ✅ Functionality
- Fully working web app + desktop apps
- Robust AI integration (handles errors gracefully)
- Scalable architecture (could handle millions of papers)
- All features tested end-to-end

### ✅ Purpose
- Solves real problem: medical misinformation
- Makes research accessible to everyone
- Enables new possibility: verified AI medical Q&A
- Previously difficult: synthesizing multiple studies

### ✅ Innovation & Creativity
- Unique: RAG pipeline with forced citations
- Creative: Hybrid search combining multiple AI approaches
- Wow factor: 50K+ papers searched in <1 second

### ✅ User Experience
- Intuitive chat interface (like ChatGPT but better)
- Clear citations (click to verify)
- Accessible to beginners (plain language)
- Works for experts too (full paper abstracts)

### ✅ Technical Execution
- Well documented (see code comments)
- Maintainable (clean architecture)
- Privacy-conscious (run with your own keys)
- Performance optimized (streaming, caching)

---

## 🔐 Privacy & Safety

**Medical Disclaimer:** I'm not a doctor, and MediCortex isn't medical advice. It's a research tool. Always consult real healthcare professionals for medical decisions.

**Privacy:**
- No data collection or telemetry
- Runs locally with your API keys
- Your questions never stored
- All API calls use your own credentials

**Open Source:**
- MIT License - use it however you want
- All code on GitHub
- Welcome to fork, modify, improve!

---

## 🚀 What's Next

If this project does well, I want to:

1. **Add more data sources** - Clinical trials, medical guidelines, drug databases
2. **Image understanding** - Search medical imaging papers
3. **Multi-language** - Translate papers to any language
4. **Mobile apps** - Native iOS/Android
5. **API access** - Let other apps integrate MediCortex

---

## 🎥 Demo & Live App

**🌐 Try It Live:** http://medicortex.appwrite.network/

**🎥 Watch Demo (3 min):** https://youtu.be/fvXn2LLjlIQ

The demo shows:
- Real-time search across 50K papers
- AI answering with citations
- Quick actions (synthesize, compare, insights)
- How the hybrid search finds relevant papers
- The "wow" moment when you click a citation and see the real paper

---

## 🤝 Acknowledgments

Built for **LuminHacks 2025**

Thanks to:
- **Google** - Gemini API and Vertex AI make this possible
- **Elastic** - Hybrid search is incredible
- **PubMed/NCBI** - Free access to medical research
- **Flutter community** - Amazing framework and support

Special shoutout to anyone who's ever been scared by WebMD. This is for you. 😄

---

## 📫 Questions?

- **Live App** - http://medicortex.appwrite.network/
- **Demo Video** - https://youtu.be/fvXn2LLjlIQ
- **GitHub Issues** - Best way to report bugs or ask questions
- **Code** - You're looking at it!

---

**Built with ❤️ and too much coffee**

*Because medical information should be accurate AND accessible.*

---

**⚠️ Important:** MediCortex is an educational tool, not a medical device. It provides information from research papers but is not a substitute for professional medical advice, diagnosis, or treatment. Always consult qualified healthcare providers with medical questions.
