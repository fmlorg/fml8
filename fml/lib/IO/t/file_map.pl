use Carp;

$map = 'file:/etc/passwd';

    use IO::MapAdapter;
    $obj = new IO::MapAdapter $map;
    $obj->open || croak("cannot open $map");
    if ($obj->error) { croak( $obj->error );}
    while ($x = $obj->getline) { print $x; }
    $obj->close;
