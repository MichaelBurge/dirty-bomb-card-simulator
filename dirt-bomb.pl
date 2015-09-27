use strict;
use warnings;
use v5.16;
use Data::Dumper;
use List::Util qw/ sum /;

my %personal_cards = (
	lead            => 49,
	iron            => 18,
	bronze          => 7,
	silver          => 16,
	gold            => 2,
	cobalt          => 0,
    );

my %no_cards = (
	lead            => 0,
	iron            => 0,
	bronze          => 0,
	silver          => 0,
	gold            => 0,
	cobalt          => 0,
    );
sub new_state {
    return {
	total_cost      => 0,
	total_fusions   => 0,
	total_cases     => 0,
	failed          => 0,
	original_lead   => 0,
	original_iron   => 0,
	original_bronze => 0,
	original_silver => 0,
	original_gold   => 0,
	original_cobalt => 0,
	fusion_lead    => 0,
	fusion_iron    => 0,
	fusion_bronze  => 0,
	fusion_silver  => 0,
	fusion_gold    => 0,
	
        %no_cards,
    };
}

my %base_probabilities = (
    lead   => 0.80,
    iron   => 0.15,
    bronze => 0.03,
    silver => 0.015,
    gold   => 0.004,
    cobalt => 0.001,
    );

my %num_fusions = (
    lead   => 3,
    iron   => 3,
    bronze => 3,
    silver => 4,
    gold   => 4,
    cobalt => 6,
    );

my %fusion_costs = (
    lead   => 500,
    iron   => 1000,
    bronze => 2000,
    silver => 4000,
    gold   => 10000,
    );

my %next_types = (
    lead   => 'iron',
    iron   => 'bronze',
    bronze => 'silver',
    silver => 'gold',
    gold   => 'cobalt',
    );

sub total_probability {
    my @types = @_;
    return sum map { $base_probabilities{$_} } @types;
}

my %probabilities = (
    lead   => total_probability(qw/ lead /),
    iron   => total_probability(qw/ lead iron /),
    bronze => total_probability(qw/ lead iron bronze /),
    silver => total_probability(qw/ lead iron bronze silver /),
    gold   => total_probability(qw/ lead iron bronze silver gold /),
    );

sub roll {
    my ($state) = @_;
    $state->{total_cost} += 1000;
    $state->{total_cases}++;
    my $random = rand();
    for my $type (qw/ lead iron bronze silver gold /) {
	if ($random < $probabilities{$type}) {
	    $state->{$type}++;
	    $state->{"original_$type"}++;
	    return;
	}
    }
    $state->{cobalt}++;
}

sub apply_fusion
{
    my ($state, $type) = @_;
    my $next_type = $next_types{$type};
    if ($state->{$type} >= $num_fusions{$type}) {
	$state->{$type} -= $num_fusions{$type};
	$state->{$next_type}++;
	$state->{total_cost} += $fusion_costs{$type};
	$state->{total_fusions}++;
	$state->{"fusion_$type"}++;
	return 1;
    }
    return 0;
}

sub apply_all_fusions {
    my ($state) = @_;
    for my $type (qw/ lead iron bronze silver gold /) {
	while (apply_fusion($state, $type)) { }
    }
}

sub loop
{
    my ($stop_function, $max_cases) = @_;
    
    my $state = new_state();

    while (! $stop_function->($state)) {
	if ($state->{total_cases} >= $max_cases) {
	    $state->{failed}++;
	    return $state;
	}
	roll($state);
	apply_all_fusions($state);
    }
    return $state;
}

sub print_state
{
    my ($state) = @_;
    my @attributes = (qw/
        total_cost
        total_fusions
        total_cases
        original_lead
        original_iron
        original_bronze
        original_silver
        original_gold
        original_cobalt
        fusion_lead
        fusion_iron
        fusion_bronze
        fusion_silver
        fusion_gold
        lead
        iron
        bronze
        silver
        gold
        cobalt
	/);
    for my $attribute (@attributes) {
	say "$attribute: @{[ $state->{$attribute} ]}";
    }
}

sub print_trial_state
{
    my ($trial_state) = @_;
    my @attributes = (qw/
        total_trials
        total_failures
    /);
    for my $attribute (@attributes) {
	say "$attribute: @{[ $trial_state->{$attribute} ]}";
    }
    my $trials = $trial_state->{total_trials};
    my $avg = sub { 
	my ($attribute) = @_;
	return ($trial_state->{$attribute} + 0.0) / $trials;
    };
    say "Average trials: @{[ $avg->('total_trials') ]}";
    say "Average fusions: @{[ $avg->('total_fusions') ]}";
    say "Average cost: @{[ $avg->('total_cost') ]}";
    say "Average cases: @{[ $avg->('total_cases') ]}";
    say "Average lead: @{[ $avg->('original_lead') ]}";
    say "Average iron: @{[ $avg->('original_iron') ]}";
    say "Average bronze: @{[ $avg->('original_bronze') ]}";
    say "Average silver: @{[ $avg->('original_silver') ]}";
    say "Average gold: @{[ $avg->('original_gold') ]}";
    say "Average cobalt: @{[ $avg->('original_cobalt') ]}";
    say "Average lead fusions: @{[ $avg->('fusion_lead') ]}";
    say "Average iron fusions: @{[ $avg->('fusion_iron') ]}";
    say "Average bronze fusions: @{[ $avg->('fusion_bronze') ]}";
    say "Average silver fusions: @{[ $avg->('fusion_silver') ]}";
    say "Average gold fusions: @{[ $avg->('fusion_gold') ]}";
}

sub stop_on_n_cards
{
    my ($type, $amount) = @_;
    return sub {
	my ($state) = @_;
	return ($state->{$type} >= $amount);
    };
}

sub accumulate_trial
{
    my ($trial_state, $state) = @_;
    for my $attribute (qw/
        total_cost
        total_fusions
        total_cases
        original_lead
        original_iron
        original_bronze
        original_silver
        original_gold
        original_cobalt
        fusion_lead
        fusion_iron
        fusion_bronze
        fusion_silver
        fusion_gold
    /) {
	$trial_state->{$attribute} //= 0;
	$trial_state->{$attribute} += $state->{$attribute};
    }
    $trial_state->{total_failures} += $state->{failed};
    $trial_state->{total_trials}++;
}

sub trial
{
    my ($stop_function, $num_iterations, $max_cases) = @_;
    my $trial_state = {
	total_trials   => 0,
	total_cost     => 0,
	total_fusions  => 0,
	total_cases    => 0,
	total_failures => 0,
	fusion_lead    => 0,
	fusion_iron    => 0,
	fusion_bronze  => 0,
	fusion_silver  => 0,
	fusion_gold    => 0,
	
    };
    while ($num_iterations--) {
	my $state = loop($stop_function, $max_cases);
	accumulate_trial($trial_state, $state);
    }
    return $trial_state;
}

sub main
{
    my $stop_function = stop_on_n_cards('cobalt', 1);
    my $num_iterations = 1000;
    my $max_cases = 10000;
    my $trial_state = trial($stop_function, $num_iterations, $max_cases);
    print_trial_state($trial_state);
}

main();
