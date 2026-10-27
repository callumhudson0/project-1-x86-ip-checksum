#!/bin/bash
# Runs ipcheck against every example from the assignment handout plus extra edge cases.
# Usage: bash tests/run_tests.sh [path/to/ipcheck]     (default: ./ipcheck)
B="${1:-./ipcheck}"; pass=0; fail=0
t() { # $1 = exact input bytes (printf format), $2 = expected output after prompt, $3 = label
  got=$(printf -- "$1" | "$B"; echo "[rc=$?]")
  exp="Enter an IP address: $2
[rc=0]"
  if [ "$got" == "$exp" ]; then pass=$((pass+1)); printf "PASS  %-34s -> %s\n" "$3" "$2"
  else fail=$((fail+1)); printf "FAIL  %-34s\n  expected: %q\n  got:      %q\n" "$3" "$exp" "$got"; fi
}
echo "--- Handout examples ---"
t '68.191.206.51\n'      'The checksum is -9'   '#1 68.191.206.51'
t '10.224.6.4\n'         'The checksum is -33'  '#2 10.224.6.4'
t 'www.lindenwood.edu\n' 'Illegal IP address'   '#3 www.lindenwood.edu'
t '0.0.0.0\n'            'The checksum is -60'  '#4 0.0.0.0'
t '127.0.0.1\n'          'The checksum is -56'  '#5 127.0.0.1'
t '20.21.22.23\n'        'The checksum is 26'   '#6 20.21.22.23'
t '20/21/22/23\n'        'Illegal IP address'   '#7 20/21/22/23'
t '20. 21. 22.23\n'      'Illegal IP address'   '#8 spaces in middle'
t '20.21.22.23  \n'      'Illegal IP address'   '#9 trailing spaces'
t '253.254.256.1\n'      'Illegal IP address'   '#10 256 too big'
t '10.122.27.255\n'      'The checksum is 13'   '#11 10.122.27.255'
echo "--- Extra edge cases ---"
t '255.255.255.255\n'    'The checksum is -32'  'all 255'
t ' 1.2.3.4\n'           'Illegal IP address'   'leading space'
t '1.2.3.4.\n'           'Illegal IP address'   'trailing dot'
t '1.2.3.4.5\n'          'Illegal IP address'   'five numbers'
t '1.2.3\n'              'Illegal IP address'   'three numbers'
t '1..2.3\n'             'Illegal IP address'   'empty middle number'
t '.1.2.3\n'             'Illegal IP address'   'leading dot'
t '\n'                   'Illegal IP address'   'just Enter'
t ''                     'Illegal IP address'   'no input at all (Ctrl-D)'
t '1.2.3.4'              'The checksum is -50'  'no newline (piped)'
t '99999999999999999999999.1.1.1\n' 'Illegal IP address' 'giant number'
t '-1.2.3.4\n'           'Illegal IP address'   'minus sign'
t '1.2.3.4\t\n'          'Illegal IP address'   'tab at end'
t '1.2.3.4\r\n'          'Illegal IP address'   'carriage return'
t '30.30.30.30\n'        'The checksum is 60'   'max positive (30 each)'
t '31.62.93.124\n'       'The checksum is -60'  'multiples of 31'
t '200.100.50.25\n'      'The checksum is 5'   '200.100.50.25'
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
