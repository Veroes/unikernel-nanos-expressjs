#!/bin/bash

./delete_results.sh

{
    echo "========== Benchmark started at $(date) =========="

    BENCHMARK_SCRIPT="./benchmark.sh"
    THREADS=2
    CONNECTIONS_LIST=(1 5 10 20 30 40)
    DURATION=30

    for CONNECTIONS in "${CONNECTIONS_LIST[@]}"; do
        $BENCHMARK_SCRIPT $THREADS $CONNECTIONS $DURATION

        sleep 5
        echo ""
        echo "------------------------------------"
        echo ""
    done

    echo "========== Benchmark ended at $(date) =========="

} 2>&1 | tee -a benchmark.log