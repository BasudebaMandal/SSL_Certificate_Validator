#!/bin/bash
###################################################
######  Author/Developer : Basudeba Mandal  #######
###################################################

cur_time=`date +%Y%m%d%H%M%S`
scriptName=`basename $0 | awk -F".sh" '{print $1}'`
File=$0
if [ `echo $File | grep -c "/"` -eq 0 ]; then
     scriptBaseDir=`pwd`
else
     scriptBaseDir="${File%/*}"
fi
cd $scriptBaseDir
. $scriptBaseDir/ssl.properties
logDir=$scriptBaseDir/log
if [ ! -d $logDir ]; then
        mkdir -p $logDir
else
        logDir=$logDir
fi
logFile=CertMonitor"_"${cur_time}".log"

echo $(date +'%a %h %d %T %Y') '<INFO> Certificate Exipry verification is Started. ' >> $logDir/$logFile

ls -lrt $certhome/*.$ext | awk  '{print $9}' > /tmp/certinfo.txt
date2find() {

    if [ "${1}" != "" ] && [ "${2}" != "" ] && [ "${3}" != "" ]
    then
        ## Since leap years add aday at the end of February,
        ## calculations are done from 1 March 0000 (a fictional year)
        d2j_tmpmonth=$((12 * ${3} + ${1} - 3))

        ## If it is not yet March, the year is changed to the previous year
        d2j_tmpyear=$(( ${d2j_tmpmonth} / 12))

        ## The number of days from 1 March 0000 is calculated
        ## and the number of days from 1 Jan. 4713BC is added
        echo $(( (734 * ${d2j_tmpmonth} + 15) / 24
                 - 2 * ${d2j_tmpyear} + ${d2j_tmpyear}/4
                 - ${d2j_tmpyear}/100 + ${d2j_tmpyear}/400 + $2 + 1721119 ))
    else
        echo 0
    fi
}
DATE=$(which date)
MONTH=$(${DATE} "+%m")
DAY=$(${DATE} "+%d")
YEAR=$(${DATE} "+%Y")
NOWJULIAN=$(date2find ${MONTH#0} ${DAY#0} ${YEAR})
echo $NOWJULIAN
getmonth()
{
    case ${1} in
        Jan) echo 1 ;;
        Feb) echo 2 ;;
        Mar) echo 3 ;;
        Apr) echo 4 ;;
        May) echo 5 ;;
        Jun) echo 6 ;;
        Jul) echo 7 ;;
        Aug) echo 8 ;;
        Sep) echo 9 ;;
        Oct) echo 10 ;;
        Nov) echo 11 ;;
       Dec) echo 12 ;;
          *) echo 0 ;;
    esac
}
function mailstruct() {
    echo $Greet
    echo ""
    echo $Subj
    echo ""
    echo $Sign1
    echo $Sign2
}
date_diff()
{
    if [ "${1}" != "" ] && [ "${2}" != "" ]
    then
        echo $((${2} - ${1}))
    else
        echo 0
    fi
}
>/tmp/cert.csv
while read cer; do
CERTDATE=`openssl x509 -in $cer -enddate -noout | sed 's/notAfter\=//'`
CertExp=`openssl x509 -in $cer -enddate -noout | sed 's/notAfter\=//' | awk '{print $2,$1,$4}'`
ComN=`openssl x509 -in $cer -subject -noout | sed -e 's/.*CN=//' | sed -e 's/\/.*//'`
IniCom=`openssl x509 -in $cer -subject -noout | sed -e 's/.*CN=//' | sed -e 's/\/.*//' | awk -F "." {'print $1'}`
OrgU=`openssl x509 -in $cer -subject -noout | sed -e 's/.*OU=//' | sed -e 's/\/.*//'`
Org=`openssl x509 -in $cer -subject -noout | sed -e 's/.*O=//' | sed -e 's/\/.*//'`
Loc=`openssl x509 -in $cer -subject -noout | sed -e 's/.*L=//' | sed -e 's/\/.*//'`
Cou=`openssl x509 -in $cer -subject -noout | sed -e 's/.*C=//' | sed -e 's/\/.*//'`
sleep 1
set -- ${CERTDATE}
MONTH=$(getmonth ${1})
CERTJULIAN=$(date2find ${MONTH#0} ${2#0} ${4})
#echo $CERTJULIAN
CERTDIFF=$(date_diff ${NOWJULIAN} ${CERTJULIAN})
#echo $CERTDIFF
 if [ "$CERTDIFF" -lt "$ThresTime" ]
    then
    echo $Env:$ComN:$CertExp >> /tmp/cert.csv
   if [ -d "$scriptBaseDir/CSR/$IniCom" ]
     then
     echo $(date +'%a %h %d %T %Y') '<INFO> Certificate with CN '$ComN' has already been validated and email has been sent. ' >> $logDir/$logFile
     else
     echo $(date +'%a %h %d %T %Y') '<INFO> Certificate with CN '$ComN' is getting expired in '$Env'. ' >> $logDir/$logFile
     echo $(date +'%a %h %d %T %Y') '<INFO> Since Certificate is getting expired, Proceeding with CSR and Key generation. ' >> $logDir/$logFile
     mkdir -p $scriptBaseDir/CSR/$IniCom
     mkdir -p $scriptBaseDir/$IniCom
     openssl req -nodes -newkey rsa:2048 -keyout $scriptBaseDir/CSR/$IniCom/$ComN.key -out $scriptBaseDir/CSR/$IniCom/$ComN.csr -subj "/C=$Cou/L=$Loc/O=$Org/OU=$OrgU/CN=$ComN"
     sleep 1
     csrmd= openssl req -noout -modulus -in $scriptBaseDir/CSR/$IniCom/$ComN.csr | openssl md5 | awk {'print $2'}
     keymd= openssl rsa -noout -modulus -in $scriptBaseDir/CSR/$IniCom/$ComN.key | openssl md5 | awk {'print $2'}
     if [ ${csrmd} -eq ${keymd} ]
     then
     sleep 1
     cp -rp $scriptBaseDir/CSR/$IniCom/$ComN.csr  $scriptBaseDir/$IniCom/
     echo $(date +'%a %h %d %T %Y') '<INFO> Pair of CSR and Key with CN '$ComN' has been generated and stored in directory '$IniCom'. ' >> $logDir/$logFile
     tar -cvf $scriptBaseDir/$IniCom.tar $scriptBaseDir/$IniCom
             if [ -f "$scriptBaseDir/$IniCom.tar" ]
             then
             mailstruct | mutt -s "Certificate with CN '$ComN' is getting expired"  -c ${Cced}  ${Reciever} -a $scriptBaseDir/$IniCom.tar
             sleep 2
             rm -rf $scriptBaseDir/$IniCom.tar
             rm -rf $scriptBaseDir/$IniCom
              echo $(date +'%a %h %d %T %Y') '<INFO> An email alert has been sent with relevent CSR . ' >> $logDir/$logFile
             else
             echo $(date +'%a %h %d %T %Y') '<ERROR> Exception in zipping CSR and Key. ' >> $logDir/$logFile
             fi
     else
     echo $(date +'%a %h %d %T %Y') '<ERROR> Md5sum value of CSR and key does not match ' >> $logDir/$logFile
     fi

    sleep 2
   fi
 else
   echo $(date +'%a %h %d %T %Y') '<INFO> Certificate with CN '$ComN' is in its validity. ' >> $logDir/$logFile
   echo $Env:$ComN:$CertExp >> /tmp/cert.csv
  fi
done </tmp/certinfo.txt
rm -rf /tmp/certinfo.txt

#input="input.csv"
>$scriptBaseDir/$Env.html
echo "<html><head><title></title></head><body><table border=2 bgcolor=pink>" >> $scriptBaseDir/$Env.html
echo "<tr><th>Environment</th><th>Domain</th><th>Expiry</th></tr>" >> $scriptBaseDir/$Env.html
while IFS=':' read -r f1 f2 f3
do
  echo "<tr><td>$f1</td><td>$f2</td><td>$f3</td></tr>" >> $scriptBaseDir/$Env.html
done < /tmp/cert.csv
echo "</table></body></html>" >> $scriptBaseDir/$Env.html
sleep 3
rm -rf /tmp/cert.csv
scp -rp $scriptBaseDir/$Env.html $docroot
