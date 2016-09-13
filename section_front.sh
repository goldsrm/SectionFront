#!/bin/bash
#
# Run XML report for Section Front web page 
# $ADMAN/scripts.custom/startPbookExporter <YYYYMMDD> <YYYYMMDD>
#
#
#
#THIRTYDATE=$(perl -e '@list = ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst)=localtime(time() + 15552000);' -e '$year += 1900;' -e 'printf qq{Date:\t%02d%02d%02d}, $year, ++$mon, $day;')
#TODAYDATE=$(perl -e '@list = ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst)=localtime(time());' -e '$year += 1900;' -e 'printf qq{Date:\t%02d%02d%02d}, $year, ++$mon, $day;')
THIRTYDATE=$(perl -e '@list = ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst)=localtime(time() + 3888000);' -e '$year += 1900;' -e 'printf qq{%02d%02d%02d}, $year, ++$mon, $day;')
TODAYDATE=$(perl -e '@list = ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst)=localtime(time() + 86400);' -e '$year += 1900;' -e 'printf qq{%02d%02d%02d}, $year, ++$mon, $day;')
#
#echo "Today: $TODAYDATE"
#echo "30day: $THIRTYDATE"
#OVERRIDE
#THIRTYDATE=20120930
#TODAYDATE=20120901
echo "Today: $TODAYDATE"
echo "30day: $THIRTYDATE"
#
SCPDIR=/PPI/adman/xmlExportpbook/xmlExportpbookAudits$TODAYDATE-$THIRTYDATE
#
/PPI/media/ppi/adman/scripts.custom/startPbookExporter $TODAYDATE $THIRTYDATE
#
perl /PPI/media/ppi/scripts.custom/posbook.pl $SCPDIR/Export.xml /PPI/production/export/section_calendar/I462_INBOUND_FILE_SECTFRONT.txt
cp -p /PPI/production/export/section_calendar/I462_INBOUND_FILE_SECTFRONT.txt /PPI/production/export/AOC_section_calendar/I462_INBOUND_FILE_SECTFRONT.txt
echo "PPI Section Front is done"
#sleep 1
#
