#!/usr/bin/perl

package outlines;

use Carp;
use Getopt::Long;
use PDF;
use Text::CSV

$objects = 0;
$offsets = 1;

#constructor setting up class variables
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = { PDFFile => undef, FILE  => undef, DICTIONARY  => undef, URLS => undef};
	bless( $self, $class );
	return $self;
}

#setter functions
sub pdffile {
	my $self = shift;
	if (@_) { $self->{PDFFile} = shift }
	return $self->{PDFFile};
}
sub file {
	my $self = shift;
	if (@_) { $self->{FILE} = shift }
	print "self->{FILE} is $self->{FILE}\n";
	return $self->{FILE};
}

sub dictionary {
	my $self = shift;
	if (@_) { $self->{DICTIONARY} = shift }
	return $self->{DICTIONARY};
}

sub urls {
	my $self = shift;
	if (@_) { $self->{URLS} = shift }
	return $self->{URLS};
}

##----------------------------------------------------
##class functions

#add_outlines function recieves following params
#PDF file information, filename of pdf file, outline dictionary
#(if outline dict. is 0 that means it must be created).
#First the function decides if we are to create new dictionary
#or not. Next read in the url file. Open up the pdf document.
#Modify the catalog so that it includes the outline dictionary
#(this is done even if the catalog doesn't need modifying
# so that the objects in the objects/offset table will not
# be all mucked up when it comes time to write the xreference
# table)
#Then append outline dictionary to end of file (either modified
#or created). Then append the top heirarchy related document
#outline.  Then the new file url bookmarks. Call  xref_table
#to write new xreference table. Call trailer to write new trailer.

#table[0][0] - document catalog
#table[0][1] - document catalog offset
#table[1][0] - outline dictionary
#table[1][1] - outline dictionary offset
#table[2][0] - related document outline
#table[2][1] - related document outline offset
#table[3][0] etc - url outlines, read from file
#table[3][1] etc - url outlines offset, read from file

sub add_outlines {

    my $self = shift;

	my @table = ();
	$table[1][$objects] = $self->{DICTIONARY};
	my $PDFfile = $self->{PDFFile};
	my $filename = $self->{FILE};
	print "FILE is $self->{FILE}\n";
	print "DICTIONARY is $self->{DICTIONARY}\n";

	my $url_num = $#urls + 1;

	#if outline dictionary was not present in catalog
	if ( $table[1][$objects] == 0 ) {  #get new object number for new dictionary
		$table[1][$objects] =
		  $PDFfile->{"Trailer"}{"/Size"};    #outline dictionary to be created
		$table[2][$objects] = $table[1][$objects] + 1; #related document outline
	}
	else {    #else get object number for related doc outline to be appended
		$table[2][$objects] =
		  $PDFfile->{"Trailer"}{"/Size"};    #related document outline
	}

	#open up pdf file for appending
	open( FILE, ">> $filename" ) or croak "can't open $filename: $!";
	binmode \*FILE;

	#obtain object number and offset for the document catalog
	$table[0][$objects] = split( /\s/, $PDFfile->{"Trailer"}{"/Root"} );
	$table[0][$offsets] = tell \*FILE;

	#print the modified or original catalog back to the file (appended)
	print FILE "$table[0][$objects] 0 obj";
	print FILE "<<";
	print FILE "/Pages $PDFfile->{\"Catalog\"}{\"/Pages\"}";
	print FILE "/Outlines $table[1][$objects] 0 R";    #only line actually added
	print FILE "/Type /Catalog";
	print FILE "/DefaultGray $PDFfile->{\"Catalog\"}{\"/DefaultGray\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/DefaultGray"} ) );
	print FILE "/DefaultRGB $PDFfile->{\"Catalog\"}{\"/DefaultRGB\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/DefaultRGB"} ) );
	print FILE "/PageLabels $PDFfile->{\"Catalog\"}{\"/PageLabels\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/PageLabels"} ) );
	print FILE "/Names $PDFfile->{\"Catalog\"}{\"/Names\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/Names"} ) );
	print FILE "/Dests $PDFfile->{\"Catalog\"}{\"/Dests\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/Dests"} ) );
	print FILE "/ViewerPreferences $PDFfile->{\"Catalog\"}{\"/ViewerPreferences\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/ViewerPreferences"} ) );
	print FILE "/PageLayout $PDFfile->{\"Catalog\"}{\"/PageLayout\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/PageLayout"} ) );
	print FILE "/PageMode $PDFfile->{\"Catalog\"}{\"/PageMode\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/PageMode"} ) );
	print FILE "/Threads $PDFfile->{\"Catalog\"}{\"/Threads\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/Threads"} ) );
	print FILE "/OpenAction $PDFfile->{\"Catalog\"}{\"/OpenAction\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/OpenAction"} ) );
	print FILE "/URI $PDFfile->{\"Catalog\"}{\"/URI\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/URI"} ) );
	print FILE "/Acroform $PDFfile->{\"Catalog\"}{\"/Acroform\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/Acroform"} ) );
	print FILE "/StructTreeRoot $PDFfile->{\"Catalog\"}{\"/StructTreeRoot\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/StructTreeRoot"} ) );
	print FILE "/SpiderInfo $PDFfile->{\"Catalog\"}{\"/SpiderInfo\"}"
	  if ( defined( $PDFfile->{"Catalog"}{"/SpiderInfo"} ) );
	print FILE ">>";
	print FILE "endobj";

	#obtain offset for outline dictionary
	$table[1][$offsets] = tell \*FILE;

	#append newly created outline dictionary
	print FILE "$table[1][$objects] 0 obj";
	print FILE "<<";
	print FILE "/Type /Outlines";
	print FILE "/Count ", $url_num + 1, "";
	print FILE "/First $table[2][$objects] 0 R";
	print FILE "/Last $table[2][$objects] 0 R";
	print FILE ">>";
	print FILE "endobj";

	#get the related document outline object num and offset
	my $obj = $table[2][$objects];
	$table[2][$offsets] = tell \*FILE;

	#append the top heirarchy related document outline to file
	print FILE "$table[2][$objects] 0 obj";
	print FILE "<<";
	print FILE "/Title (Related Documents)";
	print FILE "/Parent $table[1][$objects] 0 R";
	print FILE "/Count ", $url_num, "";
	print FILE "/First ", $obj + 1, " 0 R";
	print FILE "/Last ", $table[2][$objects] + $url_num, " 0 R";
	print FILE ">>";
	print FILE "endobj";

	my $ind = 3;
	$obj++;

	#store the object nums and offsets of the new related document
	#outlines and write them to the file (must be outline with
	#an action eg go to specific url)
	for $i ( 0 .. $#urls ) {
		$table[$ind][$offsets] = tell \*FILE;
		$table[$ind][$objects] = $obj;
		print FILE "$obj 0 obj";
		print FILE "<<";
		print FILE "/Title ($urls[$i][0])";
		print FILE "/Parent $table[2][$objects] 0 R";
		print FILE "/Next ", $obj + 1, " 0 R" if ( ( $obj + 1 ) <= ( $table[2][$objects] + $url_num ) );
		print FILE "/Prev ", $obj - 1, " 0 R" if ( ( $obj - 1 ) != ( $table[2][$objects] ) );
		print FILE "/A << /Type /Action";
		print FILE "/S /URI";
		print FILE "/URI ($urls[$i][1])";
		print FILE ">>";
		print FILE ">>";
		print FILE "endobj";
		$obj++;
		$ind++;
	}

	#append new X-reference table
	my $xref_offset = tell \*FILE;
	xref_table( \*FILE, $url_num, @table );

	#print trailer
	trailer( \*FILE, $PDFfile, $obj );
	print FILE "$xref_offset";
	print FILE "%%EOF";

	#close FILE;
}

#Modify_outline obtains the object data for the last outline entry. 
#It appends the modified outline dictionary to end of file. Next appends the
#modified last outline.  Then appends the top heirarchy related document outline.  
#Next appends the new file url bookmarks. The function then calls  xref_table
#to write new xreference table. Finally calls function trailer to write new trailer.

#table[0][0] - outline dictionary
#table[0][1] - outline dictionary offset
#table[1][0] - last outline
#table[1][1] - last outline offset
#table[2][0] - related document outline
#table[2][1] - related document outline offset
#table[3][0] etc - url outlines, read from file
#table[3][1] etc - url outlines offset, read from file

sub modify_outlines {

	my $self = shift;

	my $PDFfile = $self->{PDFFile};
	my $file = $self->{FILE};
	my $outline_data = $self->{DICTIONARY};

	#collect the data for the last outline (which must be modified)
	$PDFfile->{"Outlines"}{"/Last"} = $outline_data->{"/Last"};
	my $last_data = $PDFfile->GetObject( $PDFfile->{"Outlines"}{"/Last"} );
		
	my $url_num = $#{$self->{URLS}} + 1;
	print "Number of URLS is $url_num\n";

	my @table;

	#This number is the number to use for the next created object
	#eg the related doc heirarchy
	$table[2][$objects] = $PDFfile->{"Trailer"}{"/Size"};

	open( FILE, ">>", $file ) or croak "Can't open $file: $!";
	binmode \*FILE;
	
	print "Storing the object number and offset of the outline dictionary...\n";

	#store the object number and offset of the outline dictionary
	$table[0][$objects] = split( /\s/, $PDFfile->{"Catalog"}{"/Outlines"} );
	$table[0][$offsets] = tell \*FILE;
	
	print "Appending the outline dictionary to the file...\n";

	#write the outline dictionary back to the file (appending)
	say FILE "$table[0][$objects] 0 obj";
	say FILE "<<";
	say FILE "/Type /Outlines";
	say FILE "/Count ", $PDFfile->{"Outlines"}{"/Count"} + 1, "" if ( defined( $PDFfile->{"Outlines"}{"/Count"} ) );
	say FILE "/First $PDFfile->{\"Outlines\"}{\"/First\"}" if ( defined( $PDFfile->{"Outlines"}{"/First"} ) );
	say FILE "/Last $table[2][$objects] 0 R";
	say FILE ">>";
	say FILE "endobj";

	print "Storing the last outline entry object num and file offset...\n";

	#store the last outline entry object num and file offset
	my @last_entry = split( /\s/, $PDFfile->{"Outlines"}{"/Last"} );
	$table[1][$objects] = $last_entry[0];
	$table[1][$offsets] = tell \*FILE;

	print "Appending the modified last outline entry...\n";

	#append modified last outline entry
	say FILE "$table[1][$objects] 0 obj";
	say FILE "<<";
	say FILE "/Title $last_data->{\"/Title\"}";
	say FILE "/Dest $last_data->{\"/Dest\"}" if ( defined $last_data->{"/Dest"} );
	say FILE "/Parent $last_data->{\"/Parent\"}";
	say FILE "/Prev $last_data->{\"/Prev\"}";
	say FILE "/Next $table[2][$objects] 0 R";
	say FILE "/First $last_data->{\"/First\"}" if ( defined $last_data->{"/First"} );
	say FILE "/Last $last_data->{\"/Last\"}" if ( defined $last_data->{"/Last"} );
	say FILE "/Count $last_data->{\"/Count\"}" if ( defined $last_data->{"/Count"} );
	say FILE "/A $last_data->{\"/A\"}" if ( defined $last_data->{"/A"} );
	say FILE "/SE $last_data->{\"/SE\"}" if ( defined $last_data->{"/SE"} );
	say FILE ">>";
	say FILE "endobj";

	print "Storing the object num and offset of the related document top level outline...\n";

	#store the object num and offset of the related document top level outline
	my $obj = $table[2][$objects] + 1;
	$table[2][$offsets] = tell \*FILE;
	
	print "Appending the related document top level outline...\n";
	
	#append related document top level outline
	say FILE "$table[2][$objects] 0 obj";
	say FILE "<<";
	say FILE "/Title (Related Documents)";
	say FILE "/Parent $last_data->{\"/Parent\"}";
	say FILE "/Count ", $url_num, "";
	say FILE "/First $obj 0 R";
	say FILE "/Last ", $table[2][$objects] + $url_num, " 0 ";
	say FILE ">>";
	say FILE "endobj";

	my $ind = 3;
	
	print "Appending the object nums and offsets of the new related document outlines...\n";

	#store the object nums and offsets of the new related document outlines and write 
	#them to the file (must be outline with an action eg go to specific url)	
	foreach my $row (@{$self->{URLS}}) {
		$table[$ind][$objects] = $obj;
		$table[$ind][$offsets] = tell \*FILE;
		say FILE "$obj 0 obj";
		say FILE "<<";
		say FILE "/Title (@$row[0])";
		say FILE "/Parent $table[2][$objects] 0 R";
		say FILE "/Next ", $obj + 1, " 0 R" if ( ( $obj + 1 ) <= ( $table[2][$objects] + $url_num ) );
		say FILE "/Prev ", $obj - 1, " 0 R" if ( ( $obj - 1 ) != ( $table[2][$objects] ) );
		say FILE "/A << /Type /Action";
		say FILE "/S /URI";
		say FILE "/URI (@$row[1])";
		say FILE ">>";
		#say FILE ">>";
		say FILE "endobj";
		$obj++;
		$ind++;
	}

	print "Appending the new X-reference table...\n";

	#append new X-reference table
	my $xref_offset = tell \*FILE;
	xref_table( \*FILE, $url_num, @table );
	
	print "Appending the new trailer\n";

	#print trailer
	trailer( \*FILE, $PDFfile, $obj );
	say FILE "$xref_offset";
	say FILE "%%EOF";

	close FILE;

	print "Completed modifying the outlines.\n";

}


#xref_table takes as parameters the filehandle to the pdf document, the number of related documents
#to this pdf doc and a table of object numbers and their offsets. Using this information it appends
# a new xreference table to the pdf document.

sub xref_table (*\$) {

	my ( $fd, $num, @table ) = @_;
	my $offset;

	#print the new xref table (append to file)
	say $fd "xref";
	say $fd "0 1 ";
	say $fd "0000000000 65535 f ";
	say $fd "$table[0][$objects] 1 ";
	$offset = '0' x ( 10 - length( $table[0][$offsets] ) ) . $table[0][$offsets];
	say $fd "$offset 00000 n ";
	say $fd "$table[1][$objects] 1 ";
	$offset = '0' x ( 10 - length( $table[1][$offsets] ) ) . $table[1][$offsets];
	say $fd "$offset 00000 n ";
	say $fd "$table[2][$objects] ", $num + 1, " ";

	for $i ( 2 .. ( $num + 2 ) ) {   #add 2 on because already written 2 to file
		$offset = '0' x ( 10 - length( $table[$i][$offsets] ) ) . $table[$i][$offsets];
		say $fd "$offset 00000 n ";
	}

}

#trailer function recieves the filehandle to the pdf document, parsed information about the
#document and the new size (last object number + 1) of the pdf file.  Using this information it appends
#a new trailer to the end of the pdf document.

sub trailer (*\$) {

	my ( $fd, $PDFfile, $new_size ) = @_;

	#append the new trailer to the end of the file
	say $fd "trailer";
	say $fd "<<";
	say $fd "/Size ", $new_size, "";
	say $fd "/Root $PDFfile->{\"Trailer\"}{\"/Root\"}";
	say $fd "/Info $PDFfile->{\"Trailer\"}{\"/Info\"}" if ( defined( $PDFfile->{"Trailer"}{"/Info"} ) );
	say $fd "/ID [$PDFfile->{\"Trailer\"}{\"/ID\"}[0]$PDFfile->{\"Trailer\"}{\"/ID\"}[1]]" if ( defined( $PDFfile->{"Trailer"}{"/ID"} ) );
	say $fd "/Prev $PDFfile->{\"Last_XRef_Offset\"}";
	say $fd "/Encrypt $PDFfile->{\"Trailer\"}{\"/Encrypt\"}" if ( defined( $PDFfile->{"Trailer"}{"/Encrypt"} ) );
	say $fd ">>";
	say $fd "startxref";

}
