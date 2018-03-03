#!/usr/bin/python

import json
import sys
import os


lines = sys.stdin.readlines()

data2 = json.loads(lines[0])
data2['pools'][0]['url'] = sys.argv[2]
data2['algo'] = sys.argv[1]

out= str.replace(json.dumps(data2,separators=(',', ':')   ),"//","\/\/")

print "CCMINERCONF='" + out + "'"
