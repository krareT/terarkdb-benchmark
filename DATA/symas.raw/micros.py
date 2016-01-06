#!/usr/bin/python -tt

"""Convert Symas' ops/sec into the micros/op output
reported by the db_bench output.

Any line that does not contain ops/sec will just be written out unchanged.
"""

import sys

# Take the data from Symas which only lists ops/sec or
# entries/sec and append micros/op for comparison to db_bench output.
def raw_out(infile, outfile):
    inf = open(infile, 'r')
    onf = open(outfile, 'w')
    sec = 1000000
    conv1 = 'ops/sec'
    conv2 = 'entries/sec'
    for line in inf:
        # Write the line no matter what.
        # Then determine if it is a ops/sec line and add micros/op if needed.
        if conv1 in line or conv2 in line:
            lstr = line.split()
            prev = ""
            for word in lstr:
                newstr = word + ' '
                onf.write(newstr)
                if word == conv1 or word == conv2:
                    raw = format(float(sec) / float(prev), '.4f')
                    newstr = '\t' + raw + ' micros/op\n'
                    onf.write(newstr)
                else:
                    prev = word
        else:
            onf.write(line)
    inf.close()
    onf.close()

###
def main():
  if len(sys.argv) != 3:
    print 'usage: ./' + sys.argv[0] + 'infile outfile'
    sys.exit(1)

  infile = sys.argv[1]
  outfile = sys.argv[2]
  raw_out(infile, outfile)
  sys.exit(1)

if __name__ == '__main__':
  main()
