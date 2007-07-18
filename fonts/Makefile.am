squarize.pe: squarize.py
	$(PYTHON) squarize.py

$(TFM) $(PFB): squarize.pe
	$(FONTFORGE) squarize.pe

$(PL): $(TFM)
	$(TFTOPL) gregorio-0.tfm gregorio-0.pl
	$(TFTOPL) gregorio-1.tfm gregorio-1.pl
	$(TFTOPL) gregorio-2.tfm gregorio-2.pl
	$(TFTOPL) gregorio-3.tfm gregorio-3.pl
	$(TFTOPL) gregorio-4.tfm gregorio-4.pl
	$(TFTOPL) gregorio-5.tfm gregorio-5.pl

$(OVP): create-ovp.perl $(PL)
	$(PERL) create-ovp.perl

$(OFM) $(OVF): gregorio.ovp
	$(OVP2OVF) gregorio.ovp gregorio.ovf gregorio.ofm

PFB= \
        gregorio-0.pfb \
        gregorio-1.pfb \
        gregorio-2.pfb \
        gregorio-3.pfb \
        gregorio-4.pfb \
        gregorio-5.pfb


TFM= \
	gregorio-0.tfm \
	gregorio-1.tfm \
	gregorio-2.tfm \
	gregorio-3.tfm \
	gregorio-4.tfm \
	gregorio-5.tfm

PL= \
	gregorio-0.pl \
	gregorio-1.pl \
	gregorio-2.pl \
	gregorio-3.pl \
	gregorio-4.pl \
	gregorio-5.pl

OVF=gregorio.ovf

OVP=gregorio.ovp

OFM=gregorio.ofm

FONTS=$(PFB) $(TFM) $(OVF) $(OFM)

noinst_DATA = $(FONTS)

EXTRA_DIST = squarize.py create-ovp.perl gregorio-base.sfd FONTLOG README

CLEANFILES=gregorio-0.enc gregorio-1.enc \
	gregorio-2.enc gregorio-3.enc gregorio-4.enc \
	gregorio-5.enc gregorio-0.afm gregorio-1.afm \
	gregorio-2.afm gregorio-3.afm gregorio-4.afm \
	gregorio-5.afm $(PL) $(FONTS) squarize.pe
