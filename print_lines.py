#!/usr/bin/env python3
"""
Script that prints "line 1", "line 2", etc. up to line n
with a 1-second delay between each print.

Usage: python print_lines.py <n>
"""

import sys
import time

def print_lines(n):
    """Print lines from 1 to n with 1 second delay between each."""
    for i in range(1, n + 1):
        print(f"line {i}")
        if i < n:  # Don't sleep after the last line
            time.sleep(1)

def main():
    # Check if argument is provided
    if len(sys.argv) != 2:
        print("Usage: python print_lines.py <n>")
        print("  where <n> is the number of lines to print")
        sys.exit(1)
    
    # Parse the argument
    try:
        n = int(sys.argv[1])
        if n <= 0:
            print("Error: n must be a positive integer")
            sys.exit(1)
    except ValueError:
        print(f"Error: '{sys.argv[1]}' is not a valid integer")
        sys.exit(1)
    
    # Print the lines
    print_lines(n)

if __name__ == "__main__":
    main()
