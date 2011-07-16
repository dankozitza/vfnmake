#!/usr/bin/env perl

use warnings;
use strict;
use File::Find;


# variables
my $src;
my $binDir  = ".";
my $objsDir = "objs";
my @cc      = ("clang",
               "gcc");
my @cxx     = ("clang++",
               "g++");
my $dcc     = "g++";
my @cflags;
my @cxxflags;
my @libs;
my @pkgs;
my $name    = "a.out";
my $O       = "-O2";
my $echo    = 1;
my $quiet   = 0;
my $stdout  = 0;

if ( -d "src" ) {
    $src = "src";
} else {
    $src = ".";
}


my $file;
# config load
if ( -e "vfnmake" ) {
    open(my $file, '<', "vfnmake");
    while (my $line = <$file>) {
        if ($line eq "libs:\n") {
            $line = <$file>;
            $line =~ s/^\s*//;
            @libs = split /\s+/, $line;
        } elsif ($line eq "pkgs:\n") {
            $line = <$file>;
            $line =~ s/^\s*//;
            @pkgs = split /\s+/, $line;
        } elsif ($line eq "cflags:\n") {
            $line    = <$file>;
            $line    =~ s/^\s*//;
            @cflags  = split /\s+/, $line;
        } elsif ($line eq "cxxflags:\n") {
            $line    = <$file>;
            $line    =~ s/^\s*//;
            @cxxflags  = split /\s+/, $line;
        } elsif ($line eq "O:\n") {
            $line = <$file>;
            $line =~ s/^\s*//;
            chomp ($O = $line);
        } elsif ($line eq "src_directory:\n") {
            $line = <$file>;
            $line =~ s/^\s*//;
            chomp ($src = $line);
        } elsif ($line eq "bin_directory:\n") {
            $line = <$file>;
            $line =~ s/^\s*//;
            chomp ($binDir = $line);
        } elsif ($line eq "objs_directory:\n") {
            $line = <$file>;
            $line =~ s/^\s*//;
            chomp ($objsDir = $line);
        } elsif ($line eq "cc:\n") {
            $line  = <$file>;
            $line  =~ s/^\s*//;
            @cc    = split /\s+/, $line;
        } elsif ($line eq "cxx:\n") {
            $line  = <$file>;
            $line  =~ s/^\s*//;
            @cxx   = split /\s+/, $line;
        } elsif ($line eq "debug cc:\n") {
            $line  = <$file>;
            $line  =~ s/^\s*//;
            chomp ($dcc = $line);
        } elsif ($line eq "echo:\n") {
            $line  = <$file>;
            $line  =~ s/^\s*//;
            chomp ($echo = $line);
        } elsif ($line eq "name:\n") {
            $line  = <$file>;
            $line  =~ s/^\s*//;
            chomp ($name = $line);
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
while (@ARGV) {
    # add a lib
    if ($ARGV[0] eq "--lib+" || $ARGV[0] eq "-l+") {
        shift;
        addToArray($ARGV[0], \@libs);
        shift;
    }
    # remove a lib
    elsif ($ARGV[0] eq "--lib-" || $ARGV[0] eq "-l-") {
        shift;
        removeFromArray($ARGV[0], \@libs);
        shift;
    }
    # overwrite the list of libraries
    elsif ($ARGV[0] eq "--libs") {
        shift;
        @libs = split /\s*,\s*/, $ARGV[0];
        shift;
    }
    # pkg-config add
    elsif ($ARGV[0] eq "--pkg+") {
        shift;
        addToArray($ARGV[0], \@pkgs);
        shift;
    }
    # pkg-config remove
    elsif ($ARGV[0] eq "--pkg+") {
        shift;
        removeFromArray($ARGV[0], \@pkgs);
        shift;
    }
    # pkg-config list
    elsif ($ARGV[0] eq "--pkgs") {
        shift;
        @pkgs = split /\s*,\s*/, $ARGV[0];
        shift;
    }
    # optimization
    elsif ($ARGV[0] =~ /^-O.$/) {
        $O = $ARGV[0];
        shift;
    }
    # add a compilation flag
    elsif ($ARGV[0] eq "--cflag+" || $ARGV[0] eq "-c+") {
        shift;
        addToArray($ARGV[0], \@cflags);
        shift;
    }
    # remove a compilation flag
    elsif ($ARGV[0] eq "--cflag-" || $ARGV[0] eq "-c-") {
        shift;
        removeFromArray($ARGV[0], \@cflags);
        shift;
    }
    # overwrite the compilation flag list
    elsif ($ARGV[0] eq "--cflags") {
        shift;
        @cflags = split /\s*,\s*/, $ARGV[0];
        shift;
    }
    # add a C++ compilation flag
    elsif ($ARGV[0] eq "--cxxflag+" || $ARGV[0] eq "-C+") {
        shift;
        addToArray($ARGV[0], \@cxxflags);
        shift;
    }
    # remove a C++ compilation flag
    elsif ($ARGV[0] eq "--cxxflag-" || $ARGV[0] eq "-C-") {
        shift;
        removeFromArray($ARGV[0], \@cxxflags);
        shift;
    }
    # overwrite the C++ compilation flag list
    elsif ($ARGV[0] eq "--cxxflags") {
        shift;
        @cxxflags = split /\s*,\s*/, $ARGV[0];
        shift;
    }
    elsif ($ARGV[0] eq "--echo" || $ARGV[0] eq "-e") {
        $echo = 1;
        shift;
    }
    elsif ($ARGV[0] eq "--no-echo" || $ARGV[0] eq "-ne") {
        $echo = 0;
        shift;
    }
    # specify the src directory
    elsif ($ARGV[0] eq "--src") {
        shift;
        $src = $ARGV[0];
        shift;
    }
    # specify the bin directory
    elsif ($ARGV[0] eq "--bin") {
        shift;
        $binDir = $ARGV[0];
        shift;
    }
    # specify the objs directory
    elsif ($ARGV[0] eq "--objs") {
        shift;
        $objsDir = $ARGV[0];
        shift;
    }
    # C compiler list
    elsif ($ARGV[0] eq "--cc") {
        shift;
        @cc = split /\s*,\s*/, $ARGV[0];
        shift;
    }
    # C++ compiler list
    elsif ($ARGV[0] eq "--cxx") {
        shift;
        @cxx = split /\s*,\s*/, $ARGV[0];
        shift;
    }
    # debugging compiler
    elsif ($ARGV[0] eq "--dcc") {
        shift;
        $dcc = $ARGV[0];
        shift;
    }
    # use only gcc
    elsif ($ARGV[0] eq "--gcc") {
        @cc = ("gcc");
        @cxx = ("g++");
        $dcc = "g++";
        shift;
    }
    # use c++0x standard for C++
    elsif ($ARGV[0] eq "--c++0x") {
        addToArray("-std=c++0x", \@cxxflags);
        @cc = ("gcc");
        @cxx = ("g++");
        $dcc = "g++";
        shift;
    }
    # change the name of the executable file
    elsif ($ARGV[0] eq "--name") {
        shift;
        $name = $ARGV[0];
        shift;
    }
    # quiet mode
    elsif ($ARGV[0] eq "--quiet" || $ARGV[0] eq "-q") {
        shift;
        $quiet = 1;
        shift;
    }
    # stdout mode
    elsif ($ARGV[0] eq "--stdout") {
        $stdout = 1;
        shift;
    }
}

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

$src      =~ s#/$##;
$binDir   =~ s#/$##;
$objsDir  =~ s#/$##;



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

# cc
$config = "cc:\n\t";
$config .= join(' ', @cc);
$config .= "\n";

# cxx
$config .= "cxx:\n\t";
$config .= join(' ', @cxx);
$config .= "\n";

$config .= "debug cc:
\t$dcc\n";

# libs
$config .= "libs:\n\t";
$config .= join(' ', @libs);
$config .= "\n";

# pkg-config
$config .= "pkgs:\n\t";
$config .= join(' ', @pkgs);
$config .= "\n";

# optimization
$config .= "O:
\t$O\n";

# cflags
$config .= "cflags:\n\t";
$config .= join(' ', @cflags);
$config .= "\n";

# cxxflags
$config .= "cxxflags:\n\t";
$config .= join(' ', @cxxflags);
$config .= "\n";

#name
$config .= "name:
\t$name\n";

# dirs
$config .= "src_directory:
\t$src\n";
$config .= "bin_directory:
\t$binDir\n";
$config .= "objs_directory:
\t$objsDir\n";

# echo
$config .= "echo:
\t$echo\n";

open($file, '>', "vfnmake") or die;
print $file "$config";
close($file);
print "$config" unless $quiet or $stdout;
