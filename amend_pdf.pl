#!/usr/bin/perl

#This perl script takes a PDF file and modifies it to include user specified
#outline entries (also known as bookmarks).
#This script was originally developed to be used with the Greenstone digital library.

use Carp;
use Getopt::Long;
use PDF;
use Text::CSV;

use Cwd 'abs_path';
use File::Basename;
use lib dirname( abs_path $0 );

use outlines;

if ( defined $ARGV[0] ) {
	$pdf_document = $ARGV[0];
}
else {
	print STDERR "You must supply pdf document filename\n";
	exit(1);
}

if ( defined $ARGV[1] ) {
	$related_docs = $ARGV[1];
}
else {
	print STDERR "You must supply related document filename\n";
	exit(1);
}

create_outlines($pdf_document);

exit(1);

#create outline checks validity of pdf file and if the file is encrypted. 
#Then a check is performed to see if the outlines dictionary exists in the document catalog.
#If the outline entry exists but there are no actual outlines  present then call add_outlines 
#but pass on the existing  outline dictionary. Otherwise call modify_outlines to modify the existing outline
#structure to include new outlines. If outlines dictionary doesn't exist call add_outlines.
sub create_outlines {

	my $filename = shift;

	#parse pdf filename
	my @filelist = split( "/", $filename );
	my $old_file = pop @filelist;
	my $file     = "tmp_$old_file";
	my $outlines = outlines->new();

	print "pdf file to be manipulated: $file\n";
	print "pdf file to be saved: old_$file\n";

	#make a copy of that file in this directory
	print "cp $old_file $file\n";
	`cp $old_file $file\n`;

	#create and parse a new 'pdf' object
	my $PDFfile = PDF->new($file);

	#read url file
	my $urls = read_file();
	$outlines->urls($urls);

	#if it is a pdf file
	if ( $PDFfile->{"Header"} ) {

		if ( $PDFfile->IscryptPDF ) {

			#an encrypted file so cannot continue with
			#adding the related doc outlines to it
			print STDERR "File \"$file\" is encrypted\n";
			return;
		}

		#display some relevant information about the document
		print "Author: ",  $PDFfile->GetInfo("Author"),  "\n";
		print "Title: ",   $PDFfile->GetInfo("Title"),   "\n";
		print "Subject: ", $PDFfile->GetInfo("Subject"), "\n";
		print "Updated: ", $PDFfile->{"Updated"}, "\n";

		#if the pdf document already includes an outline dictionary
		if ( defined $PDFfile->{"Catalog"}{"/Outlines"} ) {

			#get the outline object from the indirect ref
			my $outline_data =
			  $PDFfile->GetObject( $PDFfile->{"Catalog"}{"/Outlines"} );

			#obtain the number of existing outlines
			$PDFfile->{"Outlines"}{"/Count"} = $outline_data->{"/Count"};
			print "number of existing outlines: $PDFfile->{\"Outlines\"}{\"/Count\"}\n";

			#this means that the pdf file had an outline dictionary but
			#did not actually include any outlines.
			if ( $PDFfile->{"Outlines"}{"/Count"} == 0 ) {
				print "Calling add an outline...\n";

				#obtain object number of outline dictionary and pass to add_outlines
				my $dictionary =
				  split( /\s/, $PDFfile->{"Catalog"}{"/Outlines"} );

				$outlines->pdffile($PDFfile);
				$outlines->file($file);
				$outlines->dictionary($dictionary);
				$outlines->add_outlines;
			}
			else {
				print "Collecting the other outline data and calling modify outlines...\n";

				#collect other outline data to pass to modify_outlines
				$PDFfile->{"Outlines"}{"/First"} = $outline_data->{"/First"};
				$PDFfile->{"Outlines"}{"/Last"}  = $outline_data->{"/Last"};

				$outlines->pdffile($PDFfile);
				$outlines->file($file);
				$outlines->dictionary($outline_data);

				#modify last outline entry
				$outlines->modify_outlines;
			}
		}
		else {    #there was no outline dictionary thus no outlines so add some
			print "No bookmarks in \"$file\" so calling add outlines\n";
			$outlines->pdffile($PDFfile);
			$outlines->file($file);
			$outlines->dictionary(0);
			$outlines->add_outlines;
		}
	}
	else {        #the file was not a pdf file
		print STDERR "$file is not a pdf file!!\n";
	}

}

#read_file reads in a csv file containing two columns of data with a title and url
sub read_file {

	# create two-dimensional array for urls
	my @urls;
	my $csv = Text::CSV->new( { binary => 1 } )   # should set binary attribute.
	  or die "Cannot use CSV: " . Text::CSV->error_diag();

	open my $fh, "<:encoding(utf8)", "$related_docs" or die "test.csv: $!";

	while ( my $row = $csv->getline($fh) ) {
		push @urls, $row;
	}

	close $fh;

	return \@urls;
}

