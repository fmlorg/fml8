use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'File::MMagic',
   dist_version_from => 'MMagic.pm',
   license => 'open_source',
   requires => {'perl' => '5.005'},
   pm_files => {'MMagic.pm' => 'lib/File/MMagic.pm'},
  );
  
$build->create_build_script;
