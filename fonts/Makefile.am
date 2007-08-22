font_name=gregorio

squarize-$(font_name).pe: squarize.py
	$(PYTHON) squarize.py $(font_name)

$(TFM) $(PFB): squarize-$(font_name).pe $(font_name)-base.sfd
	$(FONTFORGE) squarize-$(font_name).pe

%.pl: %.tfm
	$(TFTOPL) $< $@

%.ovp: create-ovp.perl $(PL)
	$(PERL) create-ovp.perl $*

$(OFM) $(OVF): gregorio.ovp
	$(OVP2OVF) gregorio.ovp gregorio.ovf gregorio.ofm

PFB= \
        $(font_name)-0.pfb \
        $(font_name)-1.pfb \
        $(font_name)-2.pfb \
        $(font_name)-3.pfb \
        $(font_name)-4.pfb \
        $(font_name)-5.pfb


TFM= $(PFB:.pfb=.tfm)

PL= $(PFB:.pfb=.pl)

OVF=$(font_name).ovf

OVP=$(font_name).ovp

OFM=$(font_name).ofm

FONTS=$(PFB) $(TFM) $(OVF) $(OFM)

noinst_DATA = $(FONTS)

EXTRA_DIST = squarize.py create-ovp.perl $(font_name)-base.sfd FONTLOG README

ENC=$(PFB:.pfb=.enc)
AFM=$(PFB:.pfb=.afm)

CLEANFILES=$(ENC) $(AFM) $(PL) $(FONTS) squarize-*.pe
