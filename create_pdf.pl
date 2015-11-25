#!/usr/bin/perl

use strict;
use warnings;

use PDF::API2;
use Encode;

my $pdf = PDF::API2->new();

CreatePDF('My text','my.pdf');
exit;


sub CreatePDF {
   my($txt, $pdf_name) = @_;

   $pdf = PDF::API2->new();
   my $page = $pdf->page();
   $page->mediabox('A4'); 

   my $text = $page->text();
   my $font = $pdf->corefont('Arial');
   $text->font($font, 20);
   $text->translate(150,750);
   $text->text('PDF FILE MADE BY Perl');

   my $gfx = $page->gfx;

   my $header = $page->text();
   $header->font($font, 12);
   $header->translate(200,500);
   $header->text(decode("utf8", $txt));

   my $gif = '123456.gif';
   my $image = $pdf->image_gif($gif);
   $gfx->image($image, 200, 600);

   
   $pdf->saveas($pdf_name);
   $pdf->end;

}

1;

