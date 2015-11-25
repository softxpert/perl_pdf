#!/usr/bin/perl

use strict;
use warnings;

use PDF::API2;
use GD::Barcode::Code39;
use Encode;

my $pdf = PDF::API2->new();

my $sources_path = '/root/dev/barcodes/sources/';
my $gif_path     = '/root/dev/barcodes/barcodes/';
my $pdf_path     = '/root/dev/barcodes/pdf/';
my $input_file   = '/root/dev/barcodes/sources/DE_XP.txt';

for ($sources_path,$gif_path,$pdf_path) {
   unless(-d $_) {
      print "Directory: $_ not found!\n";
      exit;
   }
}


open FH, "$input_file" || die "Inputfile: $input_file could not be opened!";
my @lines = <FH>;
close FH;


for my $line(@lines) {
   chomp($line); 
   next unless($line);
   my @crew = split(';',$line);
   my $leg_name = $crew[0];
   shift(@crew);
   next if(scalar(@crew) == 1);

   my $leg = [];
   my @p = split(',', $leg_name);
   my $pdf_name = $p[0] . $p[1] . '.pdf';

   for my $member (@crew) {
   
      my @parts = split(',',$member);

      my $type      = $parts[0] || '';
      my $last_name = $parts[1] || '';
      my $sure_name = $parts[2] || '';
      my $pk_number = $parts[4] || '';
      $pk_number =~ s/\s//g;
      my $name = "$last_name, $sure_name";

      if (length($name) > 25) {
         $name = substr($name,0,25);
      }

      if ($type =~ /-/g) {
         my @t = split('-', $type);
         $type = $t[1];      
      }

      if ($type =~ /PU|ST|JU|ACM/) {
         push(@$leg,{PK => $pk_number, NAME => $name, TYPE => $type});
      }
      
   }

   if (scalar(@$leg)) { 
      print "START: New PDF barcode briefing document\n";
      CreateBarcodes($leg);
      CreatePDF($leg,$pdf_name);
      print "END: PDF barcode briefing\n";
   }

}


exit;


##################################################################
#
##################################################################
sub CreateBarcodes {
   my($leg) = shift;

   for(@$leg) {
      my $member = $_;
      my $pk = $member->{PK};
      CreateBarcode($pk);
   }

}


##################################################################
#
#################################################################
sub CreateBarcode {
   my($pk) = @_;

   unless($pk) {
      print "Error in CreateBarcode: No parameter value";
      return;
   }

   my $code39 = '*' . $pk . '*';
   my $gif_name = $gif_path . $pk . '.gif';

   binmode(STDOUT);

   my %height = (Height => 100);
   my $image = GD::Barcode::Code39->new($code39)->plot->gif;

   open(OUT, '>', $gif_name );
   print OUT $image;
   close OUT;

   print " - Barcode image: $pk.gif created\n";
}




###################################################################
#
##################################################################
sub CreatePDF {
   my($crew, $pdf_name) = @_;

   my $nr       = 0;
   my $x        = 100;
   my $y        = 680;
   my $y_offset = 0; 

   # Create a new page
   $pdf = PDF::API2->new();
   my $page = $pdf->page();
   $page->mediabox('A4'); 

   # Set the Page Header Text
   my $text = $page->text();
   my $font = $pdf->corefont('Arial');
   $text->font($font, 20);
   $text->translate(150,800);
   $text->text('EPO CABIN CREW BARCODE');


   my $gfx = $page->gfx;

   for(@$crew) {
      if ($nr == 10) {
         print "Max value of barcodes = 10";
         return;
      }

      $nr++;
      my $member  = $_;
      my $pk      = $member->{PK};
      my $name    = $member->{NAME};
      my $type    = $member->{TYPE};
      

      if ($nr % 2) {
         $x = 100;
         $y_offset = 0;
      }
      else {
         $x = 350;
         $y_offset = 150;
      }

      #Text
      my $text = "$type: $name";
      my $header = $page->text();
      $header->font($font, 12);
      $header->translate($x,$y+55);
      $header->text(decode("utf8", $text));

      #Barcode
      my $gif = $gif_path . $pk . '.gif';
      my $image = $pdf->image_gif($gif);
      $gfx->image($image, $x, $y);

      $y = $y - $y_offset;

   }

   my $pdf_out = $pdf_path . $pdf_name;
   
   $pdf->saveas($pdf_out);
   $pdf->end;

   print " - PDF barcode briefing: $pdf_name created\n";

}


1;

__END__


my $crew = [ 
             { PK => '089089A' => ,NAME => 'Thomas Koch'    , TYPE => 'PU'},
             { PK => '222333D' => ,NAME => 'Karla Kabine'    , TYPE => 'FB'},
             { PK => '077077A' => ,NAME => 'Valerie Verkäufer', TYPE => 'FB'},
             { PK => '999000F' => ,NAME => 'Christoph Comfort'     , TYPE => 'FB'},
             { PK => '555666E' => ,NAME => 'Birgit Box'     , TYPE => 'FB'},
             { PK => '888999I' => ,NAME => 'Kerstin Kaffee'  , TYPE => 'FB'},
             { PK => '444555F' => ,NAME => 'Lars Läufer', TYPE => 'JU'},
             { PK => '333444K' => ,NAME => 'Gundula Galley', TYPE => 'JU'},

           ];
