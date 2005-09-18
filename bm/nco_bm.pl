#!/usr/bin/env perl

# $Header: /data/zender/nco_20150216/nco/bm/nco_bm.pl,v 1.92 2005-09-18 01:13:51 zender Exp $

# Usage:  usage(), below, has more information
# ~/nco/bm/nco_bm.pl # Tests all operators
# ~/nco/bm/nco_bm.pl ncra # Test one operator
# ~/nco/bm/nco_bm.pl --thr_nbr=2 --regress --udpreport # Test OpenMP
# ~/nco/bm/nco_bm.pl --mpi_prc=2 --regress --udpreport # Test MPI
# ~/nco/bm/nco_bm.pl --dap --regress --udpreport # Test OPeNDAP on sand
# ~/nco/bm/nco_bm.pl --dap=http://sand.ess.uci.edu/cgi-bin/dods/nph-dods/dodsdata --regress --udpreport # Test OPeNDAP on soot
# scp ~/nco/bm/nco_bm.pl esmf.ess.uci.edu:nco/bm

# NB: When adding tests, _be sure to use -O to overwrite files_
# Otherwise, script hangs waiting for interactive response to overwrite queries

# NB: when adding debugging messages, use dgb_msg(#,message);, where
#	# = the debug level at which the message should be emitted (2 will be seen at --debug=2)
#	message = a valid perl string to print. ie: "just before foo, \$blah = $blah"
#		the sub will prifix the message with DEBUG[#] and take care of adding a newline

require 5.6.1 or die "This script requires Perl version >= 5.6.1, stopped";
use Cwd 'abs_path';
use English; # WCS96 p. 403 makes incomprehensible Perl errors sort of comprehensible
use Getopt::Long; # GNU-style getopt #qw(:config no_ignore_case bundling);
use strict; # Protect all namespaces

# Declare vars for strict
use vars qw(
$arg_nbr  $bch_flg  $bm  @bm_cmd_ary  $bm_dir  $caseid  $cmd_ln
$dbg_lvl  $dodap  $dot_fmt  $dot_nbr  $dot_nbr_min  $dot_sng  $dsc_fmt
$dsc_lng_max  $dsc_sng  $dta_dir  %failure  $fl_cnt  @fl_cr8_dat
$fl_pth  @fl_tmg  $foo1_fl  $foo2_fl  $foo_avg_fl  $foo_fl  $foo_T42_fl
$foo_tst  $foo_x_fl  $foo_xy_fl  $foo_xymyx_fl  $foo_y_fl  $foo_yx_fl
$hiresfound  @ifls  $itmp  $localhostname  $md5  $md5found  %MD5_tbl
$mpi_fke  $mpi_prc  $mpi_prfx  $MY_BIN_DIR  $nco_D_flg  $notbodi
$nsr_xpc  $NUM_FLS  $nvr_my_bin_dir  $omp_flg  $opr_fmt  $opr_lng_max
@opr_lst  @opr_lst_all  @opr_lst_mpi  $opr_nm  $opr_rgr_mpi
$opr_sng_mpi  $orig_outfile  $outfile  $prfxd  $prg_nm
$pth_rmt_scp_tst  $pwd  $que  $rcd  %real_tme  $result  $rgr
$server_ip  $server_name  $server_port  $sock  $spc_fmt  $spc_nbr
$spc_nbr_min  $spc_sng  %subbenchmarks  %success  %sym_link
@sys_tim_arr  $sys_time  %sys_tme  $thr_nbr  $timed  $timestamp
$tmr_app  %totbenchmarks  @tst_cmd  $tst_fl_cr8  $tst_fmt  $tst_id_sng
$tst_idx  %tst_nbr  $udp_reprt  $udp_rpt  $USER  $usg  %usr_tme
%wc_tbl  $wnt_log  $xpt_dsc
);

# Initializations
# Re-constitute commandline
$prg_nm=$0; # $0 is program name Camel p. 136
$cmd_ln = "$0 "; $arg_nbr = @ARGV;
for (my $i=0; $i<$arg_nbr; $i++){ $cmd_ln .= "$ARGV[$i] ";}

# Set defaults for command line arguments
$bch_flg=0; # [flg] Batch behavior
$dbg_lvl = 0; # [enm] Print tests during execution for debugging
$nco_D_flg = "";
my $nvr_data=$ENV{'DATA'} ? $ENV{'DATA'} : '';
my $nvr_home=$ENV{'HOME'} ? $ENV{'HOME'} : '';
$USER = $ENV{'USER'};
$pwd = `pwd`; chomp $pwd;
$fl_pth = '';
$que = 0;
$thr_nbr = 0; # If not zero, pass explicit threading argument
$tst_fl_cr8 = "0";
$udp_rpt = 0;
$usg = 0;
$mpi_fke = 0;
$wnt_log = 0;
$md5 = 0;
$mpi_prc = 0; # by default, don't want no steekin MPI
$mpi_prfx = "";
$timestamp = `date -u "+%x %R"`; chomp $timestamp;
$dodap = "FALSE"; # Unless redefined by the command line, it does not get set
$fl_cnt = 32; # nbr of files to process (reduced to 4 if using remote/dods files
$pth_rmt_scp_tst='dust.ess.uci.edu:/var/www/html/dodsdata';

# other inits
$localhostname = `hostname`;
$notbodi = 0; # specific for hjm's puny laptop
my $prfxd = 0;
if ($localhostname !~ "bodi") {$notbodi = 1} # spare the poor laptop
$ARGV = @ARGV;

my $iosockfound;

BEGIN{
    unshift @INC,$ENV{'HOME'}.'/nco/bm'; # Location of NCO_rgr.pm, NCO_bm.pm
} # end BEGIN

BEGIN {eval "use IO::Socket"; $iosockfound = $@ ? 0 : 1}
#$iosockfound = 0;  # uncomment to simulate not found
if ($iosockfound == 0) {
    print "\nOoops! IO::Socket module not found - continuing with no udp logging.\n\n";
} else {
    print "\tIO::Socket  ... found.\n";
}


$rcd=Getopt::Long::Configure('no_ignore_case'); # Turn on case-sensitivity
&GetOptions(
	'bch_flg!'     => \$bch_flg,    # [flg] Batch behavior
	'benchmark'    => \$bm,         # Run benchmarks
	'bm'           => \$bm,         # Run benchmarks
	'dbg_lvl=i'    => \$dbg_lvl,    # debug level - # is now optional
	'debug:i'      => \$dbg_lvl,    # debug level
	'dods:s'       => \$dodap,      # string is the URL to the DODs data
	'dap:s'        => \$dodap,      #  "
	'opendap:s'    => \$dodap,      #  "
	'h'            => \$usg,        # explains how to use this thang
	'help'         => \$usg,        #            ditto
	'log'          => \$wnt_log,    # set if want output logged
	'mpi_prc=i'    => \$mpi_prc,    # set number of mpi processes
	'mpi_fake'		=> \$mpi_fke,    # run the mpi executable as a single process for debugging.
	'fake_mpi'		=> \$mpi_fke,    # run the mpi executable as a single process for debugging.
	'mpi_fke'		=> \$mpi_fke,    # run the mpi executable as a single process for debugging.
	'queue'        => \$que,        # if set, bypasses all interactive stuff
	'pth_rmt_scp_tst' => \$pth_rmt_scp_tst, # [drc] Path to scp regression test file
	'regress'      => \$rgr,        # test regression
	'rgr'          => \$rgr,        # test regression
	'test_files=s' => \$tst_fl_cr8, # Create test files "134" does 1,3,4
	'tst_fl=s'     => \$tst_fl_cr8, # Create test files "134" does 1,3,4
	'thr_nbr=i'    => \$thr_nbr,    # Number of OMP threads to use
	'udpreport'    => \$udp_rpt,    # punt the timing data back to udpserver on sand
	'usage'        => \$usg,        # explains how to use this thang
	'caseid=s'     => \$caseid,     # short string to tag test dir and batch queue
	'xpt_dsc=s'    => \$xpt_dsc,    # long string to describe experiment
#BROKEN - FXM hjm	'md5'          => \$md5,        # requests md5 checksumming results (longer but more exacting)
);

BEGIN {eval "use Digest::MD5"; $md5found = $@ ? 0 : 1}
# $md5found = 0;  # uncomment to simulate no MD5
if ($md5 == 1) {
	if ($md5found == 0) {
		print "\nOoops! Digest::MD5 module not found - continuing with simpler error checking\n\n" ;
} else {
		print "\tDigest::MD5 ... found.\n";
}
} else {
	print "\tMD5 NOT requested; continuing with ncks checking of single values.\n";
}

$NUM_FLS = 4; # max number of files in the file creation series

if($dbg_lvl > 0){
	print "\nDEBUG[1]: $prg_nm:\n";
	printf ("\t \$cmd_ln = $cmd_ln\n");
	printf ("\t \$caseid = $caseid\n");
	printf ("\t \$rgr = $rgr\n");
	printf ("\t \$bm = $bm\n");
	printf ("\t \$bch_flg = $bch_flg\n");
	printf ("\t \$nvr_data = $nvr_data\n");
	printf ("\t \$nvr_home = $nvr_home\n");
	printf ("\t \$nvr_my_bin_dir = $nvr_my_bin_dir\n");
	printf ("\t \@ENV = @ENV\n");
	printf ("\t \@INC:\n");
	foreach my $subpth (@INC) {print "\t   $subpth\n"}
}

if ($ARGV == 0) {	usage();}

# Resolve conflicts early
if ($mpi_prc > 0 && $thr_nbr > 0) {die "\nThe  '--mpi_prc' (MPI) and '--thr_nbr' (OpenMP) options are mutually exclusive.\nPlease decide which you want to run and try again.\n\n";}

# do $mpi_prc and $mpi_fke conflict?
if ($mpi_prc > 0 && $mpi_fke) {
	die "\nERR: You requested both an MPI run (--mpi_prc) as well as a FAKE MPI run (--mpi_fake)\n\tMake up your mind!\n\n";
}

# Any irrationally exuberant values?
if ($mpi_prc > 16) {die "\nThe '--mpi_prc' value was set to an irrationally exuberant [$mpi_prc].  Try a lower value\n ";}
if ($thr_nbr > 16) {die "\nThe '--thr_nbr' value was set to an irrationally exuberant [$thr_nbr].  Try a lower value\n ";}
if (length($caseid) > 80) {die "\nThe caseid string is > 80 characters - please reduce it to less than 80 chars.\nIt's used to create file and directory names, so it has to be relatively short\n";}

# Slurp in data for the checksum hashes

if ($md5 == 1) {
	do "nco_bm_md5wc_tbl.pl" or die "Can't find the validation data (nco_bm_md5wc_tbl.pl).\n";
}
$nco_D_flg = "-D" . "$dbg_lvl";

dbg_msg(3,"\$nco_D_flg = $nco_D_flg");

# Determine where $DATA should be, prompt user if necessary
dbg_msg(2, "$prg_nm: Calling set_dat_dir()");
set_dat_dir(); # Set $dta_dir

# make sure that the $fl_pth gets set to a reasonable defalt
$fl_pth = "$dta_dir";

# Initialize & set up some variables
if($dbg_lvl > 1){printf ("$prg_nm: Calling initialize()...\n");}
initialize($bch_flg,$dbg_lvl);

# Use variables for file names in regressions; some of these could be collapsed into
# fewer ones, no doubt, but keep them separate until whole shebang starts working correctly
$outfile       = "$dta_dir/foo.nc"; # replaces outfile in tests, typically 'foo.nc'
$orig_outfile  = "$dta_dir/foo.nc";
$foo_fl        = "$dta_dir/foo";
$foo_avg_fl    = "$dta_dir/foo_avg.nc";
$foo_tst       = "$dta_dir/foo.tst";
$foo1_fl       = "$dta_dir/foo1.nc";
$foo2_fl       = "$dta_dir/foo2.nc";
$foo_x_fl      = "$dta_dir/foo_x.nc";
$foo_y_fl      = "$dta_dir/foo_y.nc";
$foo_xy_fl     = "$dta_dir/foo_xy.nc";
$foo_yx_fl     = "$dta_dir/foo_yx.nc";
$foo_xymyx_fl  = "$dta_dir/foo_xymyx.nc";
$foo_T42_fl    = "$dta_dir/foo_T42.nc";

use NCO_bm; # module that contains most of the functions

use NCO_rgr; # module that contains perform_tests()

# the real udping server
$server_name = "sand.ess.uci.edu";
$server_ip = "128.200.14.132";
$server_port = 29659;

if ($usg) { usage()};   # dump usage blurb
if (0) { tst_hirez(); } # tests the hires timer - needs explict code mod to do this

if ($iosockfound) {
	$sock = IO::Socket::INET->new (
		Proto    => 'udp',
		PeerAddr => $server_ip,
		PeerPort => $server_port
	) or print "\nCan't get the socket - continuing anyway.\n"; # if off network..
} else {$udp_reprt = 0;}

if ($wnt_log) {
    open(LOG, ">$bm_dir/nctest.log") or die "\nUnable to open log file '$bm_dir/nctest.log' - check permissions on it\nor the directory you are in.\n stopped";
}

# Pass explicit threading argument
if ($thr_nbr > 0){$omp_flg="--thr_nbr=$thr_nbr ";} else {$omp_flg='';}

# does dodap require that we ignore both MPI and OpenMP?  Let's leave it in for now.
# If dodap is not set then test with local files
# If dodap is set and string is NULL, then test with OPeNDAP files on sand.ess.uci.edu
# If string is NOT NULL, use URL to grab files

dbg_msg(4, "before dodap assignment, \$fl_pth = $fl_pth, \$dodap = $dodap");
# $dodap asks for and if defined, carries, the URL that's inserted in the '-p' place in nco cmdlines
if ($dodap ne "FALSE") {
	if ($dodap eq "") {
		$fl_pth = "http://sand.ess.uci.edu/cgi-bin/dods/nph-dods/dodsdata";
		$fl_cnt = 4;
	} elsif ($dodap =~ /http/) {
		$fl_pth = $dodap;
		$fl_cnt = 4;
	} else {
		die "\nThe URL specified with the --dods option:\n $dodap \ndoesn't look like a valid URL.\nTry again\n\n";
	}
}
dbg_msg(4, "after dodap assignment, \$fl_pth = $fl_pth, \$dodap = $dodap");

# Initialize & set up some variables
#if($dbg_lvl > 0){printf ("$prg_nm: Calling initialize()...\n");}
#initialize($bch_flg,$dbg_lvl);

# Grok /usr/bin/time, as in shell scripts
if (-e "/usr/bin/time" && -x "/usr/bin/time") {
	$tmr_app = "/usr/bin/time ";
	if (`uname` =~ "inux"){$tmr_app.="-p ";}
} else { # just use whatever the shell thinks is the time app
	$tmr_app = "time"; # bash builtin or other 'time'-like application (AIX)
} # endif time

# Regression tests
if ($rgr){
	perform_tests();
	smrz_rgr_rslt();
} # endif rgr

# Start real benchmark tests
# Test if necessary files are available - if so, may skip creation tests

if($bm && $dodap eq "FALSE"){
	if($dbg_lvl > 1){printf ("\n$prg_nm: Calling fl_cr8_dat_init()...\n");}
	fl_cr8_dat_init(); # Initialize data strings & timing array for files
}

# Check if files have already been created
# If so, skip file creation if not requested
if ($bm && $tst_fl_cr8 == 0 && $dodap eq "FALSE") {
	if ($dbg_lvl> 0){print "\nINFO: File creation tests:\n";}
	for (my $i = 0; $i < $NUM_FLS; $i++) {
		my $fl = $fl_cr8_dat[$i][2] . ".nc"; # file root name stored in $fl_cr8_dat[$i][2]
		if (-e "$dta_dir/$fl" && -r "$dta_dir/$fl") {
		if ($dbg_lvl> 0){printf ("%50s exists - can skip creation\n", $dta_dir . "/" . $fl);}
		} else {
			my $e = $i+1;
			$tst_fl_cr8 .= "$e";
		}
	}
}

# file creation tests
if ($tst_fl_cr8 ne "0"){
    my $fc = 0;
    if ($tst_fl_cr8 =~ "[Aa]") { $tst_fl_cr8 = "1234";}
    if ($tst_fl_cr8 =~ /1/){ fl_cr8(0); $fc++; }
    if ($tst_fl_cr8 =~ /2/){ fl_cr8(1); $fc++; }
    if ($tst_fl_cr8 =~ /3/){ fl_cr8(2); $fc++; }
    if ($notbodi && $tst_fl_cr8 =~ /4/) { fl_cr8(3); $fc++; }
    if ($fc >0) {smrz_fl_cr8_rslt(); } # prints and udpreports file creation timing
}

my $doit=1; # for skipping various tests
wat4inpt(__LINE__,"just prior to starting the benchmarks");
# and now, the REAL benchmarks, set up as the regression tests below to use go() and smrz_rgr_rslt()
if ($bm) {
	my $bmfile = $pwd . "/" . "nco_bm_benchmarks.pl";
	do "$bmfile" or die "Can't find Benchmark data ($bmfile) $! $@";
}
