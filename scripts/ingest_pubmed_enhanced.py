#!/usr/bin/env python3
"""
Enhanced PubMed Data Ingestion Script for MediCortex (Qdrant edition)

Fetches 50,000+ high-quality medical articles across diverse topics
and indexes them into Qdrant Cloud with Vertex AI semantic embeddings.

Requirements:
    pip install requests google-auth

Usage:
    python ingest_pubmed_enhanced.py               # full run with embeddings
    python ingest_pubmed_enhanced.py --no-embed    # skip embeddings (keyword search only)
"""

import requests
import time
import json
import sys
import argparse
from datetime import datetime
from typing import List, Dict, Optional
import xml.etree.ElementTree as ET
from pathlib import Path

# ========== CONFIG ==========

def load_config():
    script_dir = Path(__file__).parent
    env_path = script_dir.parent / 'env.json'
    if not env_path.exists():
        print(f"❌ env.json not found at {env_path}")
        sys.exit(1)
    try:
        with open(env_path, 'r') as f:
            raw = json.load(f)
        parsed = {}
        for k, v in raw.items():
            if isinstance(v, str):
                try:
                    parsed[k] = json.loads(v)
                except (json.JSONDecodeError, ValueError):
                    parsed[k] = v
            else:
                parsed[k] = v
        return parsed
    except Exception as e:
        print(f"❌ Error loading env.json: {e}")
        sys.exit(1)

CONFIG = load_config()

QDRANT_URL        = CONFIG['qdrant']['endpoint'].rstrip('/')
QDRANT_API_KEY    = CONFIG['qdrant']['apiKey']
QDRANT_COLLECTION = CONFIG['qdrant'].get('collection', 'pubmed_articles')

PUBMED_API_BASE   = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
PUBMED_EMAIL      = CONFIG.get('pubmed', {}).get('email', 'user@example.com')
PUBMED_API_KEY    = CONFIG.get('pubmed', {}).get('apiKey')

REQUESTS_PER_SECOND = 3 if not PUBMED_API_KEY else 10
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

# ========== VERTEX AI EMBEDDINGS ==========

class VertexAiEmbeddingsClient:
    """Generates text embeddings using Google Vertex AI text-embedding-004."""

    def __init__(self):
        sa_info = CONFIG.get('service_account')
        if not sa_info or not isinstance(sa_info, dict):
            raise RuntimeError("service_account not found in env.json")

        vertex_cfg = CONFIG.get('vertex_ai', {})
        self.project_id = vertex_cfg.get('project_id') or sa_info.get('project_id')
        self.location   = vertex_cfg.get('location', 'us-central1')
        self.model      = 'text-embedding-004'

        try:
            from google.oauth2 import service_account as sa_module
            from google.auth.transport.requests import Request as GRequest

            self._credentials = sa_module.Credentials.from_service_account_info(
                sa_info,
                scopes=['https://www.googleapis.com/auth/cloud-platform'],
            )
            self._auth_request = GRequest()
        except ImportError:
            raise RuntimeError(
                "google-auth not installed. Run: pip install google-auth"
            )

    def _refresh_token(self):
        if not self._credentials.valid:
            self._credentials.refresh(self._auth_request)

    def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        self._refresh_token()
        token = self._credentials.token

        url = (
            f"https://{self.location}-aiplatform.googleapis.com/v1"
            f"/projects/{self.project_id}/locations/{self.location}"
            f"/publishers/google/models/{self.model}:predict"
        )
        instances = [
            {'content': text[:2000], 'task_type': 'RETRIEVAL_DOCUMENT'}
            for text in texts
        ]

        resp = requests.post(
            url,
            headers={
                'Authorization': f'Bearer {token}',
                'Content-Type': 'application/json',
            },
            json={'instances': instances},
            timeout=60,
        )

        if resp.status_code == 200:
            predictions = resp.json().get('predictions', [])
            return [p['embeddings']['values'] for p in predictions]
        else:
            raise RuntimeError(
                f"Vertex AI embedding failed ({resp.status_code}): {resp.text[:300]}"
            )


# ========== QDRANT CLIENT ==========

class QdrantClient:
    def __init__(self):
        self.headers = {
            'api-key': QDRANT_API_KEY,
            'Content-Type': 'application/json',
        }
        self.indexed_count = 0
        self.error_count   = 0

    def ensure_collection(self):
        resp = requests.get(
            f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}",
            headers=self.headers,
        )
        if resp.status_code == 200:
            info = resp.json().get('result', {})
            print(f"ℹ️  Collection '{QDRANT_COLLECTION}' exists "
                  f"({info.get('points_count', 0):,} points)")
            return

        print(f"🔨 Creating collection '{QDRANT_COLLECTION}'...")
        resp = requests.put(
            f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}",
            headers=self.headers,
            json={'vectors': {'size': 768, 'distance': 'Cosine'}},
        )
        if resp.status_code not in [200, 409]:
            raise RuntimeError(f"Collection creation failed: {resp.text}")
        print("✅ Collection created")

        resp = requests.put(
            f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}/index",
            headers=self.headers,
            json={
                'field_name': 'content',
                'field_schema': {
                    'type': 'text',
                    'tokenizer': 'word',
                    'min_token_len': 2,
                    'max_token_len': 30,
                    'lowercase': True,
                },
            },
        )
        if resp.status_code in [200, 202]:
            print("✅ Text index created on 'content' field")

    def filter_new(self, pmids: List[str]) -> List[str]:
        """Return only PMIDs that are NOT already in Qdrant."""
        if not pmids:
            return []
        existing = set()
        for i in range(0, len(pmids), 100):
            batch_ids = [int(p) for p in pmids[i:i + 100] if p.isdigit()]
            if not batch_ids:
                continue
            try:
                resp = requests.post(
                    f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}/points",
                    headers=self.headers,
                    json={'ids': batch_ids, 'with_payload': False, 'with_vector': False},
                    timeout=30,
                )
                if resp.status_code == 200:
                    for pt in resp.json().get('result', []):
                        existing.add(str(pt['id']))
            except Exception as e:
                print(f"⚠️  Existence check failed: {e}")
        return [p for p in pmids if p not in existing]

    def index_documents(self, documents: List[Dict]) -> Dict:
        if not documents:
            return {'indexed': 0, 'errors': 0}

        points = []
        for doc in documents:
            pmid = doc.get('pmid')
            if not pmid:
                continue
            try:
                point_id = int(pmid)
            except (ValueError, TypeError):
                self.error_count += 1
                continue

            vector = doc.pop('embedding', None) or [0.0] * 768
            points.append({'id': point_id, 'vector': vector, 'payload': doc})

        if not points:
            return {'indexed': 0, 'errors': len(documents)}

        total_indexed = 0
        total_errors  = 0

        for i in range(0, len(points), 50):
            batch = points[i:i + 50]
            success = False
            for attempt in range(3):
                try:
                    resp = requests.put(
                        f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}/points",
                        headers=self.headers,
                        json={'points': batch},
                        timeout=120,
                    )
                    if resp.status_code == 200 and resp.json().get('status') == 'ok':
                        total_indexed      += len(batch)
                        self.indexed_count += len(batch)
                        success = True
                    else:
                        print(f"❌ Upsert failed ({resp.status_code}): {resp.text[:200]}")
                    break
                except requests.exceptions.Timeout:
                    wait = 10 * (attempt + 1)
                    print(f"⏳ Timeout on batch {i//50 + 1}, retry {attempt + 1}/3 in {wait}s...")
                    time.sleep(wait)
                except requests.exceptions.ConnectionError as e:
                    wait = 10 * (attempt + 1)
                    print(f"⚠️  Connection error: {e}, retry {attempt + 1}/3 in {wait}s...")
                    time.sleep(wait)

            if not success and attempt == 2:
                total_errors      += len(batch)
                self.error_count  += len(batch)
                print(f"❌ Batch permanently failed after 3 retries, skipping.")

        return {'indexed': total_indexed, 'errors': total_errors}

    def get_stats(self) -> Dict:
        try:
            resp = requests.get(
                f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}",
                headers=self.headers,
            )
            if resp.status_code == 200:
                result = resp.json().get('result', {})
                return {'count': result.get('points_count', 0)}
        except Exception as e:
            print(f"⚠️  Failed to get stats: {e}")
        return {'count': 0}


# ========== PUBMED CLIENT ==========

class PubMedClient:
    def __init__(self):
        self.session = requests.Session()
        self.total_fetched = 0

    def search(self, query: str, max_results: int = 1000) -> List[str]:
        params = {
            'db':      'pubmed',
            'term':    query,
            'retmax':  max_results,
            'retmode': 'json',
            'email':   PUBMED_EMAIL,
        }
        if PUBMED_API_KEY:
            params['api_key'] = PUBMED_API_KEY
        try:
            resp = self.session.get(f"{PUBMED_API_BASE}/esearch.fcgi", params=params)
            time.sleep(DELAY)
            if resp.status_code == 200:
                return resp.json().get('esearchresult', {}).get('idlist', [])
            print(f"❌ Search failed: {resp.status_code}")
        except Exception as e:
            print(f"❌ Search error: {e}")
        return []

    def fetch_details(self, pmids: List[str]) -> List[Dict]:
        articles = []
        for i in range(0, len(pmids), 200):
            batch = pmids[i:i + 200]
            params = {
                'db':      'pubmed',
                'id':      ','.join(batch),
                'retmode': 'xml',
                'email':   PUBMED_EMAIL,
            }
            if PUBMED_API_KEY:
                params['api_key'] = PUBMED_API_KEY
            try:
                resp = self.session.get(f"{PUBMED_API_BASE}/efetch.fcgi", params=params)
                time.sleep(DELAY)
                if resp.status_code == 200:
                    parsed = self._parse_xml(resp.text)
                    articles.extend(parsed)
                    self.total_fetched += len(parsed)
                else:
                    print(f"❌ Fetch failed: {resp.status_code}")
            except Exception as e:
                print(f"❌ Fetch error: {e}")
        return articles

    def _parse_xml(self, xml_text: str) -> List[Dict]:
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
                abstract = ' '.join(''.join(p.itertext()) for p in abstract_parts)
                if not abstract:
                    continue

                pub_date = article.find('.//PubDate')
                date_str = self._extract_date(pub_date)

                authors = []
                for author in article.findall('.//Author'):
                    last  = author.find('.//LastName')
                    first = author.find('.//ForeName')
                    if last is not None:
                        name = last.text or ''
                        if first is not None and first.text:
                            name = f"{first.text} {name}"
                        authors.append(name)

                pub_types    = article.findall('.//PublicationType')
                article_type = [pt.text for pt in pub_types if pt.text]

                journal      = article.find('.//Journal/Title')
                journal_name = journal.text if journal is not None else ''

                articles.append({
                    'pmid':             pmid,
                    'title':            title,
                    'abstract':         abstract,
                    'content':          f"{title} {abstract}",
                    'publication_date': date_str,
                    'authors':          authors[:10],
                    'article_type':     article_type[0] if article_type else 'Article',
                    'journal':          journal_name,
                    'source_url':       f"https://pubmed.ncbi.nlm.nih.gov/{pmid}/",
                    'indexed_at':       datetime.now().isoformat(),
                })
            except Exception as e:
                print(f"⚠️  Error parsing article: {e}")
        return articles

    def _extract_date(self, pub_date) -> Optional[str]:
        if pub_date is None:
            return None
        year  = pub_date.find('Year')
        month = pub_date.find('Month')
        day   = pub_date.find('Day')
        if year is not None:
            y = year.text
            m = month.text if month is not None else '01'
            d = day.text   if day   is not None else '01'
            months = {
                'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
                'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
                'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
            }
            m = months.get(m, m)
            try:
                m = m.zfill(2) if m.isdigit() else '01'
                d = d.zfill(2) if d.isdigit() else '01'
                return f"{y}-{m}-{d}"
            except Exception:
                return f"{y}-01-01"
        return None


# ========== MAIN ==========

def add_embeddings(articles: List[Dict], embedder: VertexAiEmbeddingsClient):
    texts      = [a['content'][:2000] for a in articles]
    batch_size = 20

    for i in range(0, len(texts), batch_size):
        batch_texts    = texts[i:i + batch_size]
        batch_articles = articles[i:i + batch_size]
        try:
            embeddings = embedder.generate_embeddings(batch_texts)
            for article, emb in zip(batch_articles, embeddings):
                article['embedding'] = emb
        except Exception as e:
            print(f"⚠️  Embedding batch {i // batch_size + 1} failed: {e}")
        time.sleep(0.5)


def main():
    parser = argparse.ArgumentParser(
        description='Ingest 50k+ PubMed articles into Qdrant'
    )
    parser.add_argument(
        '--no-embed',
        action='store_true',
        help='Skip Vertex AI embeddings (keyword search only, much faster)',
    )
    args = parser.parse_args()

    print("=" * 70)
    print("  MediCortex — Enhanced PubMed → Qdrant Ingestion")
    print("  Target: 50,000+ high-quality medical articles")
    print("=" * 70)
    print()

    embedder = None
    if not args.no_embed:
        try:
            embedder = VertexAiEmbeddingsClient()
            print("✅ Vertex AI embeddings enabled (semantic search)")
        except Exception as e:
            print(f"⚠️  Vertex AI unavailable: {e}")
            print("   Proceeding with zero vectors — keyword search only.")
    else:
        print("ℹ️  Embeddings skipped (--no-embed). Using keyword search only.")
    print()

    qdrant_client = QdrantClient()
    pubmed_client = PubMedClient()

    qdrant_client.ensure_collection()
    stats = qdrant_client.get_stats()
    print(f"📊 Current document count: {stats['count']:,}")
    print()

    total_target   = sum(n for _, n in MEDICAL_TOPICS)
    estimated_mins = (total_target / REQUESTS_PER_SECOND) / 60
    print(f"📚 {len(MEDICAL_TOPICS)} topics  |  ~{total_target:,} target articles")
    print(f"   Rate limit : {REQUESTS_PER_SECOND} req/s")
    print(f"   Est. time  : ~{estimated_mins:.0f} min")
    print()

    answer = input("Start ingestion? [Y/n]: ").strip().lower()
    if answer == 'n':
        print("Cancelled.")
        return

    print("\n🚀 Starting...\n")
    start_time = time.time()

    for idx, (query, max_results) in enumerate(MEDICAL_TOPICS, 1):
        pct = idx / len(MEDICAL_TOPICS) * 100
        print(f"[{pct:5.1f}%] Topic {idx}/{len(MEDICAL_TOPICS)}: {query[:50]}")

        pmids = pubmed_client.search(query, max_results)
        if not pmids:
            print("         ⚠️  No results")
            continue

        pmids = qdrant_client.filter_new(pmids)
        if not pmids:
            print("         ✅ All already indexed, skipping")
            continue

        articles = pubmed_client.fetch_details(pmids)
        print(f"         Fetched {len(articles)} new articles")

        if articles:
            if embedder:
                add_embeddings(articles, embedder)
            result = qdrant_client.index_documents(articles)
            print(f"         Indexed: {result['indexed']}, Errors: {result['errors']}")

        print()

    elapsed = time.time() - start_time
    final   = qdrant_client.get_stats()
    print("=" * 70)
    print("  ✅ Done!")
    print(f"  Indexed this run : {qdrant_client.indexed_count:,}")
    print(f"  Errors           : {qdrant_client.error_count}")
    print(f"  Total in Qdrant  : {final['count']:,}")
    print(f"  Time             : {elapsed / 60:.1f} min")
    print("=" * 70)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n⚠️  Interrupted. Progress has been saved.")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
