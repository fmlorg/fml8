all: html

html: _subdir index.ja.html

index.ja.html: [A-Z]*
	../../doc/bin/dir2url.pl > index.ja.html

_subdir: [A-Z]*
	(cd Language; make html)
	(cd FML; make html)
	(cd File; make html)
	(cd IO; make html)
	(cd Mail; make html)
	(cd Tie; make html)
	(cd SQL; make html)
	(cd ErrorMessages; make html)

_clean:
	rm -f index.ja.html */index.ja.html

clean:
	(cd ../..;make clean)

regen: 	Mail/Delivery/ErrorStatus.pm Mail/Bounce/ErrorStatus.pm \
	Mail/Message/ErrorStatus.pm IO/Adapter/ErrorStatus.pm

Mail/Bounce/ErrorStatus.pm: ErrorStatus.pm
	sed 's/ErrorStatus/Mail::Bounce::ErrorStatus/g' ErrorStatus.pm \
		> Mail/Bounce/ErrorStatus.pm

Mail/Delivery/ErrorStatus.pm: ErrorStatus.pm
	sed 's/ErrorStatus/Mail::Delivery::ErrorStatus/g' ErrorStatus.pm \
		> Mail/Delivery/ErrorStatus.pm

Mail/Message/ErrorStatus.pm: ErrorStatus.pm
	sed 's/ErrorStatus/Mail::Message::ErrorStatus/g' ErrorStatus.pm \
		> Mail/Message/ErrorStatus.pm

IO/Adapter/ErrorStatus.pm: ErrorStatus.pm
	sed 's/ErrorStatus/IO::Adapter::ErrorStatus/g' ErrorStatus.pm \
		> IO/Adapter/ErrorStatus.pm
