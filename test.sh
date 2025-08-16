#!/bin/bash

BEFORE=$(curl -s localhost:8080/albums | jq length)

for i in {1..20}; do
    hey -n 25 -c 25 -m POST -d '{"id":"test","title":"Test","artist":"Artist","price":99.99}' -T application/json http://localhost:8080/albums >/dev/null 2>&1 &
done

wait

AFTER=$(curl -s localhost:8080/albums | jq length)
LOST=$((BEFORE + 500 - AFTER))

echo "EXPECTED: $((BEFORE + 500))"
echo "ACTUAL:   $AFTER"
echo "LOST:     $LOST"

[ $LOST -gt 0 ] && echo "🎯 RACE CONDITION TRIGGERED" || echo "❌ No race condition"
