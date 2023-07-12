#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;
use Data::Dumper;
use Inline 'C';
use Math::DCT;
use Time::HiRes qw(time);

my $M_PI  = 3.14159265358979323846;
my ($sz, $algo, $v) = @ARGV;
$algo ||= '';
$sz ||= 256;

my @array2d;
push @array2d, [ map { rand(256) } ( 1..$sz )] for 1..$sz;

my $t = time();
my $dct;
if ($algo eq 'naive') {# Extremely slow for large sizes at O(n^4)
    $dct = naive_perl_dct2d(\@array2d);
} elsif ($algo eq 'naive_c') { # Extremely slow for large sizes at O(n^4) (but uses xs)
    $dct = dct_xs(\@array2d, 1);
} elsif ($algo eq 'c') { # Slow for large sizes at O(n^3) (but uses xs)
    $dct = dct_xs(\@array2d);
} else { # Slow for large sizes at O(n^3)
    $dct = perl_dct2d(\@array2d);
}
printf "Time: %.3f\n",time()-$t;
print Dumper($dct) if $v;

sub perl_dct2d {
    my $vector = shift;
    my $sz     = scalar(@$vector);
    my @coef   = dct_coef($sz);
    my (@temp, @result);

    for (my $x = 0; $x < $sz; $x++) {
        for (my $i = 0; $i < $sz; $i++) {
            my $sum = 0;
            $sum += $vector->[$x]->[$_] * $coef[$_][$i] for 0..$sz-1;
            $temp[$x][$i] = $sum;
        }
    }

    for (my $y = 0; $y < $sz; $y++) {
        for (my $i = 0; $i < $sz; $i++) {
            my $sum = 0;
            $sum += $temp[$_][$y] * $coef[$_][$i] for 0..$sz-1;
            $result[$i]->[$y] = $sum;
        }
    }
    return \@result;
}

sub dct_coef {
    my $sz   = shift;
    my $fact = $M_PI/$sz;
    my @coef;

    for (my $i = 0; $i < $sz; $i++) {
        my $mult = $i*$fact;
        $coef[$_][$i] = cos(($_+0.5)*$mult) for 0..$sz-1;
    }
    return @coef;
}

sub naive_perl_dct2d {
    my $vect = shift;
    my $sz   = scalar(@$vect);
    my $fact = $M_PI/$sz;
    my $result;

    for (my $y = 0; $y < $sz; $y++) {
        for (my $x = 0; $x < $sz; $x++) {
            for (my $i = 0; $i < $sz; $i++) {
                my $sum = 0;
                $sum += $vect->[$_]->[$i] *
                    cos(($_ + 0.5) * $x * $fact) *
                    cos(($i + 0.5) * $y * $fact)
                    for 1 .. $sz - 1;
                $result->[$x]->[$y] += $sum;
            }
        }
    }
    return $result;
}

sub dct_xs {
    my $vector = shift;
    my $naive  = shift;
    my $sz     = scalar(@$vector);

    my $pack;
    $pack .= pack "d$sz", @{$vector->[$_]} for 0 .. $sz - 1;
    $naive ? dct_2d_naive($pack, $sz) : dct_2d($pack, $sz);

    my $result;
    $result->[$_] = [unpack "d" . ($sz), substr $pack, $_ * $sz * 8, $sz * 8]
        foreach 0 .. $sz - 1;
    return $result;
}

__END__
__C__

#ifndef M_PI
    #define M_PI 3.14159265358979323846
#endif

void dct_coef(int size, double coef[size][size]) {
    double factor = M_PI/size;
    int i, j;
    for (i = 0; i < size; i++) {
        double mult = i*factor;
        for (j = 0; j < size; j++) {
            coef[j][i] = cos((j+0.5)*mult);
        }
    }
}

void dct_2d(
    char *inbuf,
    int   size)
{
    double *input = (double *) inbuf;
    double  coef[size][size];
    double  temp[size*size];
    int x, y, i, j;

    dct_coef(size, coef);

    for (x = 0; x < size; x++) {
        for (i = 0; i < size; i++) {
            double sum = 0;
            y = x * size;
            for (j = 0; j < size; j++) {
                sum += input[y+j] * coef[j][i];
            }
            temp[y+i] = sum;
        }
    }

    for (y = 0; y < size; y++) {
        for (i = 0; i < size; i++) {
            double sum = 0;
            for (j = 0; j < size; j++) {
                sum += temp[j*size+y] * coef[j][i];
            }
            input[i*size+y] = sum;
        }
    }
}

void dct_2d_naive(
    char *inbuf,
    int   size)
{
    double *input = (double *) inbuf;
    double  fact  = M_PI/size;;
    int x, y, i, j;

    for (y = 0; y < size; y++) {
        for (x = 0; x < size; x++) {
            for (i = 0; i < size; i++) {
                double sum = 0;
                for (j = 0; j < size; j++) {
                    sum += input[j * size+i] * cos((j+0.5) * x * fact) * cos((i+0.5) * y * fact);
                }
                input[x*size+y] += sum;
            }
        }
    }
}
