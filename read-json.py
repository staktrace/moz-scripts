#!/usr/bin/env python

import json
import sys

j = json.load(sys.stdin)
components = sys.argv[1].split('/')
for component in components:
    if type(j) == list:
        component = int(component)
        if component >= len(j):
            sys.exit(1)
        j = j[component]
    elif type(j) == dict:
        if component not in j:
            sys.exit(1)
        j = j[component]

if type(j) == dict:
    print ' '.join(j.keys())
else:
    print j
