#!/usr/bin/env perl

use warnings;
use strict;
use File::Find;
use Getopt::Long;
Getopt::Long::Configure("posix_default",
                        "gnu_compat",
                        "bundling");

# variables
my $src;
my $binDir;
my $objsDir;
my @cc;
my @cxx;
my $dcc;
my @cflags;
my @cxxflags;
my @libs;
my @pkgs;
my $name;
my $O;
my $echo    = 1;
my $quiet   = 0;
my $stdout  = 0;



my $file;
# config load
if ( -e "vfnmake" ) {
    open(my $file, '<', "vfnmake");
    while (my $line = <$file>) {
        my $line2   = <$file>;
        $line2      =~ s/^\s*//;
        if ($line eq "libs:\n") {
            @libs = split /\s+/, $line2;
        } elsif ($line eq "pkgs:\n") {
            @pkgs = split /\s+/, $line2;
        } elsif ($line eq "cflags:\n") {
            @cflags   = split /\s+/, $line2;
        } elsif ($line eq "cxxflags:\n") {
            @cxxflags = split /\s+/, $line2;
        } elsif ($line eq "O:\n") {
            chomp ($O = $line2);
        } elsif ($line eq "src_directory:\n") {
            chomp ($src = $line2);
        } elsif ($line eq "bin_directory:\n") {
            chomp ($binDir = $line2);
        } elsif ($line eq "objs_directory:\n") {
            chomp ($objsDir = $line2);
        } elsif ($line eq "cc:\n") {
            @cc  = split /\s+/, $line2;
        } elsif ($line eq "cxx:\n") {
            @cxx = split /\s+/, $line2;
        } elsif ($line eq "debug_cc:\n") {
            chomp ($dcc = $line2);
        } elsif ($line eq "echo:\n") {
            chomp ($echo = $line2);
        } elsif ($line eq "name:\n") {
            chomp ($name = $line2);
        }
    }
    close($file);
}


sub addToArray {
    my ($value, $array) = @_;
    push @$array, $value unless grep {$_ eq $value} @$array;
}
sub removeFromArray {
    my ($value, $array) = @_;
    @$array = grep {$_ ne $value} @$array;
}

# argument parsing
GetOptions(
           'cc=s'          => sub { @cc  = split /\s*,\s*/, $_[1] },
           'cxx=s'         => sub { @cxx = split /\s*,\s*/, $_[1] },
           'dcc=s'         => \$dcc,

           'src=s'         => \$src,
           'bin=s'         => \$binDir,
           'objs=s'        => \$objsDir,
           'name=s'        => \$name,

           'cflags=s'      => sub { @cflags   = split /\s*,\s*/, $_[1]  },
           'cflag|c=s'     => sub {      addToArray($_[1], \@cflags)    },
           'Cflag|C=s'     => sub { removeFromArray($_[1], \@cflags)    },

           'cxxflags=s'    => sub { @cxxflags = split /\s*,\s*/, $_[1]  },
           'cxxflag|x=s'   => sub {      addToArray($_[1], \@cxxflags)  },
           'Cxxflag|X=s'   => sub { removeFromArray($_[1], \@cxxflags)  },

           'pkgs=s'        => sub { @pkgs     = split /\s*,\s*/, $_[1]  },
           'pkg|p=s'       => sub {      addToArray($_[1], \@pkgs)      },
           'Pkg|P=s'       => sub { removeFromArray($_[1], \@pkgs)      },

           'libs=s'        => sub { @libs     = split /\s*,\s*/, $_[1]  },
           'lib|l=s'       => sub {      addToArray($_[1], \@libs)      },
           'Lib|L=s'       => sub { removeFromArray($_[1], \@libs)      },

           'O=s'           => \$O,
           'echo|e!'       => \$echo,
           'quiet|q'       => \$quiet,
           'stdout'        => \$stdout,
           'cpp0x'         => sub { addToArray("-std=c++0x", \@cxxflags);
                                    @cc    = ("gcc");
                                    @cxx   = ("g++");
                                    $dcc   =  "g++"},
           'gcc'           => sub { @cc    = ("gcc");
                                    @cxx   = ("g++");
                                    $dcc   =  "g++"},
           'reset'         => sub { @cc    = ("clang"  , "gcc");
                                    @cxx   = ("clang++", "g++");
                                    $dcc   =  "g++";
                                    $echo  = 1;
                                    removeFromArray("-std=c++0x", \@cxxflags);
                                    if ( -d "src" ) {
                                        $src = "src";
                                    } else {
                                        $src = ".";
                                    }
                                    $binDir  ||= ".";
                                    $objsDir ||= "objs"; },
          ) or die "\n";


# default values
unless (defined($src)) {
    if ( -d "src" ) {
        $src = "src";
    } else {
        $src = ".";
    }
}
$binDir  ||= ".";
$objsDir ||= "objs";
@cc        = ("clang",   "gcc") unless @cc;
@cxx       = ("clang++", "g++") unless @cxx;
$dcc     ||= "g++";
$name    ||= "a.out";
$O       ||= "-O2";


my @CFiles;
find( sub { push @CFiles, "$File::Find::name" if /\.c$/ }, $src);
my @CPPFiles;
find( sub { push @CPPFiles, "$File::Find::name" if /\.cpp$/ }, $src);

my @objs =  (@CFiles, @CPPFiles);
s/^$src(.*)\.c(pp)?/$objsDir$1.o/ foreach @objs;
my $objs =  join(' ', @objs);

my $cflags   = join(' ', @cflags);
my $cxxflags = join(' ', @cxxflags);
my $lflags   = "";
foreach my $lib (@libs) {
    $lflags .= "-l $lib ";
}
my $pkgs;
if (@pkgs) {
    $pkgs    = join(' ', @pkgs);
    $lflags .= "`pkg-config $pkgs --libs` ";
    $cflags  = "$cflags `pkg-config $pkgs --cflags`";
}
chop $lflags;

$src      =~ s|/$||;
$binDir   =~ s|/$||;
$objsDir  =~ s|/$||;



# choose the first existing compiler from the list
my $cc;
my $cxx;
my $linker;

{
    sub cmdExist {
        return !system("command -v \"$_[0]\" > /dev/null 2> /dev/null");
    }

    my @tmpCC = @cc;
    do {
        $cc = shift @tmpCC;
    } while (@tmpCC != 0 &&
             !cmdExist($cc));
    die "There are no valid C compilers in the list\n" unless cmdExist($cc);

    if (@CPPFiles) {
        my @tmpCXX = @cxx;
        do {
            $cxx = shift @tmpCXX;
        } while (@tmpCXX != 0 &&
                 !cmdExist($cxx));
        die "There are no valid C++ compilers in the list\n" unless cmdExist($cxx);

        $linker = "\$(CXX)";
    } else {
        $cxx = "";
        $linker = "\$(CC)";
    }
}


# write the macros
my $make = "CC=$cc
CXX=$cxx
CFLAGS=\$(O) $cflags
CXXFLAGS=\$(CFLAGS) $cxxflags
O=$O
LFLAGS=$lflags
OBJS=$objs

all: objs $name";

if ($echo) {
    $make .= "\n
$binDir/$name: \$(OBJS)
	$linker \$(LFLAGS) \$(OBJS) -o \"$binDir/$name\"\n";
} else {
    $make .= "\n
$binDir/$name: \$(OBJS)
	@ echo \"    LINK $binDir/$name\"
	@ $linker \$(LFLAGS) \$(OBJS) -o \"$binDir/$name\"\n";
}


# detecting the dependencies
foreach my $CFile (@CFiles) {
    my $deps = `gcc -MM "$CFile"`;    # some compilers have problems sometimes, so I've hardcoded gcc here
    chomp $deps;
    if ($echo) {
        $make .= "
$objsDir/$deps
	\$(CC) \$(CFLAGS) -c \"$CFile\" -o \$@";
    } else {
        $make .= "
$objsDir/$deps
	@ echo \"    CC   $CFile\"
	@ \$(CC) \$(CFLAGS) -c \"$CFile\" -o \$@";
    }
}
foreach my $CPPFile (@CPPFiles) {
    my $deps = `g++ -MM "$CPPFile"`;
    chomp $deps;
    if ($echo) {
        $make .= "
$objsDir/$deps
	\$(CXX) \$(CXXFLAGS) -c \"$CPPFile\" -o \$@";
    } else {
        $make .= "
$objsDir/$deps
	@ echo \"    CXX  $CPPFile\"
	@ \$(CXX) \$(CXXFLAGS) -c \"$CPPFile\" -o \$@";
    }
}


$make .= "\n
objs:
	@ mkdir \"$objsDir\"
c: clean
clean:
	@ if [ -d \"$objsDir\" ]; then rm -r \"$objsDir\"; fi
	@ rm -f \"$binDir/$name\"
	@ echo \"    CLEAN\"
f: fresh
fresh: clean
	@ make all
r: run
run: all
	@ ./$binDir/$name

d: debug
debug: CFLAGS += -DDEBUG -g
debug: O=-O0
debug: CC=$dcc
debug: CXX=$dcc
debug: all";

if ($stdout) {
    print "$make";
} else {
    open($file, '>', "Makefile") or die;
    print $file "$make";
    close($file);
}


# config save
my $config;
my @config = (
              [ cc              => \@cc       ],
              [ cxx             => \@cxx      ],
              [ debug_cc        => $dcc       ],
              [ libs            => \@libs     ],
              [ pkgs            => \@pkgs     ],
              [ O               => $O         ],
              [ cflags          => \@cflags   ],
              [ cxxflags        => \@cxxflags ],
              [ name            => $name      ],
              [ src_directort   => $src       ],
              [ bin_directory   => $binDir    ],
              [ objs_directory  => $objsDir   ],
              [ echo            => $echo      ],
             );

for my $p (@config) {
    my $str;
    if (ref $p->[1] eq 'ARRAY') {
        $str = join(' ', @{$p->[1]});
    } else {
        $str = $p->[1];
    }
    $config .= "$p->[0]:\n\t$str\n";
}

open($file, '>', "vfnmake") or die;
print $file "$config";
close($file);
print "$config" unless $quiet or $stdout;
