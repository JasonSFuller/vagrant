#!/bin/bash

# NOTES:
#
# * If you have a large number of ranges to check, shell math can be slow
#   (mostly because of the subshells).  If you run into speed issues,
#   re-implement this in full-featured language, i.e. Python.  Just remember to
#   stick to built-in modules and/or do the math yourself since this will also
#   run from Tower.  On my Intel NUC 10 (2020-ish), this script takes about
#   2.169 seconds when performing the worst case match using a $CONFIG with 1024
#   ranges.  You _could_ skip some of the sanity checks to make this script
#   faster, if you're diligent about maintaining the $CONFIG.  However, if
#   you're getting to the point where this is an actual issue, again, consider
#   using Python.  Normally, you're limited by the speed of Tower
#   starting/queuing/executing the job anyway, but YMMV.
#
# * The default value for $CONFIG is f5-lookup.conf, but it can be overwritten
#   by setting it as an environment variable.  Each line in $CONFIG should be in
#   the following format:
#       <cidr_range> + "," + <dev_mgmt_if> [ + "," + <dev_mgmt_if> ... ]
#   Example: 
#       10.10.0.0/24,f5-mgmt-1a
#       10.10.1.0/24,f5-mgmt-1a,f5-mgmt-1b
#       10.10.2.0/24,f5-mgmt-1a,f5-mgmt-1b,f5-mgmt-1c
#       10.10.3.0/24,f5-mgmt-2a,f5-mgmt-2b
#       ...
#   <dev_mgmt_if> can be a name, an IP, or any string you want (except for the
#   delimiter, a comma), but at least one value is required.  Lines should be
#   terminated with a newline character.  Also, be sure to leave a newline at
#   the end of the file ("\n<EOF>"), or the last line in $CONFIG will be ignored
#   and never matched in the loop below.  
#
# * If you accidentally add overlapping ranges, only devices for the first
#   matching CIDR block is returned.
#
# * The is_cidr function does not accept CIDR notation in the short form, e.g.
#   10/8.  Use the full form of 10.0.0.0/8 instead.



### functions ##################################################################

function usage {
  echo "USAGE:        $0 <ip_address>" >&2
  echo "DESCRIPTION:  Given an IP address, lookup the corresponding device" >&2
  echo "              management interface (for use in automation)." >&2
  exit 1
}

function error {
  echo "ERROR: $*" >&2
  exit 2
}

# Check if IP is in valid dotted quad format, e.g. 1.2.3.4
function is_ip {
  local ip="$1" o1 o2 o3 o4
  IFS="." read -r o1 o2 o3 o4 <<< "$ip"
  if [[ ! $o1 =~ ^[0-9]+$ || $o1 -lt 0 || $o1 -gt 255 ]]; then return 3; fi
  if [[ ! $o2 =~ ^[0-9]+$ || $o2 -lt 0 || $o2 -gt 255 ]]; then return 4; fi
  if [[ ! $o3 =~ ^[0-9]+$ || $o3 -lt 0 || $o3 -gt 255 ]]; then return 5; fi
  if [[ ! $o4 =~ ^[0-9]+$ || $o4 -lt 0 || $o4 -gt 255 ]]; then return 6; fi
  return
}

# Check if CIDR range is in a valid format, e.g. 1.2.3.4/5
function is_cidr {
  local cidr="$1" ip m
  IFS="/" read -r ip m <<< "$cidr"
  if ! is_ip "$ip"; then return 7; fi
  if [[ ! $m =~ ^[0-9]+$ || $m -lt 0 || $m -gt 32  ]]; then return 8; fi
  return
}

# Convert IP address (dotted quad) to a decimal integer, e.g. 1.2.3.4 = 16909060
function print_i2n {
  local ip="$1" o1 o2 o3 o4
  if ! is_ip "$ip"; then return 9; fi
  IFS="." read -r o1 o2 o3 o4 <<< "$ip"
  echo "$(( o1*256**3 + o2*256**2 + o3*256 + o4 ))"
}

# Determine if an IP is inside the given CIDR range.
function in_subnet {
  local cidr="$1" ip="$2" cip cnm nm isn csn
  IFS="/" read -r cip cnm <<< "$cidr"
  nm=$(( 0xFFFFFFFF << 32 - cnm ))
  isn=$(( nm & $(print_i2n "$ip") ))
  csn=$(( nm & $(print_i2n "$cip") ))
  if [[ "$isn" == "$csn" ]]; then return; fi
  return 10
}

### main #######################################################################

ip="$1"
CONFIG=${CONFIG:-f5-lookup.conf}

if [[ -z "$ip" ]]; then usage; fi
if ! is_ip "$ip"; then error "invalid ip"; fi
if [[ ! -r "$CONFIG" ]]; then error "config not found ($CONFIG)"; fi

while IFS="," read -r cidr remainder
do
  if [[ -z "$remainder" ]]; then error "device info missing from config"; fi
  if ! is_cidr "$cidr"; then error "invalid cidr in config (cidr=$cidr)"; fi
  if in_subnet "$cidr" "$ip"; then
    IFS="," read -ra devs <<< "$remainder"
    printf '%s\n' "${devs[@]}"
    exit
  fi
done < "$CONFIG"

error "no matching device found (ip=$ip)"
