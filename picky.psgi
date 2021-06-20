#!/usr/bin/perl
# Random pic viewer
use strict;
use warnings;
use Plack::Request;
use Plack::Builder;
use DBI;
use File::Slurp;

my $docpath = "/data/textfiles";  # Where the docs at
my $debug = 1;
my $db='storiesDb';
my $dbusername='storiesUser';
my $dbpassword='biggunsPass';

# Database Inits
my $dsn = "DBI:mysql:host=localhost;database=$db";
our $dbh;
our $env;  # Main plack environment
our $request;
our $html;
our ($totfiles, $score, $views, $id);
our $search = 'Search';
our $filename = 'not loaded'; # Currently loaded file
my $last_scan;
connect_db();
rescan_files();

my $root = '/var/www/';

my $app = sub {     # Main loop
	my $reload_last = 0;
	my $edit=0;
	my $error = undef;
	$env = shift;
	print STDERR "LOOP\n";
	$request = Plack::Request->new($env);

	# Re-scan and import all files if not been run for a while
	if ($last_scan < (time() - 3600)) {
		print STDERR "Been a while, rescanning files.\n";
		rescan_files();
		}

	if ( not $dbh->ping ) {  connect_db();  }			# Check DB is still there

	my $sql = "SELECT * FROM storiesTb ORDER BY RAND() LIMIT 1;";		# random choice, no weighting


	# Check for additional quick actions and modify query
	if ($request->param('edit_text') ) {  # Some text has been submitted
		my $new_text = $request->param('edit_text');
		my $new_filename = $request->param('edit_fn');

		# Write out new file
		if ($debug == 1) { print STDERR "Received edited file: $new_filename\n"; }

		if (length($new_filename) < 5) { print STDERR "Filename too short: $new_filename\n"; $error="Filename too short: $new_filename";  }
		if (length($new_text) < 5) { print STDERR "File text too short: $new_text\n";  $error="File text too short: $new_text";  }

		# Write to the file, overwriting if an edit, creating if new
		my $newwritefile = $docpath . '/' . $new_filename;
		if ($debug == 1) { print STDERR "Writing to file: $newwritefile \n"; }

		if (! $error)  {
			write_file( $newwritefile, $new_text ) ;
			$dbh->do("INSERT IGNORE INTO storiesTb (filename) VALUES ('$new_filename') ");
			}

		}

	if ($request->param('q') ) {
		my $qa_val = $request->param('q');
		if ($qa_val eq 'vu')		{  $dbh->do("UPDATE storiesTb SET score = score + 10 WHERE id = '$id' LIMIT 1; "); }		# Upvote
		if ($qa_val eq 'vd')		{  $dbh->do("UPDATE storiesTb SET score = score - 10 WHERE id = '$id' LIMIT 1; "); }		# Downvote
		if ($qa_val eq 'vb')		{  $dbh->do("UPDATE storiesTb SET score = 100 WHERE id = '$id' LIMIT 1; "); }				# Topvote
		if ($qa_val eq 'reload')	{ print STDERR "Refreshing\n"; $reload_last =1; }		# Don't load another, re-parse previous

		if ($qa_val eq 'tr')		{   $sql = "SELECT * FROM storiesTb WHERE score > 80 ORDER BY RAND() LIMIT 1;"; }				# Top random

		if ($qa_val eq 'edit')	{ print STDERR "Editing ($filename)\n";	 edit_file($filename);	$edit=1; }		# Edit this file
		if ($qa_val eq 'add')	{ print STDERR "Adding file\n";			edit_file();			$edit=1; }			# Add a new file
		}
	if ($request->param('s') ) {  # Search
		$search = $request->param('s');
		$sql = "SELECT * FROM storiesTb WHERE filename LIKE '%$search%' ORDER BY RAND() LIMIT 1;"
		}

	if ($request->param('del') ) {  # Delete
		my $todel = $request->param('del');
		my $deletefile = $docpath . '/' . $todel;
		print STDERR "Deleting file: $deletefile\n";
		unlink( $deletefile);
		# Remove from the database
		 $dbh->do("DELETE FROM storiesTb WHERE filename = '$todel' LIMIT 1; ");
		}

	# Got final query, execute

	if ($reload_last == 0) {
		my $sth = $dbh->prepare($sql);
		$sth->execute();
		my $a = $sth->fetchrow_hashref();
		$id = $a->{'id'};
		$filename = $a->{'filename'};
		$score = $a->{'score'};
		$views = $a->{'views'};
		}

	if ($debug) { print STDERR "Showing: $filename\n"; }

	# Display header if not editing;
	if ($edit == 0) {
		$html =show_header();

		# Load file, tidy it then display.
		my $textfile = $docpath . '/' . $filename;
		if ( (! $filename ) || (! -e $textfile) ) { print STDERR "ERROR: File does not exist, looping: $textfile ($filename)\n\n"; $error="ERROR: File does not exist! $textfile ($filename)";}
		my $content = read_file($textfile);
		$content =~ s/\n/<br>\n/g;
		$content =~ s/â€œ/"/g;
		$content =~ s/â€\™/'/g;
		$content =~ s/Â©/<br>/g;
		$content =~ s/â€/"/g;
		$content =~ s/â€“//g;	# Junk
		$html .= "<big>" . $content . "</big>";
		$html .= "</div></div>\n"; # End jumbotron

		# Increment view
		$dbh->do("UPDATE storiesTb SET views = views + 1 WHERE id = '$id' LIMIT 1; ");
		}

	if ($error)  {
		$html = show_header() . "<h4>$error</h4>";
		}

	return [
		'200',
		[ 'Content-Type' => 'text/html' ],
		[ $html ],
		];
	}; # End main loop

sub connect_db { # Connect to database;
	our $dbh = DBI->connect ($dsn, $dbusername, $dbpassword)  or die "Cannot connect to server ".DBI->errstr."\n";
	}

sub rescan_files {  # Scan filedir and import all files if they don't exist.
	print STDERR "Rescanning files\n";
	my @files = glob( $docpath . '\/*' );
	$totfiles = scalar(@files);
	# Update database record
	foreach(@files) {
		my $short_filename = $dbh->quote(substr($_, rindex($_,"/")+1, length($_)-rindex($_,"/")-1));

		my $sql = "INSERT IGNORE INTO storiesTb (filename) VALUES ($short_filename) ";
		my $sth = $dbh->prepare($sql);
		$sth->execute();
#		print STDERR "DEBUG2 ($sql)\n";
		}

	$last_scan = time();
	}

builder {
        enable 'Plack::Middleware::Static',
            path => qr{^/(favicon.ico|robots.txt)},
            root => "$root/";
        $app;
    };

sub edit_file {
	my $editfile = shift;
	my $mode = 'edit';
	if (! $editfile) { $mode = 'add'; }	# No filename supplied, it's a new one
	my $editbuffer = undef;

	$html =show_header();

	# Start form
	$html .= qq~ <form action = "./" method="post">
		~;

	$html .= qq~
	<div class="form-group">
		<label for="edit_fn">Text</label>
		<input type="text" class="form-control" name="edit_fn" placeholder="Enter filename"   value="$editfile">
	</div>
	~;

	if ($mode eq 'edit') {		 # Load an existing file
		my $loadfile = $docpath . '/' . $editfile;
		print STDERR "Loading for edit: $loadfile\n";
		$editbuffer = read_file($loadfile);
		}


	# Display buffer in editbox
	$html .= qq~
	 <div class="form-group">
		<label for="edit_text">Text</label>
<textarea class="form-control"  name="edit_text" rows="100">
$editbuffer
</textarea>
	  </div>
		<div class="form-group">
		<button type="submit" class="btn btn-default">Submit</button>
		</div>
	      </form>
	</div></div>
	~;

	}

sub show_header {
$views++;		# So it includes this read
return qq~
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.min.js" integrity="sha512-bLT0Qm9VnAYZDflyKcBaQ2gg0hSYNQrJ8RilYldYQ1FxQYoCLtUjuuRuZo+fjqhx/qtq/1itJ0C2ejDxltZVFg==" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datetimepicker/4.17.47/js/bootstrap-datetimepicker.min.js" integrity="sha512-GDey37RZAxFkpFeJorEUwNoIbkTwsyC736KNSYucu1WJWFK9qTdzYub8ATxktr6Dwke7nbFaioypzbDOQykoRg==" crossorigin="anonymous"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.1/css/all.min.css" integrity="sha512-+4zCK9k+qNFUR5X+cKL9EIR+ZOhtIloNl9GIKS57V1MyNsYpYcUrUeQc9vNfzsWfV28IaLL3i96P9sdNyeRssA==" crossorigin="anonymous" />

<nav class="navbar navbar-default navbar-fixed-top">
  <div class="container-fluid">
    <div class="navbar-header">

      <a class="navbar-brand" href="?">Picky <i class="fa fa-random"></i></a>
    </div>

    <div class="collapse navbar-collapse" >
      <ul class="nav navbar-nav nav-pills">
        <li  class="active"><a href="?q=tr"><span title="Top Random">Top <i class="fa fa-random"></i></span></a></li>
	<p class="navbar-text">    Score:</p>
        <li><a href="?q=vu"><span title="Vote up"><i class="fa fa-chevron-up"></i></span></a></li>
        <li><a href="?q=vb"><span title="Vote best"><i class="fa fa-trophy"></i></span></a></li>
        <li><a href="?q=vd"><span title="Vote down"><i class="fa fa-chevron-down"></i></span></a></li>
	<p class="navbar-text">($score/100)</p>
	<li><a href="?q=edit">Edit</a></li>
	<li><a href="?q=add">Add</a></li>

      </ul>

      <ul class="nav navbar-nav navbar-right">
	      <p class="navbar-text small">\"$filename\" - $views reads (#$id / $totfiles)</p>
	        <li ><a href="?q=reload"><span title="Reload"><i class="fa fa-sync"></i></span></a></li>
	      <form class="navbar-form navbar-left" action="./">
		<div class="form-group">
		  <input type="text" class="form-control" name="s" id = "s" placeholder="$search">
		</div>
		<button type="submit" class="btn btn-default">Search</button>
	      </form>
        <li><a href="?del=$filename">Delete</a></li>
      </ul>
    </div><!-- /.navbar-collapse -->
  </div><!-- /.container-fluid -->
</nav>

<div class="container">
	<div class="jumbotron">
~;
}
