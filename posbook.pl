#!/usr/bin/perl -w
#use NYT::machine_mail;
################################################################################
#     date     init     reason                                                 #
#  06/11/2012  AL      bkarea dw-ny or ds-ny append bkarea to catg             #
#                      catg spt_dr,spt_fp,sptw_dr,sptw_fp change to SPT        #
#                                                                              #
#  04/02/2012  AL      create a file for the section front feed web page       #
#                      this will run a script that pulls ads from ADMAN for    #
#                      the next 30 days and create an xml file. This xml file  #
#                      will then be extracted from via a perl program that     #
#                      uses 2 translation tables to use as drivers. After the  #
#                      tab delimited file is created it will be passed to a    #
#                      that the web page will use.                             #
#                                                                              #
#  04/20/2015  HP      changed the folder from Position_Book_In to             #
#                      Position_Book_Out. Modified to copy the jpg file        #
#                      instead of eps file.                                    #
################################################################################
use strict;
use warnings;
use XML::DOM;
use File::Copy;
use Date::Calc qw(Today_and_Now  Day_of_Week Day_of_Week_to_Text Date_to_Text  Date_to_Text_Long );
#use NYT::machine_mail;
####################
#  define fields   #
####################
my $LOG_ROOT = "/PPI/logdir/ppi/logs/";
#my $bkfile = "/PPI/media/ppi/scripts.custom/bkfile.txt";
my $bkfile = "/PPI/media/ppi/scripts.custom/bkarea.txt";
my $catgfile = "/PPI/media/ppi/scripts.custom/category.txt";
my ($file, $parser, $doc, $tabfile, $coloursize, $fname, $keyword, $fldname);
my ($folderpath, $exid, $catg, $cust, $hgt, $wid, $feat, $signal, $iss, $bkarea);
my ($sptcatg, $jobmulti, $strfname, $filetobecopied, $newfile);
my @found;
my (@colour, @bkarray, @catgarray);
my $ny = "NY";

#my $outputfolder="PPI/production/import/SectionCalendar/";
#my $outputfolder='nytppisapfs.nyhq.nytint.com/PPI/production/asura_input/Position_Book_In/';
#my $outputfolder='/PPI/production/asura_input/Position_Book_In/';
my $outputfolder='/PPI/production/asura_input/Position_Book_Out/';
#my $MAILLIST="lopomaj@nytimes.com walshd@nytimes.com goldsrm@nytimes.com aghah@nytimes.com pubsup@nytimes.com"
#my $MAILLIST="lopomaj@nytimes.com"
#my $SUBJECT="Section Front process has aborted -- Please check log:";
#
#
###################################################
#####   print info to log file                    #
###################################################
sub printlog1 {
    my ($message) = @_;
    my ($year, $month, $day, $hour, $minute, $second) = Today_and_Now();
    my $log_date = sprintf("%4d%02d%02d", $year, $month, $day);
    my $date = Date_to_Text_Long($year, $month, $day);
    my $now = sprintf("%02d:%02d:%02d", $hour, $minute, $second);
  	my $LOG1 = "$LOG_ROOT"."SectFront"."_"."$log_date".".log";
	open(LOG1, ">> $LOG1") || die "Can't create $LOG1\n";
	print LOG1 "[$date, $now]: $message\n";
	close LOG1;
}

############################################
#    send email                            #
############################################
#sub sendemail {
#    my ($LTR) = @_;
#	&machine_mail::machine_mail("$LTR", "", "$SUBJECT", "", "$MAILLIST");
# }   
###################################################################
#   read directory for all eps files and take the latest file     #
#   99999.?.eps                                                   #
###################################################################
sub getEPSData {
    #print "Subs passed :@_ \n";
	my ($dirname, $holdeps, $dirsize, $f, $epsnbr, $holdfname, $fnamefound, $jpg);
	my @files;
	$fnamefound="";
	#$dirname = @_[0];
	$dirname = $_[0];
	opendir(D1, $dirname) or die "@_ Directory cannot be opened.";
	#&machine_mail::machine_mail("$LTR", "", "$SUBJECT1", "", "$MAILLIST");
	#my $LTR="The ";
	#@files = grep(/\.eps/, readdir(D1));
	@files = grep(/\.jpg/, readdir(D1));
    #print "files: @files\n";
	closedir(D1);
	$holdeps = 0;
	$dirsize = @_;
	foreach $f (@files) {
	#    print "filename is: $f\n";
		#($epsnbr) = (split(/\./, $f))[1];
		($epsnbr, $jpg) = (split(/\./, $f))[1,2];
		#if ($epsnbr > $holdeps) {
		if (($epsnbr > $holdeps) && ($jpg eq 'jpg')) {
		    $holdeps = $epsnbr;
			$holdfname = $f;
			$fnamefound = "Y";
		}
	}
    #print "after loop: $holdfname \n";	
	#print "fnamefound: $fnamefound\n"; 
	if ($fnamefound eq "Y") {
	    return $holdfname;
        }
    else {
        return "UNDEF";
        }		
}
###########################################################
#    create object for xml parser                         #
###########################################################	
$file = $ARGV[0];
$parser = XML::DOM::Parser->new();
$doc = $parser->parsefile($file);

#############################################################
#    open booking area control file                         #
#############################################################
&printlog1("Opening $bkfile \n");
#open INPUT, "$bkfile" or die("cant open booking area  $bkfile: $!");
unless (open (INPUT, "$bkfile")) {
   #&sendemail("The booking file $bkfile failed to open)";
   print "Failure to open $bkfile - program is stopping";
   exit;
   }
while (<INPUT>) {
	chomp;
	#print "1:  $_\n";
	push(@bkarray , $_);
				}
close INPUT;
##############################################################
#    open category control file                              #
##############################################################
&printlog1("Opening $catgfile file \n");
#open INPUT, "$catgfile" or die("cant open category  $catgfile: $!");
unless (open (INPUT, "$catgfile")) {
   #&sendemail("The category file $catgfile failed to open)";
   print "Failure to open $catgfile - program is stopping";
   exit;
   }
while (<INPUT>) {
	chomp;
	#print "2: $_\n";
	push(@catgarray , $_);
				}
close INPUT;
#
##############################################################
#  get parts of xml file                                     #
##############################################################
$tabfile = $ARGV[1];
#print "$ARGV[1]";
#open(OUT,">$tabfile") or die("cant open $tabfile: $!");
unless (open (OUT, ">$tabfile")) {
   #&sendemail("The output file $tabfile failed to open)";
   print "Failure to open $tabfile - program is stopping";
   exit;
   }
foreach my $job ($doc->getElementsByTagName('Job')){
#check if color ad or not
	@colour =  ($job->getElementsByTagName('Colour'));
	$coloursize = scalar (@colour);
	$folderpath = $job->getAttribute('FolderPath');					
	$exid = $job->getAttribute('ExternalId');
	$catg = $job->getAttribute('Category');
	$cust = $job->getElementsByTagName('Customer')->item(0)
				->getAttribute('Name');
	$hgt =  $job->getAttribute('Height');
	$wid =  $job->getAttribute('Width');
	$feat = $job->getElementsByTagName('Feature')->item(1)
				->getAttribute('Id');
	$signal =  $job->getElementsByTagName('Feature')->item(1)
				->getAttribute('Signal');
	$keyword =  $job->getAttribute('Caption');			
#
	if ($catg eq "") {
	    $catg = "@@@@@"; 
	}		
	foreach  my $jobmulti ($job->getElementsByTagName('Connexion')){
		$iss = $jobmulti->getAttribute('DateOfIssue');
		$bkarea = $jobmulti->getAttribute('BookingArea');
		if ($bkarea eq "") {
		    $bkarea = "@@@@@"; 
		}		
#al 06/11/2012		
		if ($catg eq "SPT_DR" or $catg eq "SPT_FP" or $catg eq "SPTW_DR" or $catg eq "SPTW_FP") {
		    $sptcatg = "SPT";
		}
		else {
		    $sptcatg =  $catg;
		}     
		
		if((@found = grep(/\b$catg\b/,@catgarray)) and (@found = grep(/\b$bkarea\b/,@bkarray))) {
		        #print "passed: $catg $bkarea\n";
			print OUT "$iss \t";
			if (($sptcatg eq "SPT") and ($bkarea eq "DW-NY" or $bkarea eq "D-NY" or $bkarea eq "DS-NY")) {
			        print OUT "$sptcatg$ny \t";
			}
			else {
				if ($catg eq "REG_PG1" or $catg eq "MDS") {
					print OUT "$sptcatg$bkarea \t";
				}		
				else {
					print OUT "$sptcatg \t";
				}
			}
			print OUT "$cust \t";
			print OUT "$keyword \t";
			print OUT "$exid \t";
			print OUT "$signal \t";
			if ($coloursize > 0) {
				print OUT "4C \n"; 
		    }
			else {
				print OUT "  \n";
	        }
			$fname = getEPSData($folderpath);
			#print "copy file: $fname\n";
			&printlog1("Processing Job# $exid ");
			if ($fname ne "UNDEF") {
				#print "file to copy is $fname\n";
				$strfname = $fname;
				$strfname =~ s/\.\d//;
				$filetobecopied = $folderpath.$fname;
				$newfile = $outputfolder.$strfname;
				#&printlog1("Copying $filetobecopied to $newfile");
				copy($filetobecopied, $newfile) or die "$filetobecopied -- cannot be copied to -- $newfile";
				#copy($filetobecopied, $newfile);
		     }
        }
	}
        }
#	
#  foreach  my $jobmulti2 ($job->getElementsByTagName('ConnexionList\/')){
#     print "====This ad cancelled==== $exid\n"; }	
#}	
close OUT;
