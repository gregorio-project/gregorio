squarize.pe: squarize.py
	$(PYTHON) squarize.py

gregorio-0.tfm: squarize.pe
	$(FONTFORGE) squarize.pe

gregorio-0.pl: gregorio-0.tfm
	$(TFTOPL) gregorio-0.tfm gregorio-0.pl
	$(TFTOPL) gregorio-1.tfm gregorio-1.pl
	$(TFTOPL) gregorio-2.tfm gregorio-2.pl
	$(TFTOPL) gregorio-3.tfm gregorio-3.pl
	$(TFTOPL) gregorio-4.tfm gregorio-4.pl
	$(TFTOPL) gregorio-5.tfm gregorio-5.pl

gregorio.ovp: create_font.pl gregorio-0.pl
	$(PERL) create_font.pl

gregorio.ofm: gregorio.ovp
	$(OVP2OVF) gregorio.ovp gregorio.ovf gregorio.ofm

EXTRA_DIST=gregorio.ofm

CLEANFILES=gregorio-0.enc gregorio-1.enc \
	gregorio-2.enc gregorio-3.enc gregorio-4.enc \
	gregorio-5.enc gregorio-0.afm gregorio-1.afm \
	gregorio-2.afm gregorio-3.afm gregorio-4.afm \
	gregorio-5.afm gregorio-0.pl gregorio-1.pl \
	gregorio-2.pl gregorio-3.pl gregorio-4.pl \
	gregorio-5.pl gregorio.ovp
