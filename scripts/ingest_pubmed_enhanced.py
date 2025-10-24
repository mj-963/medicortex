#!/usr/bin/env python3
"""
Enhanced PubMed Data Ingestion Script for MediCortex
Fetches 50,000+ high-quality medical articles across diverse topics
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

# ========== LOAD CONFIGURATION ==========

def load_config():
    """Load configuration from env.json file"""
    script_dir = Path(__file__).parent
    env_path = script_dir.parent / 'env.original.json'
    
    if not env_path.exists():
        print("❌ Error: env.json not found!")
        sys.exit(1)
    
    try:
        with open(env_path, 'r') as f:
            config = json.load(f)
        return config
    except Exception as e:
        print(f"❌ Error loading env.json: {e}")
        sys.exit(1)

CONFIG = load_config()

# Elasticsearch configuration
ELASTICSEARCH_URL = CONFIG['elasticsearch']['endpoint']
ES_API_KEY = CONFIG['elasticsearch']['apiKey']
ES_INDEX = CONFIG['elasticsearch']['index']

# PubMed configuration
PUBMED_API_BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
EMAIL = CONFIG['pubmed']['email']
API_KEY = CONFIG['pubmed'].get('apiKey')

# Rate limiting
REQUESTS_PER_SECOND = 3 if not API_KEY else 10
DELAY = 1.0 / REQUESTS_PER_SECOND

# ========== EXPANDED MEDICAL TOPICS (50,000+ articles) ==========

MEDICAL_TOPICS = [
    # === CHRONIC DISEASES (8,000 articles) ===
    ("diabetes mellitus type 2[Title/Abstract] AND (treatment OR management)", 1000),
    ("diabetes mellitus type 1[Title/Abstract] AND (insulin OR therapy)", 600),
    ("hypertension[Title/Abstract] AND (treatment OR management)", 800),
    ("cardiovascular disease[Title/Abstract] AND prevention", 700),
    ("heart failure[Title/Abstract] AND treatment", 600),
    ("coronary artery disease[Title/Abstract] AND therapy", 500),
    ("chronic kidney disease[Title/Abstract] AND management", 600),
    ("chronic obstructive pulmonary disease[Title/Abstract] AND treatment", 600),
    ("stroke[Title/Abstract] AND (prevention OR treatment)", 700),
    ("atherosclerosis[Title/Abstract] AND therapy", 500),
    ("metabolic syndrome[Title/Abstract] AND management", 500),
    ("obesity[Title/Abstract] AND (treatment OR weight loss)", 900),
    
    # === CANCER (6,000 articles) ===
    ("cancer immunotherapy[Title/Abstract]", 800),
    ("breast cancer[Title/Abstract] AND treatment", 700),
    ("lung cancer[Title/Abstract] AND therapy", 600),
    ("colorectal cancer[Title/Abstract] AND treatment", 500),
    ("prostate cancer[Title/Abstract] AND therapy", 500),
    ("melanoma[Title/Abstract] AND immunotherapy", 400),
    ("leukemia[Title/Abstract] AND treatment", 500),
    ("lymphoma[Title/Abstract] AND therapy", 400),
    ("pancreatic cancer[Title/Abstract] AND treatment", 400),
    ("ovarian cancer[Title/Abstract] AND therapy", 400),
    ("targeted therapy[Title/Abstract] AND cancer", 600),
    ("chemotherapy[Title/Abstract] AND efficacy", 600),
    
    # === MENTAL HEALTH (5,000 articles) ===
    ("anxiety disorder[Title/Abstract] AND (treatment OR therapy)", 700),
    ("depression[Title/Abstract] AND (cognitive behavioral therapy OR medication)", 800),
    ("post traumatic stress disorder[Title/Abstract] AND treatment", 500),
    ("bipolar disorder[Title/Abstract] AND management", 500),
    ("schizophrenia[Title/Abstract] AND treatment", 500),
    ("attention deficit hyperactivity disorder[Title/Abstract] AND therapy", 500),
    ("autism spectrum disorder[Title/Abstract] AND intervention", 500),
    ("obsessive compulsive disorder[Title/Abstract] AND treatment", 400),
    ("eating disorders[Title/Abstract] AND therapy", 400),
    ("substance abuse[Title/Abstract] AND treatment", 500),
    
    # === INFECTIOUS DISEASES (4,500 articles) ===
    ("covid-19[Title/Abstract] AND (treatment OR vaccine)", 800),
    ("influenza[Title/Abstract] AND vaccination", 500),
    ("HIV[Title/Abstract] AND antiretroviral therapy", 600),
    ("tuberculosis[Title/Abstract] AND treatment", 500),
    ("malaria[Title/Abstract] AND therapy", 400),
    ("hepatitis C[Title/Abstract] AND treatment", 400),
    ("sepsis[Title/Abstract] AND management", 500),
    ("pneumonia[Title/Abstract] AND treatment", 500),
    ("urinary tract infection[Title/Abstract] AND therapy", 400),
    ("antibiotic resistance[Title/Abstract]", 600),
    
    # === NEUROLOGICAL DISORDERS (4,000 articles) ===
    ("Alzheimer disease[Title/Abstract] AND treatment", 700),
    ("Parkinson disease[Title/Abstract] AND therapy", 600),
    ("multiple sclerosis[Title/Abstract] AND treatment", 500),
    ("epilepsy[Title/Abstract] AND management", 500),
    ("migraine headache[Title/Abstract] AND treatment", 600),
    ("neuropathic pain[Title/Abstract] AND therapy", 400),
    ("dementia[Title/Abstract] AND management", 500),
    ("traumatic brain injury[Title/Abstract] AND treatment", 400),
    
    # === AUTOIMMUNE DISEASES (3,500 articles) ===
    ("rheumatoid arthritis[Title/Abstract] AND treatment", 600),
    ("systemic lupus erythematosus[Title/Abstract] AND therapy", 500),
    ("inflammatory bowel disease[Title/Abstract] AND treatment", 500),
    ("Crohn disease[Title/Abstract] AND therapy", 400),
    ("ulcerative colitis[Title/Abstract] AND treatment", 400),
    ("psoriasis[Title/Abstract] AND therapy", 500),
    ("multiple sclerosis[Title/Abstract] AND immunotherapy", 400),
    
    # === RESPIRATORY DISEASES (3,000 articles) ===
    ("asthma[Title/Abstract] AND management", 600),
    ("chronic obstructive pulmonary disease[Title/Abstract] AND therapy", 500),
    ("pulmonary fibrosis[Title/Abstract] AND treatment", 400),
    ("sleep apnea[Title/Abstract] AND therapy", 500),
    ("cystic fibrosis[Title/Abstract] AND treatment", 400),
    ("bronchitis[Title/Abstract] AND management", 400),
    
    # === NUTRITION & LIFESTYLE (3,500 articles) ===
    ("intermittent fasting[Title/Abstract] AND (weight loss OR diabetes)", 500),
    ("mediterranean diet[Title/Abstract] AND health", 500),
    ("ketogenic diet[Title/Abstract] AND (weight loss OR epilepsy)", 400),
    ("exercise[Title/Abstract] AND cardiovascular health", 500),
    ("physical activity[Title/Abstract] AND disease prevention", 500),
    ("vitamin D[Title/Abstract] AND health", 500),
    ("omega-3 fatty acids[Title/Abstract] AND cardiovascular", 400),
    
    # === PREVENTIVE MEDICINE (3,000 articles) ===
    ("screening[Title/Abstract] AND (cancer OR cardiovascular)", 600),
    ("vaccination[Title/Abstract] AND efficacy", 500),
    ("preventive medicine[Title/Abstract]", 500),
    ("health promotion[Title/Abstract]", 400),
    ("disease prevention[Title/Abstract]", 500),
    ("public health[Title/Abstract] AND intervention", 500),
    
    # === PEDIATRICS (2,500 articles) ===
    ("pediatric[Title/Abstract] AND (treatment OR management)", 600),
    ("childhood obesity[Title/Abstract] AND intervention", 400),
    ("neonatal care[Title/Abstract]", 400),
    ("pediatric cancer[Title/Abstract] AND treatment", 400),
    ("childhood asthma[Title/Abstract] AND management", 400),
    
    # === WOMEN'S HEALTH (2,500 articles) ===
    ("pregnancy[Title/Abstract] AND complications", 500),
    ("polycystic ovary syndrome[Title/Abstract] AND treatment", 400),
    ("endometriosis[Title/Abstract] AND therapy", 400),
    ("menopause[Title/Abstract] AND management", 400),
    ("gestational diabetes[Title/Abstract] AND management", 400),
    
    # === GERIATRICS (2,000 articles) ===
    ("geriatric[Title/Abstract] AND (care OR management)", 500),
    ("frailty[Title/Abstract] AND elderly", 400),
    ("falls prevention[Title/Abstract] AND elderly", 400),
    ("polypharmacy[Title/Abstract] AND elderly", 400),
    
    # === PRECISION MEDICINE (2,000 articles) ===
    ("personalized medicine[Title/Abstract]", 500),
    ("pharmacogenomics[Title/Abstract]", 400),
    ("biomarkers[Title/Abstract] AND disease", 500),
    ("genomic medicine[Title/Abstract]", 400),
    
    # === EMERGING THERAPIES (2,000 articles) ===
    ("gene therapy[Title/Abstract]", 500),
    ("stem cell therapy[Title/Abstract]", 500),
    ("CRISPR[Title/Abstract] AND therapy", 400),
    ("regenerative medicine[Title/Abstract]", 400),
    
    # === PAIN MANAGEMENT (1,500 articles) ===
    ("chronic pain[Title/Abstract] AND management", 500),
    ("opioid[Title/Abstract] AND pain management", 400),
    ("pain management[Title/Abstract] AND non-pharmacological", 400),
    
    # === TELEMEDICINE & DIGITAL HEALTH (1,500 articles) ===
    ("telemedicine[Title/Abstract]", 400),
    ("digital health[Title/Abstract]", 400),
    ("mobile health[Title/Abstract]", 400),
    ("artificial intelligence[Title/Abstract] AND healthcare", 300),
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

        ndjson_lines = []
        for doc in documents:
            pmid = doc.get('pmid')
            if not pmid:
                continue

            ndjson_lines.append(json.dumps({'index': {'_index': ES_INDEX, '_id': pmid}}))
            ndjson_lines.append(json.dumps(doc))

        ndjson = '\n'.join(ndjson_lines) + '\n'

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
        batch_size = 200

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
                pmid_elem = article.find('.//PMID')
                if pmid_elem is None:
                    continue
                pmid = pmid_elem.text

                title_elem = article.find('.//ArticleTitle')
                title = ''.join(title_elem.itertext()) if title_elem is not None else ''

                abstract_parts = article.findall('.//AbstractText')
                abstract = ' '.join([''.join(part.itertext()) for part in abstract_parts])

                if not abstract:
                    continue

                pub_date = article.find('.//PubDate')
                date_str = self._extract_date(pub_date)

                authors = []
                for author in article.findall('.//Author'):
                    last = author.find('.//LastName')
                    first = author.find('.//ForeName')
                    if last is not None:
                        name = last.text
                        if first is not None:
                            name = f"{first.text} {name}"
                        authors.append(name)

                pub_types = article.findall('.//PublicationType')
                article_types = [pt.text for pt in pub_types if pt.text]

                # Extract journal info
                journal = article.find('.//Journal/Title')
                journal_name = journal.text if journal is not None else ''

                doc = {
                    'pmid': pmid,
                    'title': title,
                    'abstract': abstract,
                    'content': f"{title} {abstract}",
                    'publication_date': date_str,
                    'authors': authors[:10],
                    'article_type': article_types[0] if article_types else 'Article',
                    'journal': journal_name,
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

            months = {
                'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
                'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
                'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
            }
            m = months.get(m, m)

            try:
                m = m.zfill(2) if m.isdigit() else '01'
                d = d.zfill(2) if d.isdigit() else '01'
                return f"{y}-{m}-{d}"
            except:
                return f"{y}-01-01"

        return None

# ========== MAIN ==========

def print_header():
    print("=" * 70)
    print("  MediCortex - Enhanced PubMed Data Ingestion")
    print("  Target: 50,000+ high-quality medical articles")
    print("=" * 70)
    print()

def main():
    print_header()

    es_client = ElasticsearchClient()
    pubmed_client = PubMedClient()

    print("📊 Checking current index status...")
    stats = es_client.get_stats()
    print(f"   Current document count: {stats['count']:,}")
    print()

    print(f"📚 Will fetch articles for {len(MEDICAL_TOPICS)} medical topics")
    total_target = sum(count for _, count in MEDICAL_TOPICS)
    print(f"   Target: ~{total_target:,} articles")
    print(f"   Rate limit: {REQUESTS_PER_SECOND} requests/second")
    estimated_time = (total_target / REQUESTS_PER_SECOND) / 60
    print(f"   Estimated time: ~{estimated_time:.0f} minutes")
    print()

    response = input("Start ingestion? [Y/n]: ")
    if response.lower() == 'n':
        print("Cancelled.")
        return

    print("\n🚀 Starting ingestion...\n")
    start_time = time.time()

    for idx, (query, max_results) in enumerate(MEDICAL_TOPICS, 1):
        progress = (idx / len(MEDICAL_TOPICS)) * 100
        print(f"[{progress:5.1f}%] Topic {idx}/{len(MEDICAL_TOPICS)}: {query[:50]}")

        pmids = pubmed_client.search(query, max_results)

        if not pmids:
            print("   ⚠️  No results found")
            continue

        articles = pubmed_client.fetch_details(pmids)
        print(f"         Fetched {len(articles)} complete articles")

        if articles:
            result = es_client.index_documents(articles)
            print(f"         Indexed: {result['indexed']}, Errors: {result['errors']}")

        print()

    elapsed = time.time() - start_time
    print("\n" + "=" * 70)
    print("  ✅ Ingestion Complete!")
    print("=" * 70)
    print(f"  Total articles indexed: {es_client.indexed_count:,}")
    print(f"  Errors: {es_client.error_count}")
    print(f"  Time elapsed: {elapsed/60:.1f} minutes")

    final_stats = es_client.get_stats()
    print(f"  Final index count: {final_stats['count']:,} documents")
    print("=" * 70)
    print()
    print("🎉 Your MediCortex index is ready!")
    print()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
