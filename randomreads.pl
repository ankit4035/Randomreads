#!/usr/bin/perl
my $usage= "\nUsage: perl randomreads.pl name_of_file number_of_reads paired/single";
my $usage1 = "\nThis script is used to extract random n number of reads from fastq file in LINUX. User needs to provide only 1 file(in case of paired-end R1 file), number of reads to extract and paired-end or single-end by giving either 'paired' or 'single'.\nRead extraction is done using Pullseq (https://github.com/bcthomas/pullseq.git). Make sure pullseq is pre-installed and accessible system-wide.\nThis script supports single-end and paired-end both. Make sure paired-end files are named as filename_R1.fastq and filename_R2.fastq.\n\n";

if(@ARGV!=3){print STDERR $usage, "\n", $usage1; exit -1;}

my $inputFile = $ARGV[0];
my $readsnumber = $ARGV[1];
my $end = $ARGV[2];


# extract headers of all reads and input in perl
$mycmd = "awk 'NR\%4==1 {print \$1}' $inputFile > header.txt";
system (`$mycmd`);

my @list = ();
srand(); # Initialize the random number generator

open(PAGE,">list.txt") || die"Can't open list.txt\n";
open(INPUT, "<", "header.txt") or die("Could not open input file header file!\n");

@heads = ();


#make list of random n headers. Idea used from https://blog-en.openalfa.com/how-to-extract-a-random-sample-from-a-text-file-in-perl  
while (<INPUT>)
{
    push(@heads, $_);
    push(@list, $_), next if (@list < $readsnumber);
    $list[ rand(@list) ] = $_ if (rand($./$readsnumber) < 1);
}

if ($readsnumber >= scalar(@heads))
{ print "ERROR_TERMINATING: Number of reads to extract is either equal or greater than number of reads in file \n\n"; system(`rm header.txt list.txt`); exit;}


#remove @ from header names
for (@list)
{ s/^@// ; }

#export the list of headers to be used by pullseq
print PAGE foreach @list;

close (PAGE);
close (INPUT);

#use pullseq to extract reads from fastq files

if (lc($end) eq "single")
{
	if ($inputFile =~ /(.*?).fastq/)
	{ $filename = $1; }
	$of = $filename;	
	$of .= "_random_".$readsnumber."reads.fastq";
	$mypullseqcmd = "pullseq -i $inputFile -n list.txt > $of";
	system (`$mypullseqcmd`);
}
elsif (lc($end) eq "paired")
{
 
	if ($inputFile =~ /(.*?)_R1.fastq/)
	{ $filename = $1; }
	
	$file1=$file2=$of1=$of2=$filename;
	$file1 .= "_R1.fastq";
	$file2 .= "_R2.fastq";
	$of1 .= "_random_".$readsnumber."reads_R1.fastq";
	$of2 .= "_random_".$readsnumber."reads_R2.fastq";
	
	$mypullseqcmd1 = "pullseq -i $file1 -n list.txt > $of1";
	$mypullseqcmd2 = "pullseq -i $file2 -n list.txt > $of2";
	
	
	
	system (`$mypullseqcmd1`);
	system (`$mypullseqcmd2`);
	
}
else
{
print "Improper input in type of end, provide either single or paired \n";
system(`rm header.txt list.txt`); exit;
}


#clear the intermediate files
system(`rm header.txt list.txt`);

print "\nALL DONE\n";
