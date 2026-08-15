#!/usr/bin/env python3
"""Broker stats. One-shot by default; --watch N for live in-place refresh."""
import argparse
import datetime
import json
import sys
import time
import urllib.request

URL = "http://hil:9875/labels/stats"


def fetch():
    with urllib.request.urlopen(URL, timeout=5) as r:
        return json.load(r)


def render(d):
    """Return list of strings (one per line) to display."""
    def fmt(v, spec, fallback="—"):
        return format(v, spec) if v is not None else fallback

    lines = [
        f"{datetime.datetime.now().strftime('%H:%M:%S')}  "
        f"pct {fmt(d.get('pct_done'), '.2f')}%  |  "
        f"{fmt(d.get('pct_per_hour'), '.2f')}%/hr  |  "
        f"ETA {fmt(d.get('eta_hours_remaining'), '.1f')}h"
    ]
    for w in sorted(d['per_worker_recent_10min'], key=lambda x: -x['keys_10min']):
        rps = w['keys_10min'] * 90 / 600
        lines.append(f"  {w['worker']:15s} {rps:>5.1f} reqs/s")
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--watch", type=float, nargs="?", const=5.0, default=None,
                    metavar="SECONDS",
                    help="Refresh every N seconds in place (default 5)")
    args = ap.parse_args()

    if args.watch is None:
        for line in render(fetch()):
            print(line)
        return

    # Live mode: print once, then redraw in place.
    last_n = 0
    try:
        while True:
            try:
                lines = render(fetch())
            except Exception as e:
                lines = [f"  ERROR: {e!r}"]
            # Move cursor up to top of previous block + clear from there down.
            if last_n:
                sys.stdout.write(f"\033[{last_n}A\033[J")
            sys.stdout.write("\n".join(lines) + "\n")
            sys.stdout.flush()
            last_n = len(lines)
            time.sleep(args.watch)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
