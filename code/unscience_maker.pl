#!/usr/bin/perl
use v5.10; # to Say
use strict;
use warnings;

# given a string collapses it to a year in format yyyy
sub collapse_year {
	my $datestring=$_[0];
	my @arr;
	@arr = $datestring=~/1999|2000|2001|2002|2003|2004|2005|2006|2007/gi;
	if (scalar @arr ==1){
		return $arr[0];
	}
	else {
		return "";
	}
}

sub normalize_name {

	# if email just return it
	return $_[0] if $_[0] =~/(\w+\@[\w,.]+)/gio;
	# clean and trim it first
	my $norm_name = $_[0] =~ s/^\s+|\s+$//irgo;
	$norm_name = $norm_name =~s/fla$//irgo;
	my @items = split /\s/,$norm_name ;

	return '' if scalar @items <=1; # orphans ignored for the time being
	return $norm_name;
}

sub detect_people {
	my @people;
	my $domain_stops = '(jeb|governor) (bush|jeb)|eog|\@eog|e-mail|GOV\@Exchange';
	my $clean=$_[0]=~s/^\s+|\s+$|\/|\(|\)|"|\'|//irgo;
	$clean =$clean =~s/$domain_stops//irg;
	my @parts =$clean =~/(\w+\@[\w,.]+)/gio; # array is used to get the list context

	#simple email or email name pair
	if (scalar @parts==1) {
		my $other=$clean=~s/(\w+\@[\w,.]+)|"|<|>//giro;
		if (length $other >0) {
			push @people, $other
		}
		else {
			push @people, $parts[0];
		}

	}
	else {
		push @people, $clean if scalar (split /\s/,$clean) > 1; # it is just a name or an orphan
	}
	return @people;

}


# givev a string (most likely from a to field, extract all the people name (when possible) or email)
sub harvest_names  {
	my @names;

	my @items =split /;/,$_[0];
	@items =split /,/,$_[0] if scalar (@items ==1);

	for my $item(@items) {
		if ($item!~/florida governor|unprivileged user|correspondence opb|jeb\@jeb.org/i){
			my @people = detect_people $item;
			for my $person (@people) {
				#say $person;
				push @names,(normalize_name $person);

			}
		}
	}


	return @names;
}


# given a string (most likely from a to field, extract the .com company name)
sub harvest_company {

	# is it an email at all

	return "" if $_[0] !~ /@/;

	my $provider_companies ="aol|yahoo|hotmail|gmail|juno|msn|peoplepc|mindspring|netzero|myflorida|cs";

	if ($_[0] !~ /$provider_companies/i){

		my $suffix= substr $_[0], (index $_[0], '@')+1;

		$suffix =substr $suffix,0,(index $suffix,'.');
		return $suffix=$suffix=~s/\W//r;
	}
	else {
		return '';
	}

}

# given a file compute influencer fds for all the years

sub compute_influencers {
	open(my $fh,'<', $_[0])
		or die "Could not open file '$_[0]' $!";
	my %fd;
	my $count=0;

	while ( my $raw_line = <$fh>) {

		my $line=$raw_line=~s/\R/\n/r; #getting rid of unicode line breaks, chomp does not get them
		chomp($line);
		my @fields =split /\t/,$line;
		if (scalar(@fields)==4){

			if ($fields[0] and $fields[1] and $fields[0] =~/Jeb Bush|Governor/i) {

				# get all the names (i.e name email pairs)
				my @names= harvest_names($fields[1]);
				my $year = collapse_year($fields[2]);

				if ($year) {
					for my $name (@names) {
						if (exists $fd {$year} {lc $name}) {
							$fd{$year}{lc $name} ++;
						}
						else {
							$fd {$year}{lc $name}=1;
						}
					}
				}
			};

		}

	}
	return %fd;
}

# .coms
sub compute_companies {
	open(my $fh,'<', $_[0])
		or die "Could not open file '$_[0]' $!";
	my %fd;

	my $count=0;

	while ( my $raw_line = <$fh>) {

		my $line=$raw_line=~s/\R/\n/r; #getting rid of unicode line breaks, chomp does not get them
		chomp($line);
		my @fields =split /\t/,$line;
		if (scalar(@fields)==4){
			if ($fields[0] and $fields[1] and $fields[0] =~/Jeb Bush|Governor/i and $fields[1]=~/\.com/) {
				#say $fields[1];
				my $company =harvest_company($fields[1]);
				my $year = collapse_year($fields[2]);
				if ($year) {
					if ($company){
						if (exists $fd {$year} {lc $company}) {
							$fd{$year}{lc $company} ++;
						}
						else {
							$fd {$year}{lc $company}=1;
						}
					}
				}

			};

		}
	}
	return %fd;
}



# parameters the_fd and top. Will return top n fd
# note the returned fd is not sorted. it contains the top n but if displayed through a simple loop
# the values will come in random order
sub topN {
	my %param = @_;
	# reverse sort used to get the keys in descending order of values
	my @keys_sorted_by_val = reverse sort {$param{the_fd}{$a} <=> $param{the_fd}{$b}} keys $param{the_fd};

	my @top_n_keys = splice @keys_sorted_by_val, 0, $param{top};


	my %fd;

	for my $key (@top_n_keys) {

		$fd{$key} =$param{the_fd}{$key};
	}


	return  %fd;

}


# print out tab seperated fds to pull in google sheets  etc.
sub write_fd {
	my %params = @_;
	my $line;
	my %fd = %{$params{the_fd}};
	for my $word (keys %fd) {
		say $word.$params{d}.$fd{$word};

	}

}

######## Investigators ###########


# counts emails for a given year
sub how_many_emails {

	open(my $fh,'<', $_[0])
		or die "Could not open file '$_[0]' $!";

	my $count=0;

	while ( my $raw_line = <$fh>) {

		my $line=$raw_line=~s/\R/\n/r; #getting rid of unicode line breaks, chomp does not get them
		chomp($line);
		my @fields =split /\t/,$line;
		if ($fields[2] && scalar @fields ==4) {
			my $year = collapse_year($fields[2]);
			$count++ if ($year && $year==$_[1]);
		}

	}
	return $count;
}



############# End investigators ######################



# Generate all the FDS
sub do_unscience {
	my %params =@_;
	my %fd;
	my $fh;

	my %dispatch =(
		influencer=>\&compute_influencers,
		company=>\&compute_companies,

	);
	%fd= $dispatch{$params{the_type}}->($params{input_file});
	for my $year (keys %fd) {
		open $fh, '>', $params{the_path}."$params{the_type}".'_'.substr ($year,2,2).'.txt' or die"Could not ----open file '$_[0]' $!";
		print $fh (format_luca_string(topN (top=>50, the_fd=>$fd{$year})));
		close $fh;
	}
}
