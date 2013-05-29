#!/bin/bash
#
#
#
set -x
VERSION="1.00.02"
HERE=`pwd`
BR="buildroot"



function help()
{
cat << LAB_HELP

    Buildroot is now ready to build the project.

       Goto directory ${BR} and type make pandaboard_krutt_defconfig and then make to start the build.


LAB_HELP
}


# Copy board into buildroot 
function reinstall()
{
    local outfile="Config.in.new"

    # Copy board into buildroot
    cd ${HERE}
    tar --exclude=.git -cf - configs/ | (cd ../${BR}; tar -xvf -) 
    tar --exclude=.git -cf - board/   | (cd ../${BR}; tar -xvf -) 
    tar --exclude=.git --exclude=.gitkeep -cf - package/ | (cd ../${BR}; tar -xvf -)
   
    # Add new package into the buildroot menu
    local bname="Krutt"
    if [ `grep -i ${bname} ../${BR}/package/Config.in | wc -l ` -eq 0 ]
    then 
        if [ `ls package | wc -l ` -ne 0 ]
        then
          local pkglist=`ls package`

          local numberofendmenu=`grep ^endmenu ../${BR}/package/Config.in | wc -l`

          cat ../${BR}/package/Config.in | awk -v bb=$numberofendmenu '
                                !/^endmenu/ { print } 
                                /^endmenu/ && (++c != bb) { print } 
                                ' > $outfile
          echo "menu \"${bname} utils\" " >> $outfile
          for pk in ${pkglist}
          do 
             echo "source \"package/${pk}/Config.in\" " >> $outfile
          done

          echo "endmenu" >> $outfile
          echo "" >> $outfile
          echo "endmenu "  >> $outfile

          cp $outfile ../${BR}/package/Config.in
          rm $outfile
        fi
    fi
}

# Install buildroot 
cd ..

reinstall

