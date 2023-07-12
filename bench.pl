#!/usr/bin/env perl

use strict;
use warnings;
use v5.020;
use utf8;

use Benchmark qw(cmpthese);
use List::Util;
use Ref::Util qw(is_plain_arrayref is_plain_hashref);
use Try::Tiny;

# File I/O
use Fcntl qw(:flock);
use File::Slurp 'read_file';
use File::Slurper 'read_text';
use Path::Tiny qw(path);

# Time/Date
use DateTime::Format::DateParse;
use Date::Parse;
use Time::Local qw( timelocal );
use Time::Piece;
use POSIX qw(mktime);

say "For loops:";

cmpthese(-2, {
    c_for => sub {
        my $sum;
        for (my $i = 1; $i <= 100; $i++) { $sum += $i*$i; }
    },
    foreach => sub {
        my $sum;
        foreach my $i (1..100) { $sum += $i*$i; }
    },
    postfix => sub {
        my $sum;
        $sum += $_*$_ for 1..100;
    },
});

say "\nSubstitution:";

my $template = ('abc'x1000 .'!one!'.'def'x1000 .'!two!'.'ghi'x1000 .'!three!'.'jkl'x1000)x100;

cmpthese(-2, {
    multipass => sub {
        my $str = $template;
        $str =~ s/!one!/1/g;
        $str =~ s/!two!/2/g;
        $str =~ s/!three!/3/g;
    },
    hash => sub {
        my %hash = (one => 1, two => 2, three => 3);
        my $find = join '|', keys %hash;
        my $str = $template;
        $str =~ s/!($find)!/$hash{$1}/g;
    },
});


say "\nConditions:";

my @elements = map {
          rand(2) < 1   ? 'value'
        : rand(2) < 1   ? 'other value'
        : rand(1.5) < 1 ? 'rare value'
        : 'rarest value'
} 1 .. 100;

cmpthese(-2, {
    regex => sub {
        my $cnt;
        for (@elements) {
            $cnt++ if /^(?:rare(?:st) )?value$/;
        }
    },
    hash => sub {
        my %hash = ('value' => 1, 'rare value' => 1, 'rarest value' => 1);
        my $cnt;
        for (@elements) {
            $cnt++ if $hash{$_};
        }
    },
    cmp_opt => sub {
        my $cnt;
        for (@elements) {
            $cnt++ if $_ eq 'value' || $_ eq 'rare value'|| $_ eq 'rarest value';
        }
    },
    cmp => sub {
        my $cnt;
        for (@elements) {
            $cnt++ if $_ eq 'rarest value' || $_ eq 'value' || $_ eq 'rare value';
        }
    },
});

say "\nSearch array:";

my @array = 1..10;
my %hash = map {$_ => 1} @array;
cmpthese(-2, {
    first => sub {
        my $find = List::Util::first {$_ eq int(rand(20))} @array;
    },
    hash => sub {
        my $find = $hash{int(rand(20))};
    },
    hash_static => sub {
        my %hash = (
            1 => 1,
            2 => 1,
            3 => 1,
            4 => 1,
            5 => 1,
            6 => 1,
            7 => 1,
            8 => 1,
            9 => 1,
            10 => 1,
        );
        my $find = grep {$_ eq int(rand(20))} @array;
    },
    hash_for => sub {
        my %hash;
        $hash{$_} = 1 for @array;
        my $find = grep {$_ eq int(rand(20))} @array;
    },
    hash_map => sub {
        my %hash = map {$_ => 1} @array;
        my $find = grep {$_ eq int(rand(20))} @array;
    },
});

say "\nRegex:";

my $str = "the rain in Spain stays mainly in the plain";

cmpthese(-2, {
    literal => sub {$str =~ /Spain/},
    group   => sub {$str =~ /(?:Spain)/},
    ci      => sub {$str =~ /Spain/i},
    g      => sub {$str =~ /Spain/g},
    capture => sub {$str =~ /(Spain)/},
    dotstar => sub {$str =~ /.*Spain/},
});

say "\nChop vs subst:";

my $test = 'abc,'x10;

cmpthese(-2, {
    chop => sub {
        my $string = $test;
        chop($string);
    },
    substr => sub {
        my $string = substr($test, 0, -1);
    },
    subst => sub {
        my $string = $test;
        $string =~ s/.$//;
    },
});

say "\nUnicode vs bytes:";

my $origin = ('ábc'x100 .'</a><q>'.'def'x100 .'</q>')x1000;
my $bytes = $origin;
utf8::downgrade($bytes);

cmpthese(-2, {
    unicode => sub {
        my $string = $origin;
        $string =~ s/<q>.*?<\/q>//g;
    },
    bytes => sub {
        my $string = $bytes;
        $string =~ s/<q>.*?<\/q>//g;
    },
    byte_convert => sub {
        my $string = $origin;
        utf8::downgrade($string);
        $string =~ s/<q>.*?<\/q>//g;
        utf8::upgrade($string);
    },
});

say "\nIf defined:";

cmpthese(-2, {
    ifdefined => sub {
        my $sum;
        $sum = 0 if !defined $sum;
    },
    defopper => sub {
        my $sum;
        $sum //= 0;
    },
    unless => sub {
        my $sum;
        $sum = 0 unless $sum;
    },
    ifopper => sub {
        my $sum;
        $sum ||= 0;
    },
});


say "\nSlurp methods:";

system "gunzip *.gz";

cmpthese(-2, {
    'while (<fh>)' => sub {
        foreach (0..2){
            open my $fh, '<', "wiki$_.html" or die "Can't open file $!";
            my $content;
            while (<$fh>) {
                $content .= $_;
            }
            close $fh;
        }
    },
    'read -s' => sub {
        foreach (0..2){
            open my $fh, '<', "wiki$_.html" or die "Can't open file $!";
            read $fh, my $file_content, -s $fh;
            close $fh;
        }
    },
    'local_$/' => sub {
        foreach (0..2){
            open my $fh, '<', "wiki$_.html" or die "Can't open file $!";
            my $file_content = do { local $/; <$fh> };
            close $fh;
        }
    },
    'File::Slurp::read_file' => sub {
        my $file_content = read_file("wiki$_.html") for 0..2;
    },
    'File::Slurper::read_text' => sub {
        my $file_content = read_text("wiki$_.html") for 0..2;
    },
    'Path::Tiny::slurp_utf8' => sub {
        my $content = path("wiki$_.html")->slurp_utf8 for 0..2;
    },
    'Path::Tiny::slurp' => sub {
        my $content = path("wiki$_.html")->slurp for 0..2;
    },
});

say "\nNull sub:";

cmpthese(-2,{
    with_amp    => sub {&null_sub},
    without_amp => sub {null_sub()},
});

sub null_sub {return;}

say "\nNon-null sub:";

cmpthese(-2,{
    with_amp    => sub {&nonnull_sub},
    without_amp => sub {nonnull_sub()},
});

sub nonnull_sub {
    my $res = 0;
    $res += map {rand(1000)} (1 .. 10);
    return $res;
}

say "\nParse date:";

my @zones = qw#Europe/London America/New_York#;

cmpthese(-2, {
    "Date::Parse" => sub {
        my $time = parse(randdate() , $zones[int(rand(2))]);
    },
    "Time::Local" => sub {
        my $time = time_local(randdate() , $zones[int(rand(2))]);
    },
    "POSIX mktime" => sub {
        my $time = posix(randdate() , $zones[int(rand(2))]);
    },
    "Time::Piece" => sub {
        my $time = timepiece(randdate() , $zones[int(rand(2))]);
    },
    "DateTime" => sub {
        my $time = date_time(randdate() , $zones[int(rand(2))]);
    },
});

sub randdate {
    return sprintf ("%d-%02d-%02d %02d:%02d:%02d", int(rand(10))+2015, int(rand(12))+1, int(rand(28))+1, int(rand(20))+4, int(rand(60)), int(rand(60)));
}

sub parse {
    my $str = shift;
    my $tz = shift;
    my $return;
    try {
        local $ENV{TZ} = $tz;
        $return = Date::Parse::str2time($str);      
    } catch {
        warn "$str - DP not valid date";
        $return = 0;
    };

    return $return;
}

sub time_local {
    my $str = shift;
    my $tz = shift;
    my $return;
    try {
        if ($str =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        local $ENV{TZ} = $tz;
        $return = timelocal( $6, $5, $4, $3, $2-1, $1-1900 );
        } else {
            warn "Can't parse $str";
        }
    } catch {
        warn "$str - TL not valid date";
        $return = 0;
    };

    return $return;

}

sub posix {
    my $str = shift;
    my $tz = shift;
    my $return;
    try {
        if ($str =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        local $ENV{TZ} = $tz;
        $return = mktime( $6, $5, $4, $3, $2-1, $1-1900 );
        } else {
            warn "Can't parse $str";
        }
    } catch {
        warn "$str - P not valid date";
        $return = 0;
    };

    return $return;

}

sub timepiece {
    my $str = shift;
    my $tz = shift;
    my $return;
    try {
        local $ENV{TZ} = $tz;
        my $t = Time::Piece::localtime->strptime($str,"%Y-%m-%d %H:%M:%S");
        $return = $t->epoch;
    } catch {
        warn "$str - TP not valid date";
        $return = 0;
    };

    return $return;
}

sub date_time {
    my $str = shift;
    my $tz = shift;
    my $return;
    try {
        my $dt = DateTime::Format::DateParse->parse_datetime($str, $tz);
        $return = $dt->epoch;
    } catch {
        warn "$str - DT not valid date";
        $return = 0;
    };

    return $return;
}

say "\nRef:";

my $ref = [];

cmpthese(-2, {
    refutil => sub {
        my $res = is_plain_arrayref($ref);
        $res = is_plain_hashref($ref);
    },
    ref_eq => sub {
        my $res = ref($ref) eq 'ARRAY';
        $res = ref($ref) eq 'HASH';
    },
});

