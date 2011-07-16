#!/usr/bin/env perl

use warnings;
use strict;
use File::Find;

# variables
my $src;
my $binDir;
my $objsDir;
my $cc;
my $cxx;
my @cflags;
my @libs;
my $name;
my $O;

# config load
open(my $file, '<', "vmake");
while (my $line = <$file>) {
    if ($line =~ /libs:$/) {
        $line = <$file>;
        $line =~ s/^\s*//;
        @libs = split /\s+/, $line;
    }
    elsif ($line =~ /cflags:$/) {
        $line = <$file>;
        $line =~ s/^\s*//;
        @cflags = split /\s+/, $line;
    }
    elsif ($line =~ /O:$/) {
        $line = <$file>;
        $line =~ s/^\s*//;
        chomp ($O = $line);
    }
}

# argument parsing
while (@ARGV) {
    # add a lib
    if ($ARGV[0] eq "-l+") {
        shift;
        push @libs, $ARGV[0] unless grep {$_ eq $ARGV[0]} @libs;
        shift;
    }
    # remove a lib
    elsif ($ARGV[0] eq "-l-") {
        shift;
        @libs = grep {$_ ne $ARGV[0]} @libs;
        shift;
    }
    # optimization
    elsif ($ARGV[0] =~ /^-O.$/) {
        $O = $ARGV[0];
        shift;
    }
    # add a compilation flag
    elsif ($ARGV[0] eq "-c+") {
        shift;
        push @cflags, $ARGV[0] unless grep {$_ eq $ARGV[0]} @cflags;
        shift;
    }
    # remove a compilation flag
    elsif ($ARGV[0] eq "-c-") {
        shift;
        @cflags = grep {$_ ne $ARGV[0]} @cflags;
        shift;
    }
}

# default values
$cc    //= "gcc";
$cxx   //= "g++";
$name  //= "a.out";
if (!$src) {
    if ( -d "src" ) {
        $src = "src";
    } else {
        $src = ".";
    }
}
$objsDir  //= "objs";
$binDir   //= ".";
$O        //= "-O2";


my @CFiles;
find( sub { push @CFiles, "$File::Find::name" if /\.c(pp)?$/ }, $src);

my $objs =  join(' ', @CFiles);
$objs    =~ s/\.cpp( ?)/\.o$1/g;

my $cflags = join (' ', @cflags);
my $lflags = "";
foreach my $lib (@libs) {
    $lflags .= "-l $lib ";
}
chop $lflags;


# Write the macros
my $make = "CC=$cc
CXX=$cxx
CFLAGS=$O $cflags
LFLAGS=$lflags
OBJS=$objs

all: objs $name

$binDir/$name: \$(OBJS)
	\$(CXX) \$(LFLAGS) \$(OBJS) -o \"$binDir/$name\"\n";

foreach my $CFile (@CFiles) {
    my $deps = `$cxx -MM "$CFile"`;
    chomp $deps;
    $make .= "
$objsDir/$deps
	\$(CXX) \$(CFLAGS) -c \"$CFile\" -o \$@"
}



$make .= "\n
objs:
	\@ mkdir \"$objsDir\"
c: clean
clean:
	\@ if [ -d \"$objsDir\" ]; then rm -r \"$objsDir\"; fi
	\@ rm -f \"$binDir/$name\"
	\@ echo CLEAN";

open($file, '>', "Makefile") or die;
print $file "$make";
close($file);

# config save
open($file, '>', "vmake") or die;

print $file "libs:\n\t";
foreach (@libs) {
    print $file " $_";
}

print $file "\nO:\n\t$O\n";

print $file "cflags:\n\t";
foreach (@cflags) {
    print $file " $_";
}
print $file "\n";

close($file);
