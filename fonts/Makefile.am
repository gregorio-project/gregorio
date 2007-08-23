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
        gregorio-3.pfb \
        gregorio-4.pfb \
        gregorio-5.pfb

gregorio_TFM= $(gregorio_PFB:.pfb=.tfm)
gregorio_PL= $(gregorio_PFB:.pfb=.pl)

gregorio_OFM=gregorio.ofm
gregorio_OVF=gregorio.ovf

## parmesan rules
$(parmesan_PFB): parmesan.pe parmesan-base.sfd
	$(FONTFORGE) parmesan.pe

$(parmesan_TFM): $(parmesan_PFB)

parmesan_PFB= \
        parmesan-0.pfb \
        parmesan-1.pfb \
        parmesan-2.pfb \
        parmesan-3.pfb \
        parmesan-4.pfb \
        parmesan-5.pfb

parmesan_TFM= $(parmesan_PFB:.pfb=.tfm)
parmesan_PL= $(parmesan_PFB:.pfb=.pl)

parmesan_OFM=parmesan.ofm
parmesan_OVF=parmesan.ovf

## rules tu put all this in common

all_PFB= $(parmesan_PFB) $(gregorio_PFB)
all_TFM= $(parmesan_TFM) $(gregorio_TFM)
all_OVF= $(parmesan_OVF) $(gregorio_OVF)
all_OFM= $(parmesan_OFM) $(gregorio_OFM)

## build rules

FONTS=$(all_PFB) $(all_TFM) $(all_OVF) $(all_OFM)

noinst_DATA = $(FONTS)

EXTRA_DIST = squarize.py create-ovp.perl parmesan-base.sfd gregorio-base.sfd FONTLOG README

## rules for the files to clean

PFB=$(parmesan_PFB) $(gregorio_PFB)

ENC=$(PFB:.pfb=.enc)
AFM=$(PFB:.pfb=.afm)
PL=$(PFB:.pfb=.pl)

CLEANFILES=$(ENC) $(AFM) $(PL) $(FONTS) squarize-*.pe
