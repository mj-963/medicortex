#!/usr/bin/env python3
"""
PubMed Data Ingestion Script for MediCortex

Fetches medical articles from PubMed API and indexes them into Elasticsearch.
Free to use - no API key required (3 requests/second limit).
"""

import requests
import time
import json
from datetime import datetime
from typing import List, Dict, Optional
import xml.etree.ElementTree as ET
import sys
import os
from pathlib import Path

# ========== LOAD CONFIGURATION FROM env.json ==========

def load_config():
    """Load configuration from env.json file"""
    # Look for env.json in parent directory (project root)
    script_dir = Path(__file__).parent
    env_path = script_dir.parent / 'env.json'
    
    if not env_path.exists():
        print("❌ Error: env.json not found!")
        print(f"   Expected location: {env_path}")
        print(f"   Please copy env.example.json to env.json and configure your credentials.")
        sys.exit(1)
    
    try:
        with open(env_path, 'r') as f:
            config = json.load(f)
        return config
    except Exception as e:
        print(f"❌ Error loading env.json: {e}")
        sys.exit(1)

# Load configuration
CONFIG = load_config()

# Elasticsearch configuration
ELASTICSEARCH_URL = CONFIG['elasticsearch']['endpoint']
ES_API_KEY = CONFIG['elasticsearch']['apiKey']
ES_INDEX = CONFIG['elasticsearch']['index']

# PubMed configuration
PUBMED_API_BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
EMAIL = CONFIG['pubmed']['email']
API_KEY = CONFIG['pubmed'].get('apiKey')  # Optional

# Rate limiting (requests per second)
REQUESTS_PER_SECOND = 3 if not API_KEY else 10
DELAY = 1.0 / REQUESTS_PER_SECOND

# Medical topics to fetch articles for
MEDICAL_TOPICS = [
    # Chronic diseases (high priority)
    ("diabetes mellitus type 2[Title/Abstract] AND (treatment OR management)", 800),
    ("hypertension[Title/Abstract] AND (treatment OR management)", 600),
    ("cardiovascular disease[Title/Abstract] AND prevention", 500),
    ("cancer immunotherapy[Title/Abstract]", 400),

    # Mental health (important for demo)
    ("anxiety disorder[Title/Abstract] AND (treatment OR therapy)", 500),
    ("depression[Title/Abstract] AND (cognitive behavioral therapy OR medication)", 500),
    ("post traumatic stress disorder[Title/Abstract] AND treatment", 300),

    # Common conditions
    ("migraine headache[Title/Abstract] AND treatment", 400),
    ("asthma[Title/Abstract] AND management", 300),
    ("arthritis rheumatoid[Title/Abstract] AND treatment", 300),

    # Infectious diseases
    ("covid-19[Title/Abstract] AND (treatment OR vaccine)", 400),
    ("influenza[Title/Abstract] AND vaccination", 300),

    # Nutrition and lifestyle
    ("intermittent fasting[Title/Abstract] AND (weight loss OR diabetes)", 300),
    ("mediterranean diet[Title/Abstract] AND health", 300),
    ("exercise[Title/Abstract] AND cardiovascular health", 300),

    # Preventive care
    ("screening[Title/Abstract] AND (cancer OR cardiovascular)", 400),
    ("vaccination[Title/Abstract] AND efficacy", 300),
]

# ========== ELASTICSEARCH CLIENT ==========

class ElasticsearchClient:
    def __init__(self):
        self.url = ELASTICSEARCH_URL
        self.headers = {
            'Authorization': f'ApiKey {ES_API_KEY}',
            'Content-Type': 'application/json'
        }
        self.indexed_count = 0
        self.error_count = 0

    def index_documents(self, documents: List[Dict]) -> Dict:
        """Bulk index documents"""
        if not documents:
            return {'indexed': 0, 'errors': 0}

        # Build NDJSON for bulk API
        ndjson_lines = []
        for doc in documents:
            pmid = doc.get('pmid')
            if not pmid:
                continue

            # Index action
            ndjson_lines.append(json.dumps({'index': {'_index': ES_INDEX, '_id': pmid}}))
            # Document
            ndjson_lines.append(json.dumps(doc))

        ndjson = '\n'.join(ndjson_lines) + '\n'

        # Send bulk request
        response = requests.post(
            f"{self.url}/_bulk",
            headers={**self.headers, 'Content-Type': 'application/x-ndjson'},
            data=ndjson
        )

        if response.status_code == 200:
            result = response.json()
            has_errors = result.get('errors', False)

            if has_errors:
                items = result.get('items', [])
                indexed = sum(1 for item in items if 'error' not in item.get('index', {}))
                errors = len(items) - indexed
                self.indexed_count += indexed
                self.error_count += errors
                return {'indexed': indexed, 'errors': errors}
            else:
                self.indexed_count += len(documents)
                return {'indexed': len(documents), 'errors': 0}
        else:
            self.error_count += len(documents)
            print(f"❌ Bulk index failed: {response.status_code}")
            print(f"   Response: {response.text[:200]}")
            return {'indexed': 0, 'errors': len(documents)}

    def get_stats(self) -> Dict:
        """Get index statistics"""
        try:
            response = requests.get(
                f"{self.url}/{ES_INDEX}/_stats",
                headers=self.headers
            )
            if response.status_code == 200:
                data = response.json()
                indices = data.get('indices', {})
                index_data = indices.get(ES_INDEX, {})
                total = index_data.get('total', {})
                docs = total.get('docs', {})
                return {
                    'count': docs.get('count', 0),
                    'deleted': docs.get('deleted', 0)
                }
        except Exception as e:
            print(f"⚠️  Failed to get stats: {e}")
        return {'count': 0, 'deleted': 0}

# ========== PUBMED CLIENT ==========

class PubMedClient:
    def __init__(self):
        self.session = requests.Session()
        self.total_articles_fetched = 0

    def search(self, query: str, max_results: int = 1000) -> List[str]:
        """Search PubMed and return PMIDs"""
        params = {
            'db': 'pubmed',
            'term': query,
            'retmax': max_results,
            'retmode': 'json',
            'email': EMAIL,
        }
        if API_KEY:
            params['api_key'] = API_KEY

        try:
            response = self.session.get(f"{PUBMED_API_BASE}/esearch.fcgi", params=params)
            time.sleep(DELAY)

            if response.status_code == 200:
                data = response.json()
                pmids = data.get('esearchresult', {}).get('idlist', [])
                return pmids
            else:
                print(f"❌ Search failed: {response.status_code}")
                return []
        except Exception as e:
            print(f"❌ Search error: {e}")
            return []

    def fetch_details(self, pmids: List[str]) -> List[Dict]:
        """Fetch article details for PMIDs"""
        if not pmids:
            return []

        articles = []
        batch_size = 200  # PubMed allows up to 200 IDs per request

        for i in range(0, len(pmids), batch_size):
            batch = pmids[i:i+batch_size]
            params = {
                'db': 'pubmed',
                'id': ','.join(batch),
                'retmode': 'xml',
                'email': EMAIL,
            }
            if API_KEY:
                params['api_key'] = API_KEY

            try:
                response = self.session.get(f"{PUBMED_API_BASE}/efetch.fcgi", params=params)
                time.sleep(DELAY)

                if response.status_code == 200:
                    batch_articles = self._parse_xml(response.text)
                    articles.extend(batch_articles)
                    self.total_articles_fetched += len(batch_articles)
                else:
                    print(f"❌ Fetch failed: {response.status_code}")
            except Exception as e:
                print(f"❌ Fetch error: {e}")
                continue

        return articles

    def _parse_xml(self, xml_text: str) -> List[Dict]:
        """Parse PubMed XML into structured data"""
        articles = []

        try:
            root = ET.fromstring(xml_text)
        except ET.ParseError as e:
            print(f"❌ XML parse error: {e}")
            return []

        for article in root.findall('.//PubmedArticle'):
            try:
                # Extract PMID
                pmid_elem = article.find('.//PMID')
                if pmid_elem is None:
                    continue
                pmid = pmid_elem.text

                # Extract title
                title_elem = article.find('.//ArticleTitle')
                title = ''.join(title_elem.itertext()) if title_elem is not None else ''

                # Extract abstract
                abstract_parts = article.findall('.//AbstractText')
                abstract = ' '.join([''.join(part.itertext()) for part in abstract_parts])

                # Skip if no abstract (we want high-quality articles)
                if not abstract:
                    continue

                # Extract publication date
                pub_date = article.find('.//PubDate')
                date_str = self._extract_date(pub_date)

                # Extract authors
                authors = []
                for author in article.findall('.//Author'):
                    last = author.find('.//LastName')
                    first = author.find('.//ForeName')
                    if last is not None:
                        name = last.text
                        if first is not None:
                            name = f"{first.text} {name}"
                        authors.append(name)

                # Extract article type
                pub_types = article.findall('.//PublicationType')
                article_types = [pt.text for pt in pub_types if pt.text]

                # Build document
                doc = {
                    'pmid': pmid,
                    'title': title,
                    'abstract': abstract,
                    'content': f"{title} {abstract}",  # Combined for search
                    'publication_date': date_str,
                    'authors': authors[:10],  # Limit to 10 authors
                    'article_type': article_types[0] if article_types else 'Article',
                    'source_url': f"https://pubmed.ncbi.nlm.nih.gov/{pmid}/",
                    'indexed_at': datetime.now().isoformat(),
                }

                articles.append(doc)

            except Exception as e:
                print(f"⚠️  Error parsing article: {e}")
                continue

        return articles

    def _extract_date(self, pub_date) -> Optional[str]:
        """Extract publication date from PubMed XML"""
        if pub_date is None:
            return None

        year = pub_date.find('Year')
        month = pub_date.find('Month')
        day = pub_date.find('Day')

        if year is not None:
            y = year.text
            m = month.text if month is not None else '01'
            d = day.text if day is not None else '01'

            # Convert month name to number
            months = {
                'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
                'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
                'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
            }
            m = months.get(m, m)

            try:
                # Ensure proper formatting
                m = m.zfill(2) if m.isdigit() else '01'
                d = d.zfill(2) if d.isdigit() else '01'
                return f"{y}-{m}-{d}"
            except:
                return f"{y}-01-01"

        return None

# ========== MAIN INGESTION LOGIC ==========

def print_header():
    """Print welcome message"""
    print("=" * 70)
    print("  MediCortex - PubMed Data Ingestion")
    print("  Fetching medical literature for AI-powered search")
    print("=" * 70)
    print()

def print_progress(current: int, total: int, topic: str, articles: int):
    """Print progress update"""
    progress = (current / total) * 100
    print(f"[{progress:5.1f}%] Topic {current}/{total}: {topic[:40]}")
    print(f"         Found {articles} articles with abstracts")

def main():
    print_header()

    # Initialize clients
    es_client = ElasticsearchClient()
    pubmed_client = PubMedClient()

    # Check initial state
    print("📊 Checking current index status...")
    stats = es_client.get_stats()
    print(f"   Current document count: {stats['count']}")
    print()

    # Confirm start
    print(f"📚 Will fetch articles for {len(MEDICAL_TOPICS)} medical topics")
    total_target = sum(count for _, count in MEDICAL_TOPICS)
    print(f"   Target: ~{total_target:,} articles")
    print(f"   Rate limit: {REQUESTS_PER_SECOND} requests/second")
    print()

    response = input("Start ingestion? [Y/n]: ")
    if response.lower() == 'n':
        print("Cancelled.")
        return

    print("\n🚀 Starting ingestion...\n")
    start_time = time.time()

    # Process each topic
    for idx, (query, max_results) in enumerate(MEDICAL_TOPICS, 1):
        print_progress(idx, len(MEDICAL_TOPICS), query, 0)

        # Search PubMed
        pmids = pubmed_client.search(query, max_results)

        if not pmids:
            print("   ⚠️  No results found")
            continue

        # Fetch article details
        articles = pubmed_client.fetch_details(pmids)
        print(f"         Fetched {len(articles)} complete articles")

        if articles:
            # Index into Elasticsearch
            result = es_client.index_documents(articles)
            print(f"         Indexed: {result['indexed']}, Errors: {result['errors']}")

        print()

    # Final statistics
    elapsed = time.time() - start_time
    print("\n" + "=" * 70)
    print("  ✅ Ingestion Complete!")
    print("=" * 70)
    print(f"  Total articles indexed: {es_client.indexed_count:,}")
    print(f"  Errors: {es_client.error_count}")
    print(f"  Time elapsed: {elapsed/60:.1f} minutes")

    # Get final stats
    final_stats = es_client.get_stats()
    print(f"  Final index count: {final_stats['count']:,} documents")
    print("=" * 70)
    print()
    print("🎉 Your MediCortex index is ready for search!")
    print()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
        print("Progress has been saved. You can run the script again to continue.")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
