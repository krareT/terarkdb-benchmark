#!/usr/bin/python -tt

help = """Take raw output from benchmark from local runs and create gnuplot
ready data.  If there are more than 2 files with any given suffix,
it tosses the high and the low values for each operation type and averages
the rest of them to get a single value.

Run with 'plot.py outfileprefix runfile1 runfile2...'

We expect that you provide runfiles from the same workload configuration,
e.g., 'big', 'bigval', etc for the LevelDB benchmarks. We currently do not
support comparing performance across workloads. So it's logical to specify
the workload name as part of the outfileprefix.

You can give the following mixes of runfiles:

1) The runfiles for the same DB, but different thread numbers. In this
case we will generate a histogram chart.

Example: ./plot.py big big.*.WTlsm.*

2) The runfiles for different DBs, but a fixed thread number. In this case
we will generate a histogram chart.

Example: ./plot.py big big.*.*.2

3) The runfiles for different DBs and different thread numbers. In this case
we will generate a line plot with multiple lines per plot (one for each DB),
and thread numbers on the x-axis.

Example: ./plot.py big big.*.*


"""

import time
from datetime import date

from os import system
import os.path

import re
import sys

imageFileNames = []

def parse_raw(rawfile):
    rawf = open(rawfile, 'r')
    rawdata = {}
    for line in rawf:
        words = line.split()

        # Create a dict of key: opname value: micros/op-number
        # Conveniently, the benchmark often runs the same operations
        # multiple times (i.e. to prime the cache) and we take only
        # the last value.
        if len(words) > 2 and words[1] == ':':
            rawdata[words[0]] = words[2]

    rawf.close()
    return rawdata

###
#
# We get each line preceding the separator "-------------",
# and append them to the list, which we return.
#
def get_header_lines(rawfilename):

    lineList = []
    rawf = open(rawfilename, 'r')
    for line in rawf:
        if line.startswith("-------------"):
            return lineList
        else:
            lineList.append(line)

    # Hopefully we don't get there, otherwise the file
    # format is probably wrong.
    print("WARNING: iterated through the file without encountering the "
          "separator.")
    return lineList


def getavg(rawdicts, rawnames):
    newdict = {}
    sec = 1000000
    #
    # Rawnames is a dict where the key is the suffix, like '16' or
    # 'WTlsm, and the value is a list of all filenames with that suffix.
    #
    for ftype in rawnames:
        opsdict = {}
        flist = rawnames[ftype]
        #
        # Go through each op/value pair for each filename in there and
        # build up a list of one op: list of values from all files.
        #
        for fname in flist:
            rawfiledata = rawdicts[fname]
            for op in rawfiledata:
                if not op in opsdict:
                    opsdict[op] = []
                opsdict[op].append(rawfiledata[op])
        print opsdict
        opsavg = {}
        for ops in opsdict:
            # Now generate a single average value for each operation.
            # TODO (Sasha): Hmm, not sure about this. I think we
            # shouldn't remove min and max, but instead keep track of
            # the standard deviation.
            vals = opsdict[ops]
            if len(vals) > 2:
                 # If we have enough samples remove the min and max.
                 vals.remove(min(vals))
                 vals.remove(max(vals))
            sum = 0.0
            for v in vals:
                 sum += float(v)
            val = format(round(float(sec) / (sum/len(vals))), '.0f')
            opsavg[ops] = val
        newdict[ftype] = opsavg
    return newdict

#
# Generate the gnuplot file.  We don't use gnuplot.py here because that
# has not been updated since 2008!  Some of the things we want to do need
# a later version of gnuplot (this was first generated to work with gnuplot 4.6
# and is known to fail with gnuplot 4.2).
#
def gen_2D_gnuplot(opfx, dname, op, fixedparamStr, glist):
    fname = opfx + '.' + op + '.gnu'
    fd = open(fname, 'w+')
    fd.write('set title "LevelDB benchmark - ' + op + ". " + fixedparamStr +
             " (" + opfx + ")" + '"\n')
    fd.write('set terminal gif medium\n')
    jname = opfx + '.' + op + '.gif'
    imageFileNames.append(jname)
    fd.write('set output "' + jname + '"\n')
    fd.write('set border 3 front linetype -1 linewidth 1.000\n')
    fd.write('set style data histogram\n')
    fd.write('set format y "%9.0f"\n')
    fd.write('set xlabel "DB Source"\n')
    fd.write('set ylabel "Operations/sec per thread"\n')
    fd.write('set yrange [0:]\n')
    fd.write('set grid\n')
    fd.write('set boxwidth 0.5 relative\n')
    fd.write('set style fill transparent solid 0.5 noborder\n')
    fd.write('plot "' + dname + '" u ($0):2:($0):xticlabels(1) w boxes lc variable notitle\n')
    fd.close
    glist.append(fname)

###
def generate_2D_data(rawdicts, varnames, varnameStr, fixednameStr, opfx):
    
    opsdict = getavg(rawdicts, varnames)
    gnulist = []

    # Let's determine if the keys are integers.
    # This will tell us how to sort them. 
    sortedKeys = opsdict.keys()
    try:
        float(opsdict.keys()[0])
        sortedKeys.sort(key=int)
    except:
        sortedKeys.sort(key=str)

    for dtype in sortedKeys:
        ops = opsdict[dtype]
        for op in ops:
            fname = opfx + '.' + op + '.res'
            exists = os.path.exists(fname)
            fd = open(fname, 'a')
            if not exists:
                fd.write("# " + varnameStr + "\tOps/sec\n")
                gen_2D_gnuplot(opfx, fname, op, fixednameStr, gnulist)
            fd.write(dtype + '\t' + str(ops[op]) + '\n')
            fd.flush()
            fd.close

    print gnulist
    print 'Running gnuplot'
    for script in gnulist:
        cmd = ("gnuplot < %s" % script)
        print 'Executing ' + cmd
        system(cmd)

#
# Generate the gnuplot file.  We don't use gnuplot.py here because that
# has not been updated since 2008!  Some of the things we want to do need
# a later version of gnuplot (this was first generated to work with gnuplot 4.6
# and is known to fail with gnuplot 4.2).
#
def gen_3D_gnuplot(opfx, resfilename, op, dbnames, glist):
    fname = opfx + '.' + op + '.gnu'
    fd = open(fname, 'w+')
    fd.write('set title "LevelDB benchmark - ' + op + ". " +
             " (" + opfx + ")" + '"\n')
    fd.write('set terminal gif medium\n')
    jname = opfx + '.' + op + '.gif'
    imageFileNames.append(jname)
    fd.write('set output "' + jname + '"\n')
    
    fd.write('set border 3 front linetype -1 linewidth 1.000\n')
    fd.write('set style data linespoints\n')
    fd.write('set format y "%9.0f"\n')
    fd.write('set xlabel "Thread count"\n')
    fd.write('set ylabel "Operations/sec"\n')
    fd.write('set yrange [0:]\n')
    fd.write('set grid\n')
    fd.write('set boxwidth 0.5 relative\n')
    fd.write('set style fill transparent solid 0.5 noborder\n')

    fd.write("plot");
    d = 2    
    for db in dbnames:
        fd.write(' "' + resfilename + '" using 1:' + str(d) + ' title "'
                 + db + '" with lines');
        if(db != dbnames[-1]):
            fd.write(",")
        else:
            fd.write("\n")
            
        d = d+1
    #fd.write('plot "' + dname + '" u ($0):2:($0):xticlabels(1) w boxes lc variable notitle\n')
    fd.close
    glist.append(fname)

###
#        
# Here we generate plots for 3D data, i.e., if we have multiple
# DBs and multiple threads for each DB. The result will be a line plot
# with one line per DB, and the thread count varying across the
# x-axis.
#
# The dictionary threadcounts is keyed on threadcount.
# The value is the dictionary of all DBs. That second
# dictionary is keyed on the DB name. The value is the
# list of all file names corresponding to that DB and
# that thread count. 
#
def generate_3D_data(rawdicts, threadcountsForEachDB, opfx):

    # This dictionary will be keyed on threadcounts. The value
    # is the opsdict for each threadcount. Opsdict is another dictionary
    # keyed on DB name. Each value in opsdict is a dictionary of
    # operations (like fill100K) and corresponding average ops/sec
    # for this operation, for this threadcount and DB.
    #
    allThreadcountOps = {}
    gnulist = []
    ops2dbs = {}

    # getavg computes the dictionary of ops/second for each operation
    # We must give it a dictionary of file names corresponding to a
    # specific thread count and a specific DB.
    #
    for threadcount in threadcountsForEachDB:

        allThreadcountOps[threadcount] = {}
        allThreadcountOps[threadcount] = getavg(rawdicts,
                                                threadcountsForEachDB[threadcount])

    for threadcount in allThreadcountOps:
        print("===================================================")
        print("+++ Ops dictionary for threadcount: " + threadcount);
        print("---------------------------------------------------")

        for db in allThreadcountOps[threadcount]:
            print("++++++ DB name is: " + db)
            print allThreadcountOps[threadcount][db]

    #    
    # Now, we can have a situation where an operation (e.g., fill100K)
    # would have data for some of the DBs, but not all of them. This is
    # because symas-configured benchmarks feature different ops than
    # others. We need to know the correspondence of ops to DBs before we
    # begin creating the data files, so we create the right headers and
    # don't put empty slots for DBs that do not exist. To accomplish that
    # we create a reverse dictionary, keyed by op names, where DB names
    # are values.
    #
    for threadcount in sorted(allThreadcountOps.keys(), key=int):
        for db in allThreadcountOps[threadcount]:

            ops = allThreadcountOps[threadcount][db]

            for op in ops:
                if not op in ops2dbs:
                    ops2dbs[op] = []
                if db not in ops2dbs[op]: 
                    ops2dbs[op].append(db)

    # Now create the file for each op, and print the header row
    # with DB names.
    #
    for op in ops2dbs:
        fname = opfx + '.' + op + '.res'
        exists = os.path.exists(fname)
        if exists:
            print "File " + fname + " already exits. Exiting"
            sys.exit(-1);
            
        fd = open(fname, 'a')
        fd.write("# " + opfx + "\n")
        fd.write("# Thread#\t");

        for db in sorted(ops2dbs[op]):
            fd.write(db + "\t");

        fd.write("\n"); 
        fd.flush();
        fd.close();
        gen_3D_gnuplot(opfx, fname, op, sorted(ops2dbs[op]), gnulist)

    # Go over all threadcounts in the outer loop and all DBs in the inner
    # loop. For each operation type that we see, open the .res file and print data
    # into that file. We will have one row for each thread count. All DBs will
    # be in the columns. The .res file must exist, because we just created it
    # in the previous loop.
    #    
    for threadcount in sorted(allThreadcountOps.keys(), key=int):

        print ("Writing data for threadcount " + threadcount);
        prevDBforThisOp = {}
        
        for db in sorted(allThreadcountOps[threadcount]):
            ops = allThreadcountOps[threadcount][db]
        
            for op in ops:
                fname = opfx + '.' + op + '.res'
                exists = os.path.exists(fname)
                fd = open(fname, 'a')
                if not exists:
                    print("Expecting file \"" + fname + "\" to exist,"
                          "but cannot find it. Exiting...");
                    sys.exit(-1);

                if(sorted(ops2dbs[op])[0] == db):
                    fd.write(threadcount + "\t");

                # See if there are any gaps in data,
                # if the previous DB for this thread count
                # should've had a value, but it was missing.
                gapSize = 0
                allDBsForThisOp = sorted(ops2dbs[op])
                myIndex = allDBsForThisOp.index(db)
                
                if op in prevDBforThisOp:
                    prevDB = prevDBforThisOp[op]
                    prevDBIndex = allDBsForThisOp.index(prevDB)
                    gapSize = myIndex - prevDBIndex
                else: # We are the first DB for this op
                    gapSize = myIndex

                if(gapSize > 1):
                    print("Gap size of " + str(gapSize) + " before " + db
                          + ", threadcount " + str(threadcount) + " op " + op)

                # We write '-' whenever we detect the missing data.
                # Otherwise gnuplot will displace the data and plot
                # the data for this DB in place of the missing value
                # for the previous DB.
                for i in range(1, gapSize):
                    fd.write("- \t");

                fd.write(ops[op] + "\t");
                
                # Let's see if we are the last DB, so we write
                # a newline character.
                if(sorted(ops2dbs[op])[-1] == db):
                    fd.write("\n");

                fd.flush();
                fd.close();

                # Remember the last DB that we saw for this op.
                # We need this to detect any gaps in data.
                prevDBforThisOp[op] = db

    print gnulist
    print 'Running gnuplot'
    for script in gnulist:
        cmd = ("gnuplot < %s" % script)
        print 'Executing ' + cmd
        system(cmd)


###
def show_fname_format_error(filename):
    print "File name format could be wrong for file:" + filename
    print "Valid file name format is:"
    print "\t workload.PID.COUNT.db.threadNum"
    print "Example:"
    print "\t big.19665.0.WTlsm.16"

###
def check_fname_format(dbname, threadNum):
    try:
        float(threadNum)
    except ValueError:
        print("ERROR: Thread number \"" + threadNum +
              "\" does not appear to be a number.")
        return False

    if(dbname == ""):
        return False

    return True

###
def show_unexpected_data_format_message():

    print("ERROR: Unexpected data format!")
    print(" We can have two kinds of data: 2D or 3D.");
    print(" For 2D data, the two examples are:");
    print("  a) a fixed thread count, but many DBs");
    print("  b) a fixed db, but many thread counts.");
    print(" For 2D data we want to generate histograms");
    print("");
    print(" For 3D data, we have multiple databases and");
    print(" multiple thread counts. For 3D data we want to");
    print(" generate line plots with threads on the x-axis and");
    print(" a line per DB.");

###
# Create an HTML page showing all the image files we created
#
def create_HTML(outfilepfx, imageFileNames, headerLines):

    htmlFileName = outfilepfx + ".html"
    
    if os.path.exists(htmlFileName):
        print("Output file " + htmlFileName + " already exists as a file")
        sys.exit(1)

    fd = open(htmlFileName, "w+");
    print("Writing HTML........ "
          "output file is " + htmlFileName);

    fd.write("<html>\n")
    fd.write("<head>\n")
    fd.write("<title> ")
    fd.write("LevelDB benchmark. Workload identifier: " + outfilepfx)
    fd.write(" </title>\n")
    fd.write("</head>\n")

    fd.write("<body>\n")
    fd.write("<h1>")
    fd.write("LevelDB benchmark. Workload identifier: " + outfilepfx
             + ". Date created: " + str(date.today()) + ".")
    fd.write("</h1>\n")

    # Now let's print all the headers with the information about DBs
    # that we ran.
    
    fd.write("<p>\n")
    for db in (sorted(headerLines)):
        fd.write("<h2>" + db + "</h2>\n")
        header = headerLines[db]
        for line in header:
            fd.write(line + "<br>\n")
        fd.write("<p>\n")

    # And now let's insert all the images
    for name in imageFileNames:
        fd.write("<img src =\"" + name + "\"/>\n");
        fd.write("<p>\n")

    fd.write("</body>\n")
    fd.write("</html>\n")

    fd.flush();
    fd.close();

###
def main():

    numargs = len(sys.argv)
    if numargs < 3:
        print 'usage: ./' + sys.argv[0] + ' outfilepfx datafile1...\n'
        print help
        sys.exit(1)

    outfilepfx = sys.argv[1]
    #
    # If the output file prefix exists as a file, it is likely the user
    # forgot and it really is the first datafile name instead.
    #
    if os.path.exists(outfilepfx):
        print 'output file prefix already exists as a file'
        sys.exit(1)
    d = 2
    
    rawdicts = {}
    dbnames = {}
    threadcounts = {}
    threadcountsForEachDB = {}

    headerLines = {}

    while d < numargs:
        rawfilename = sys.argv[d]
        
        # Create a dict containing this file's data.
        raw = parse_raw(rawfilename)

        fnameComponents = []
        fnameComponents = rawfilename.split(".");


        dbname = fnameComponents[len(fnameComponents)-2]
        threadNum = fnameComponents[len(fnameComponents)-1]

        if(check_fname_format(dbname, threadNum) == False):
            show_fname_format_error(rawfilename);
            sys.exit(-1);            

        # We can have two kinds of data: 2D or 3D.
        # For 2D data, the two examples are:
        #  a) a fixed thread count, but many DBs
        #  b) a fixed db, but many thread counts.
        # For 2D data we want to generate histograms.
        #
        # For 3D data, we have multiple databases and
        # multiple thread counts. For 3D data we want to
        # generate line plots with threads on the x-axis and
        # a line per DB.
        #
        # When we just begin parsing, we don't know what type
        # of data we have, so create three dictionaries just in case:
        # -- one keyed on DBnames for 2D case a)
        # -- one keyed on threadcount for 2D case b)
        # -- one keyed on threadcount containing a dictionary keyed on DB
        # for 3D data.
        #
        if not dbname in dbnames:
            dbnames[dbname] = []
            
            # From the raw data file, get some identifying
            # information about this DB and workload.
            # As per help message we assume that all input
            # files correspond to the same workload.
            headerLines[dbname] = get_header_lines(rawfilename)

        if not threadNum in threadcounts:
            threadcounts[threadNum] = []

        if not threadNum in threadcountsForEachDB:
            threadcountsForEachDB[threadNum] = {}
            
        if not dbname in threadcountsForEachDB[threadNum]:
            threadcountsForEachDB[threadNum][dbname] = []
        
        # Each file should only be there once.
        if not rawfilename in rawdicts:
            rawdicts[rawfilename] = raw
            dbnames[dbname].append(rawfilename)
            threadcounts[threadNum].append(rawfilename)
            threadcountsForEachDB[threadNum][dbname].append(rawfilename)
        d += 1

    # Now let's determine whether we have 2D or 3D data.
    if(len(dbnames) > 1 and len(threadcounts) > 1):
        print("We have 3D data")
        generate_3D_data(rawdicts, threadcountsForEachDB, outfilepfx)
    else: # 2D data -- let's deal with two sub-cases
        print("We have 2D data")
        if(len(dbnames) == 1 and len(threadcounts) > 1):
            print("We have a fixed DB and many threads")
            dbname = dbnames.keys()[0]
            fixedparamStr = "DB Name is " + dbname
            generate_2D_data(rawdicts, threadcounts, "ThreadCount", fixedparamStr,
                             outfilepfx)
            
        elif(len(dbnames) > 1 and len(threadcounts) == 1):
            print("We have a fixed thread count and many DBs")
            threadcount = threadcounts.keys()[0]
            fixedparamStr = "Thread count = " + str(threadcount)
            generate_2D_data(rawdicts, dbnames, "DBName", fixedparamStr,
                             outfilepfx)
            
        else:
            show_unexpected_data_format_message()
            sys.exit(1);

    # Generate an HTML page with all the chart images we created
    create_HTML(outfilepfx, imageFileNames, headerLines)

    sys.exit(0)

if __name__ == '__main__':
    main()
