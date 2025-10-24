#!/bin/bash

# Test Runner for MediCortex Hackathon Features
# This script runs all critical tests to validate the winning features

echo "🧪 MediCortex - Running All Tests"
echo "=================================="
echo ""

# Check if env.json exists
if [ ! -f "env.json" ]; then
    echo "❌ Error: env.json not found!"
    echo "Please create env.json from env.example.json with your credentials"
    exit 1
fi

echo "✅ env.json found"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_file=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Running: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if flutter test $test_file; then
        echo ""
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo ""
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo ""
}

# Run tests in order
echo "Starting test suite..."
echo ""

# Test 1: Vertex AI Embeddings
run_test "Vertex AI Embeddings Service" "test/vertex_ai_embeddings_test.dart"

# Test 2: Hybrid Search
run_test "Elasticsearch Hybrid Search" "test/hybrid_search_test.dart"

# Test 3: RAG Service
run_test "RAG Service (Full Pipeline)" "test/rag_service_test.dart"

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
else
    echo "Failed:       $FAILED_TESTS"
fi

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Ready for integration!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please fix before proceeding.${NC}"
    exit 1
fi
