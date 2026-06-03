#!/bin/bash

OUTFILE="out.txt"
ITER=1
RNS_NUM=2   # allowed values: 2, 4, 7, 14, 29

echo "===== START $(date) =====" > "$OUTFILE"

for ((i=1;i<=ITER;i++)); do
  echo "" >> "$OUTFILE"
  echo "===== ITERATION $i =====" >> "$OUTFILE"

expect <<EOF
  set timeout -1

  # ---- run.sh (completely silent) ----
  log_user 0
  spawn ./run.sh
  expect {
      -re ".*\\[Y/n\\].*" { send "y\r"; exp_continue }
      -re ".*password.*" { send "password90!\r"; exp_continue }
      eof
  }

  # ---- make run with auto Ctrl+C after 2 min ----
  log_file -a $OUTFILE
  log_user 0
  spawn make run TARGET=hw
  send "v\r"

  # send Ctrl+C after 120 seconds
  after 250000 {
      send "\003"
  }

  expect eof
EOF

echo "===== KERNEL OUTPUT =====" >> "$OUTFILE"

  cd scripts/kernel || exit
  python3 compare_script.py "$RNS_NUM" >> "../../$OUTFILE" 2>&1
  cd ../.. || exit

done

echo "===== DONE $(date) =====" >> "$OUTFILE"
