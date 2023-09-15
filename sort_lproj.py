#!/usr/bin/env python3

import os

LOCATION = "./RootHide/"
subdirs = [f for f in os.listdir(LOCATION) if os.path.isdir(os.path.join(LOCATION, f)) and f.endswith('.lproj')]
files = list()

for subdir in subdirs:
  path = os.path.join(LOCATION, subdir)
  files.extend(
    [
      os.path.join(path, f) for f in os.listdir(path) \
        if os.path.isfile(os.path.join(path, f)) and f.endswith('.strings')
    ]
  )

for file in files:
  with open(file, 'r') as fin:
    lines = fin.readlines()
  lines = sorted([line for line in lines if not line.isspace()])
  with open(file, 'w') as fout:
    fout.write(''.join(lines))
