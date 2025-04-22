#!/bin/bash

./delete_results.sh

{
    echo "========== Benchmark started at $(date) =========="

    BENCHMARK_SCRIPT="./benchmark.sh"
    THREADS=4
    CONNECTIONS_LIST=(4 10 20 30 40 50)
    DURATION=60

    for CONNECTIONS in "${CONNECTIONS_LIST[@]}"; do
        $BENCHMARK_SCRIPT $THREADS $CONNECTIONS $DURATION

        sleep 10
        echo ""
        echo "------------------------------------"
        echo ""
    done

    echo "========== Benchmark ended at $(date) =========="

} 2>&1 | tee -a benchmark.log