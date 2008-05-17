## common rules

%.pe: squarize.py
	$(PYTHON) squarize.py $*

%.pl: %.tfm
	$(TFTOPL) $< $@

%.ovp: create-ovp.perl $(PL)
	$(PERL) create-ovp.perl $*

%.ofm %.ovf: %.ovp
	$(OVP2OVF) $< $*.ovf $*.ofm

## rules specific to a font

## gregorio rules
$(gregorio_PFB): gregorio.pe gregorio-base.sfd
	$(FONTFORGE) gregorio.pe

$(gregorio_TFM): $(gregorio_PFB)

gregorio_PFB= \
	gregorio-0.pfb \
	gregorio-1.pfb \
	gregorio-2.pfb \
	gregorio-3.pfb

gregorio_TFM= $(gregorio_PFB:.pfb=.tfm)
gregorio_PL= $(gregorio_PFB:.pfb=.pl)

gregorio_OFM=gregorio.ofm
gregorio_OVF=gregorio.ovf
gregorio_OVP=gregorio.ovp

## parmesan rules
$(parmesan_PFB): parmesan.pe parmesan-base.sfd
	$(FONTFORGE) parmesan.pe

$(parmesan_TFM): $(parmesan_PFB)

parmesan_PFB= \
	parmesan-0.pfb \
	parmesan-1.pfb \
	parmesan-2.pfb \
	parmesan-3.pfb

parmesan_TFM= $(parmesan_PFB:.pfb=.tfm)
parmesan_PL= $(parmesan_PFB:.pfb=.pl)

parmesan_OFM=parmesan.ofm
parmesan_OVF=parmesan.ovf
parmesan_OVP=parmesan.ovp

## greciliae rules
$(greciliae_PFB): greciliae.pe greciliae-base.sfd
	$(FONTFORGE) greciliae.pe

$(greciliae_TFM): $(greciliae_PFB)

greciliae_PFB= \
	greciliae-0.pfb \
	greciliae-1.pfb \
	greciliae-2.pfb \
	greciliae-3.pfb

greciliae_TFM= $(greciliae_PFB:.pfb=.tfm)
greciliae_PL= $(greciliae_PFB:.pfb=.pl)

greciliae_OFM=greciliae.ofm
greciliae_OVF=greciliae.ovf
greciliae_OVP=greciliae.ovp

## rules tu put all this in common

all_PFB= $(parmesan_PFB) $(gregorio_PFB) $(greciliae_PFB) gresym.pfb
all_TFM= $(parmesan_TFM) $(gregorio_TFM) $(greciliae_TFM) gresym.tfm
all_OVF= $(parmesan_OVF) $(gregorio_OVF) $(greciliae_OVF)
all_OVP= $(parmesan_OVP) $(gregorio_OVP) $(greciliae_OVP)
all_OFM= $(parmesan_OFM) $(gregorio_OFM) $(greciliae_OFM)

## build rules

FONTS=$(all_PFB) $(all_TFM) $(all_OVF) $(all_OFM) $(all_OVP)

noinst_DATA = $(FONTS)

EXTRA_DIST = squarize.py create-ovp.perl parmesan-base.sfd greciliae-base.sfd gregorio-base.sfd FONTLOG README gresym.sfd

## rules for the files to clean

PFB=$(parmesan_PFB) $(gregorio_PFB) $(greciliae_PFB)

ENC=$(PFB:.pfb=.enc)
TFM=$(PFB:.pfb=.tfm)
AFM=$(PFB:.pfb=.afm)
PL=$(PFB:.pfb=.pl)

CLEANFILES=$(ENC) $(AFM) $(PL) $(PFB) $(TFM) $(all_OVF) $(all_OVP) $(all_OFM) *.pe

