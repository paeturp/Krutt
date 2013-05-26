#!/bin/bash
#
#
# set -x

CFILE="cscope.files"
CSFILE="cscope.files.sorted"
COFILE="cscope.out"
CTAGS="tags"

if [ "$1" == "clean" ]
then
    for f in ${CTAGS} ${COFILE} ${CFILE}
    do
        if [ -e "$f" ]
        then
            rm $f
        fi
    done 
    exit 0
fi 


find | grep "\.c$\|\.h$" | grep "\.\/arch\/arm"        >  ${CFILE}
find | grep "\.c$\|\.h$" | grep "\.\/fs"               >> ${CFILE}
find | grep "\.c$\|\.h$" | grep "\.\/mm"               >> ${CFILE}
find | grep "\.c$\|\.h$" | grep "\.\/include\/asm-arm" >> ${CFILE}
find | grep "\.c$\|\.h$" | grep "\.\/include" | grep -v "\.\/include\/asm-" | grep -v "\.\/include\/config\/" >> ${CFILE}
find | grep "\.c$\|\.h$" | grep "\.\/kernel"           >> ${CFILE}
find | grep "\.c$\|\.h$" | grep "\.\/block"            >> ${CFILE}
find | grep "\.c$\|\.h$" | grep "\.\/lib"              >> ${CFILE}

sort ${CFILE} > ${CSFILE}

mv ${CSFILE} ${CFILE}

# The second script (gentagdb).

# gentagdb database build script
cscope -b

ctags -L ${CFILE}

