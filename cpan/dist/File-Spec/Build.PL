use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'File::Spec',
   license => 'perl',
   installdirs => 'core',
   requires       => {
		      File::Basename => 0,
		      Cwd => 0,
		     },
   build_requires => {
		      Test::More => 0,
		      Test => 0,
		     },
  );

$build->create_build_script;
