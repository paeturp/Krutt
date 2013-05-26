#!/bin/sh
#
#
# 

html_begin()
{
# Do not remove any newlines in this block
cat << LAB_BEGIN
\\n\\nContent-type: text/html

<HTML>
    <HEAD>
       <TITLE>Message Log</TITLE>
    </HEAD>
  <BODY>
LAB_BEGIN
}

html_end()
{
cat << LAB_END
  </BODY>
</HTML>
LAB_END
}

html_sysinfo()
{

cat << LAB_INFO
<BR>
<pre>
`cat /etc/issue`

Hostname: `hostname`
Date: `/bin/date`

</pre>
LAB_INFO
}




html_begin

html_sysinfo

# echo $QUERY_STRING
VAR=`echo $QUERY_STRING | tr -cd '[[:alpha:]]'`

# Output in the block is plane ascii text
echo "<BR><pre>" 

case "${VAR}" in
    netstat)
         netstat -l -u -t -n -a
         ;;

    ps)
         ps
         ;;

    dmesg)
         dmesg
         ;;

    clearmsg)
         echo "Message log is now cleared" 
         echo "" > /var/log/messages.0
         echo "" > /var/log/messages 
         ;;
  
    *)
         if [ -e /var/log/messages.0 ]
         then
             cat /var/log/messages.0 /var/log/messages
         else
             cat /var/log/messages 
         fi
         ;;
esac
echo "</pre>"

html_end

