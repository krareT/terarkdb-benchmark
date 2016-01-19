#!/usr/bin/python -tt

"""Add raw output benchmark from local runs to the input file template.
Run with 'addraw.py datatemplate runfile1 runfile2...'
It will add each item from each runfile to the appropriate category
and write the result to stdout.
"""

import re
import sys

def parse_raw(rawfile):
    rawf = open(rawfile, 'r')
    rawdata = {}
    for line in rawf:
        words = line.split()
        # Create a dict of key: opname value: micros/op-number
        if len(words) > 2 and words[1] == ':':
            rawdata[words[0]] = words[2]
    rawf.close()
    return rawdata


def add_newdata(infile, rawdicts):
    inf = open(infile, 'r')
    sec = 1000000
    op = ""
    r = re.compile(r'\((.+)\)')
    for line in inf:
        # First find the operation, then append our lines after the op line.
        # Write the line no matter what.
        print line,
        if op == "":
            opmatch = r.search(line)
            if opmatch:
                op = opmatch.group(1)
        if op != "":
            for rawfile in rawdicts:
                # We just printed the op line.  Now construct our new
                # line to write after the op line.  The line looks like:
                # name value ops/sec value micros/op
                raw = rawdicts[rawfile]
                if op in raw:
                    rawval = raw[op]
                    opsval = format(round(float(sec) / float(rawval)), '.0f')
                    newline = rawfile + ' ' + opsval + ' ops/sec\t' + rawval + ' micros/op'
                    print newline
            op = ""
    inf.close()

###
def main():
  numargs = len(sys.argv)
  if numargs < 3:
    print 'usage: ./' + sys.argv[0] + 'infile datafile1...'
    sys.exit(1)

  infile = sys.argv[1]
  d = 2
  rawdicts = {}
  while d < numargs:
    rawfile = sys.argv[d]
    raw = parse_raw(rawfile)
    #
    # Look for a Symas-specific operation to confirm this output is
    # from a run of a symas-configured program.  One would be
    # 'fillseqbatch'.
    #
    # if 'fillseqbatch' in raw:
    rawdicts[rawfile] = raw
    # else:
    #     print rawfile + ' is not symas configured.'
    d += 1
  add_newdata(infile, rawdicts)
  sys.exit(1)

if __name__ == '__main__':
  main()
