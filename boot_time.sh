#!/bin/bash

# ./boot_time.sh <tests>
# Example of how to run the script:
# ./boot_time.sh 10

NODE_LIBRARY="eyberg/node:20.5.0"
CONFIG="config.json"
NUMBER_OF_TESTS=${1:-10}

total=0

nanos_boot_time() {
    START=$(date +%s%N)

    ops pkg load $NODE_LIBRARY -c $CONFIG  > /dev/null 2>&1 &
    NANOS_PID=$!

    while ! nc -z localhost 3001; do
        sleep 0.1
    done

    END=$(date +%s%N)
    RESULT=$(( (END - START) / 1000000 )) # In milliseconds

    echo "$RESULT"
    kill $NANOS_PID 2>/dev/null
}

echo "Running $NUMBER_OF_TESTS tests..."

for (( i=1; i<=$NUMBER_OF_TESTS; i++ )); do
    time_ms=$(nanos_boot_time)
    echo "Test $i: $time_ms ms"
    total=$(( total + time_ms ))
    sleep 1.5
done

# bc used for floating point values
AVERAGE_BOOT_TIME=$(echo "scale=2; $total / $NUMBER_OF_TESTS" | bc)
echo "Average boot time over $NUMBER_OF_TESTS tests: $AVERAGE_BOOT_TIME ms"