use ExtUtils::MakeMaker;

require 5.005;

WriteMakefile
  ( NAME		=> 'MIME::Types'
  , VERSION_FROM	=> 'MIME/Types.pm'
  , DIR                 => [ 'MIME' ]
  , PREREQ_PM		=> {}
  , AUTHOR              => 'Mark Overmeer'
  , ABSTRACT            => 'Definition of MIME types'
  );
