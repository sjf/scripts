#!/usr/bin/env python
"""
Compare two bash environments to find differences.
Compares ENV vars, path, shell opts, functions.
"""

from data.log import *
from data.utils import *
from termcolor import colored
SKIP_SAME=True

def read_dicteq(f):
  pairs = splitpairs(read_lines(f))
  return dict(pairs)

def read_dictws(f):
  pairs = splitpairsws(read_lines(f))
  return dict(pairs)

def read_path(f):
  with open(f) as fh:
    f = fh.read().strip()
    return f.split(":")

def read_functions(f):
  out = []
  lines = read_lines(f)
  for l in lines:
    if l:
      c = l[0]
      if not c.isspace() and c not in '{}':
        out.append(l)
  return out

def same(s):
  if SKIP_SAME:
    return
  print(colored("SAME " + s, "yellow"))

def removed(s):
  print(colored("REMOVED " +s, "cyan"))

def added(s):
  print(colored("ADDED " + s, "green"))

def changed(s):
  print(colored("CHANGED " + s, "white"))

def diff_(a,b):
  ka = sorted(a.keys())
  kb = sorted(b.keys())
  out = []

  for k in ka:
    if k in b and a[k] == b[k]:
      same(f"{k}={a[k]}")

  for k in ka:
    if k not in b:
      added(f"{k}={a[k]}")

  for k in kb:
    if k not in a:
      removed(f"{k}={b[k]}")

  for k in ka:
    if k in b and not a[k] == b[k]:
      changed(f"{k}={b[k]} to {a[k]}")
  print()

def diffl_(a,b):
  ka = sorted(a)
  kb = sorted(b)
  out = []

  for k in ka:
    if k in b:
      same(f"{k}")

  for k in ka:
    if k not in b:
      added(f"{k}")

  for k in kb:
    if k not in a:
      removed(f"{k}")
  print()

def showdiff(name,a,b):
  print(f"*** {name} ***")
  # print(f" *** {name} SHELL 1 ***")
  # printlines(a)
  # print(f" *** {name} SHELL 2 ***")
  # printlines(b)
  if type(a) == type({}):
    diff_(a,b)
  elif type(a) == type([]):
    diffl_(a,b)

def diffenv():
  f = ['SHLVL','ITERM_SESSION_ID', 'TERM_SESSION_ID'] # process specific
  a = filter_dict(read_dicteq('/tmp/e1'), f)
  b = filter_dict(read_dicteq('/tmp/e2'), f)

  showdiff("ENV",a,b)

def diffshopt():
  a = read_dictws('/tmp/s1')
  b = read_dictws('/tmp/s2')
  showdiff("SHOPT",a,b)

def diffpath():
  a = read_path('/tmp/p1')
  b = read_path('/tmp/p2')
  showdiff("PATH",a,b)

def difffunctions():
  a = read_functions('/tmp/f1')
  b = read_functions('/tmp/f2')
  showdiff("FUNCTIONS", a,b)


MESG="""Run the following commands
Shell #1:
set > /tmp/e1; alias > /tmp/a1; shopt > /tmp/s1; echo $PATH > /tmp/p1; declare -f > /tmp/f1;

Shell #2:
set > /tmp/e2; alias > /tmp/a2; shopt > /tmp/s21; echo $PATH > /tmp/p2; declare -f > /tmp/f2;
"""

FILES = ['a','e','s','p','f']
for file in FILES:
  for n in ['1','2']:
    if not isfile('/tmp/'+file + n):
      fail(MESG)

diffenv()
diffshopt()
diffpath()
difffunctions()
