#! /usr/bin/perl
#  Remove header entry of two PO files and compare them

my $ignore_ref = 0;
my $f1 = shift(@ARGV);

if ($f1 =~ /--no-ref/) {
    $ignore_ref = 1;
    $f1 = shift(@ARGV);
}

my $f2 = shift(@ARGV);

open IN1, "<", $f1 or die "Unable to read 1st file ($f1): $!\n";
open IN2, "<", $f2 or die "Unable to read 2nd file ($f2): $!\n";

# Skip headers
my $inMsgstr = 0;
my $lineno = 0;
while (<IN1>) {
	$lineno ++;
	if (m/^msgstr/) {
		$inMsgstr = 1;
	} elsif ($inMsgstr == 1 && $_ !~ /^"/) {
		last;
	}
}
$inMsgstr = 0;
while (<IN2>) {
	if (m/^msgstr/) {
		$inMsgstr = 1;
	} elsif ($inMsgstr == 1 && $_ !~ /^"/) {
		last;
	}
}

# Now compare lines
foreach my $l1 (<IN1>) {
    $lineno ++;

    my $l2 = <IN2> or die "Unexpected EOF found when reading $f2\n";

    # Ignore end of lines, to avoid issues on windows
    chomp $l1;
    chomp $l2; 

    unless (($l1 eq $l2) or ($ignore_ref and ($l1 =~ m/^#:/) and ($l2 =~ m/^#:/))) {
	die "Files $f1 and $f2 differ at line $lineno:\n-${l1}+${l2}\n";
    }
}
close IN1;
die "EOF expected at 2nd file\n" unless eof(IN2);
close IN2;
exit 0;
