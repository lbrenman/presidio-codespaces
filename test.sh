#!/bin/bash
# Quick smoke test for Presidio Analyzer and Anonymizer APIs

ANALYZER_URL="http://localhost:5002"
ANONYMIZER_URL="http://localhost:5001"
PASS=0
FAIL=0

run_test() {
  local name="$1"
  local result="$2"
  local expect="$3"

  if echo "$result" | grep -q "$expect"; then
    echo "  ✅ PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL: $name"
    echo "     Response: $result"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "================================================"
echo "  Presidio API Smoke Tests"
echo "================================================"

echo ""
echo "--- Analyzer (port 5002) ---"

result=$(curl -sf "$ANALYZER_URL/health" 2>&1)
run_test "Analyzer health check" "$result" "ok\|healthy\|200\|OK"

result=$(curl -sf -X POST "$ANALYZER_URL/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text":"My name is John Smith and my email is john@example.com","language":"en"}' 2>&1)
run_test "Analyze - detect PERSON" "$result" "PERSON"
run_test "Analyze - detect EMAIL_ADDRESS" "$result" "EMAIL_ADDRESS"

result=$(curl -sf "$ANALYZER_URL/supportedentities?language=en" 2>&1)
run_test "List supported entities" "$result" "PHONE_NUMBER"

echo ""
echo "--- Anonymizer (port 5001) ---"

result=$(curl -sf "$ANONYMIZER_URL/health" 2>&1)
run_test "Anonymizer health check" "$result" "ok\|healthy\|200\|OK"

result=$(curl -sf -X POST "$ANONYMIZER_URL/anonymize" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "My name is John Smith.",
    "anonymizers": { "DEFAULT": { "type": "replace" } },
    "analyzer_results": [
      { "start": 11, "end": 21, "score": 0.85, "entity_type": "PERSON" }
    ]
  }' 2>&1)
run_test "Anonymize - replace PERSON" "$result" "PERSON\|<"

result=$(curl -sf "$ANONYMIZER_URL/anonymizers" 2>&1)
run_test "List supported anonymizers" "$result" "replace\|mask\|hash"

echo ""
echo "================================================"
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "================================================"
echo ""

[ $FAIL -eq 0 ] && exit 0 || exit 1
