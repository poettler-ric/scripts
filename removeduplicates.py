#!/usr/bin/env python3

import sys

if __name__ == '__main__':
    lines = []
    uniqueLines = {}

    for line in sys.stdin:
        line = line.strip()
        if line not in uniqueLines:
            lines.append(line)
            uniqueLines[line] = True

    for line in lines:
        print(line)
