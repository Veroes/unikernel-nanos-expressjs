#!/bin/bash

# ./benchmark.sh <threads> <connections> <duration> [OPTIONAL <app_url> <csv_file>]
# Example of how to run the script:
# ./benchmark.sh 2 50 30 http://localhost:3001 benchmark_results.csv

THREADS=$1
CONNECTIONS=$2
DURATION=$3
APP_URL=${4:-"http://localhost:3001"}
CSV_FILE=${5:-"benchmark_results.csv"}

NODE_LIBRARY="eyberg/node:20.5.0"
CONFIG="config.json"

LOG_FILE="benchmark.log"
CPU_LOG_DIR="./cpu_logs"
MEM_LOG_DIR="./mem_logs"
TMP_WRK_OUTPUT="wrk_output.tmp"

next_log_index=$(ls $CPU_LOG_DIR/cpu_usage_*.log 2>/dev/null | sed -E 's/.*cpu_usage_([0-9]+)\.log/\1/' | sort -n | tail -1)

if [ -z "$next_log_index" ]; then
    next_log_index=1
else
    next_log_index=$((next_log_index + 1))
fi

CPU_LOG="${CPU_LOG_DIR}/cpu_usage_${next_log_index}.log"
MEM_LOG="${MEM_LOG_DIR}/mem_usage_${next_log_index}.log"

echo "Starting Benchmark Test..."
echo "Threads: $THREADS, Connections: $CONNECTIONS, Duration: $DURATION"

# Start Nanos
ops pkg load $NODE_LIBRARY -c $CONFIG > /dev/null 2>&1 &

# Check if Nanos ready
while ! nc -z localhost 3001; do
    sleep 5
done

# Get PID from running processes
NANOS_PID=$(pgrep -f "qemu-system-x86_64")

# CPU
echo "Monitoring CPU & Memory usage..."
pidstat -u -p $NANOS_PID 1 > $CPU_LOG &  
CPU_PIDSTAT_PID=$!

# Memory (Get the VIRT and RSS)
while ps -p $NANOS_PID > /dev/null; do
    pmap -x $NANOS_PID | tail -1 | awk '{print $3, $4}' >> $MEM_LOG
    sleep 1
done & # Running in Background
MEM_MONITOR_PID=$!

# Delay
sleep 0.5

# Run WRK benchmark
wrk -t$THREADS -c$CONNECTIONS -d"${DURATION}s" $APP_URL | tee $TMP_WRK_OUTPUT >> $LOG_FILE 

# Stop Monitoring
echo "Stopping CPU & Memory monitoring..."
kill $NANOS_PID 2>/dev/null
kill $CPU_PIDSTAT_PID 2>/dev/null
kill $MEM_MONITOR_PID 2>/dev/null

# Calculate Average CPU and Memory
# CPU Usage
CPU_USAGE=$(awk '{sum+=$8} END {print sum/NR " %"}' $CPU_LOG)

# Memory Usage
VIRT_USAGE=$(awk '{sum+=$1} END {printf "%.2f", sum/NR}' $MEM_LOG)
RSS_USAGE=$(awk '{sum+=$2} END {printf "%.2f", sum/NR}' $MEM_LOG)
# Peak Memory Usage
PEAK_RSS=$(awk '{ if ($2 > max) max=$2 } END { print max }' $MEM_LOG)

# Convert Memory Usage KB to MB
VIRT_USAGE_MB=$(echo "scale=2; $VIRT_USAGE / 1024" | bc)
RSS_USAGE_MB=$(echo "scale=2; $RSS_USAGE / 1024" | bc)
PEAK_RSS_MB=$(echo "scale=2; $PEAK_RSS / 1024" | bc)

# WRK Parsing
TOTAL_REQUESTS=$(grep -m1 "requests in" $TMP_WRK_OUTPUT | awk '{print $1}')
REQUESTS_PER_SEC=$(grep "Requests/sec" $TMP_WRK_OUTPUT | awk '{print $2}')
TRANSFER_PER_SEC=$(grep "Transfer/sec" $TMP_WRK_OUTPUT | awk '{print $2 " " $3}')

SOCKET_CONNECT=$(grep "Socket errors" $TMP_WRK_OUTPUT | awk -F'connect ' '{print $2}' | awk -F',' '{print $1}')
SOCKET_READ=$(grep "Socket errors" $TMP_WRK_OUTPUT | awk -F'read ' '{print $2}' | awk -F',' '{print $1}')
SOCKET_WRITE=$(grep "Socket errors" $TMP_WRK_OUTPUT | awk -F'write ' '{print $2}' | awk -F',' '{print $1}')
SOCKET_TIMEOUT=$(grep "Socket errors" $TMP_WRK_OUTPUT | awk -F'timeout ' '{print $2}' | awk '{print $1}')

# Display results
echo "===== System Usage (Average) ====="
echo "CPU Usage: $CPU_USAGE"
echo "Memory Usage (VIRT): $VIRT_USAGE_MB MB"
echo "Memory Usage (RSS):  $RSS_USAGE_MB MB"
echo "Peak Memory Usage (RSS): $PEAK_RSS_MB MB"
echo "Requests/sec: $REQUESTS_PER_SEC"
echo "Transfer/sec: $TRANSFER_PER_SEC"
echo "Socket Errors (C/R/W/T): $SOCKET_CONNECT/$SOCKET_READ/$SOCKET_WRITE/$SOCKET_TIMEOUT"

# Save results to CSV
if [ ! -f "$CSV_FILE" ]; then
    echo "Threads,Connections,Duration,CPU Usage,Virtual Memory (MB),Resident Memory (MB),Peak Resident Memory (MB),Total Requests,Requests/sec,Transfer/sec,SocketErr (Connect),SocketErr (Read),SocketErr (Write),SocketErr (Timeout)" > "$CSV_FILE"
fi
echo "$THREADS,$CONNECTIONS,$DURATION,$CPU_USAGE,$VIRT_USAGE_MB,$RSS_USAGE_MB,$PEAK_RSS_MB,$TOTAL_REQUESTS,$REQUESTS_PER_SEC,$TRANSFER_PER_SEC,$SOCKET_CONNECT,$SOCKET_READ,$SOCKET_WRITE,$SOCKET_TIMEOUT" >> "$CSV_FILE"


echo "Benchmark test completed. Results saved in $LOG_FILE and $CSV_FILE"