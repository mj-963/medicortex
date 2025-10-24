# PubMed Data Ingestion

This script fetches medical articles from PubMed and indexes them into Elasticsearch for MediCortex.

## Quick Start

```bash
# Run the script (takes 30-60 minutes)
python3 scripts/ingest_pubmed.py
```

## What It Does

- Fetches ~7,000+ medical articles from PubMed
- Covers 17 diverse medical topics:
  - Chronic diseases (diabetes, hypertension, cardiovascular)
  - Mental health (anxiety, depression, PTSD)
  - Common conditions (migraine, asthma, arthritis)
  - Infectious diseases (COVID-19, influenza)
  - Nutrition & lifestyle (intermittent fasting, diet, exercise)
  - Preventive care (screening, vaccination)

- Only indexes articles with abstracts (high quality)
- Rate-limited to 3 requests/second (free tier, no API key needed)
- Shows progress in real-time
- Can be interrupted and resumed

## Expected Output

```
======================================================================
  MediCortex - PubMed Data Ingestion
  Fetching medical literature for AI-powered search
======================================================================

📊 Checking current index status...
   Current document count: 1

📚 Will fetch articles for 17 medical topics
   Target: ~7,100 articles
   Rate limit: 3 requests/second

Start ingestion? [Y/n]: Y

🚀 Starting ingestion...

[  5.9%] Topic 1/17: diabetes mellitus type 2[Title/Abstract...
         Found 800 PMIDs
         Fetched 623 complete articles
         Indexed: 623, Errors: 0

[11.8%] Topic 2/17: hypertension[Title/Abstract] AND (tre...
         Found 600 PMIDs
         Fetched 487 complete articles
         Indexed: 487, Errors: 0

...

======================================================================
  ✅ Ingestion Complete!
======================================================================
  Total articles indexed: 6,847
  Errors: 0
  Time elapsed: 42.3 minutes
  Final index count: 6,848 documents
======================================================================

🎉 Your MediCortex index is ready for search!
```

## Time Estimate

- **With free tier (3 req/sec):** 30-60 minutes
- **With API key (10 req/sec):** 10-20 minutes

## Getting a PubMed API Key (Optional)

For faster ingestion, get a free API key:
1. Go to https://www.ncbi.nlm.nih.gov/account/
2. Register (free)
3. Get API key from settings
4. Edit `ingest_pubmed.py` line 21: `API_KEY = "your_key_here"`

## Troubleshooting

**Script fails with connection error:**
- Check internet connection
- Verify Elasticsearch endpoint is accessible
- API key might have expired (get new one)

**Script interrupted:**
- Just run it again! Already-indexed articles won't be duplicated (same PMID)

**Too slow:**
- Get a PubMed API key (10x faster)
- Reduce article counts in MEDICAL_TOPICS list

**Want more articles:**
- Edit MEDICAL_TOPICS in the script
- Add more topics or increase max_results

## Notes

- PubMed API is free and doesn't require authentication
- Only articles with abstracts are indexed (better quality)
- Duplicates are automatically handled (PMID is unique ID)
- You can interrupt and resume anytime (Ctrl+C)
