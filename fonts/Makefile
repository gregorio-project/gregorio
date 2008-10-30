## This makefile is made to build to fonts from the sfd, it won't be useful for
## the average user.

## declaration of files:

gregorio_PFB= \
	gregorio-0.pfb \
	gregorio-1.pfb \
	gregorio-2.pfb \
	gregorio-3.pfb \
	gregorio-4.pfb \
	gregorio-5.pfb \
	gregorio-6.pfb \
	gregorio-7.pfb \
	gregorio-8.pfb

gregorio_TFM= $(gregorio_PFB:.pfb=.tfm)
gregorio_PL= $(gregorio_PFB:.pfb=.pl)

gregorio_OFM=gregorio.ofm
gregorio_OVF=gregorio.ovf
gregorio_OVP=gregorio.ovp

## 

parmesan_PFB= \
	parmesan-0.pfb \
	parmesan-1.pfb \
	parmesan-2.pfb \
	parmesan-3.pfb \
	parmesan-4.pfb \
	parmesan-5.pfb \
	parmesan-6.pfb \
	parmesan-7.pfb \
	parmesan-8.pfb

parmesan_TFM= $(parmesan_PFB:.pfb=.tfm)
parmesan_PL= $(parmesan_PFB:.pfb=.pl)

parmesan_OFM=parmesan.ofm
parmesan_OVF=parmesan.ovf
parmesan_OVP=parmesan.ovp

## 

greciliae_PFB= \
	greciliae-0.pfb \
	greciliae-1.pfb \
	greciliae-2.pfb \
	greciliae-3.pfb \
	greciliae-4.pfb \
	greciliae-5.pfb \
	greciliae-6.pfb \
	greciliae-7.pfb \
	greciliae-8.pfb

greciliae_TFM= $(greciliae_PFB:.pfb=.tfm)
greciliae_PL= $(greciliae_PFB:.pfb=.pl)

greciliae_OFM=greciliae.ofm
greciliae_OVF=greciliae.ovf
greciliae_OVP=greciliae.ovp

PFB=$(parmesan_PFB) $(gregorio_PFB) $(greciliae_PFB)

ENC=$(PFB:.pfb=.enc)
TFM=$(PFB:.pfb=.tfm)
AFM=$(PFB:.pfb=.afm)
PL=$(PFB:.pfb=.pl)

## common rules

%.pe: squarize.py
	python squarize.py $*

%.pl: %.tfm
	tftopl $< $@

%.ovp: create-ovp.perl $(PL)
	perl create-ovp.perl $*

%.ofm %.ovf: %.ovp
	ovp2ovf $< $*.ovf $*.ofm

## rules specific to a font

## gregorio rules
$(gregorio_PFB): gregorio.pe gregorio-base.sfd
	fontforge gregorio.pe

$(gregorio_TFM): $(gregorio_PFB)

## parmesan rules
$(parmesan_PFB): parmesan.pe parmesan-base.sfd
	fontforge parmesan.pe

$(parmesan_TFM): $(parmesan_PFB)

## greciliae rules
$(greciliae_PFB): greciliae.pe greciliae-base.sfd
	fontforge greciliae.pe

$(greciliae_TFM): $(greciliae_PFB)

## rules tu put all this in common

all_PFB= $(parmesan_PFB) $(gregorio_PFB) $(greciliae_PFB) gresym.pfb
all_TFM= $(parmesan_TFM) $(gregorio_TFM) $(greciliae_TFM) gresym.tfm
all_OVF= $(parmesan_OVF) $(gregorio_OVF) $(greciliae_OVF)
all_OVP= $(parmesan_OVP) $(gregorio_OVP) $(greciliae_OVP)
all_OFM= $(parmesan_OFM) $(gregorio_OFM) $(greciliae_OFM)

## build rules

FONTS=$(all_PFB) $(all_TFM) $(all_OVF) $(all_OFM) $(all_OVP)

## rules for the files to clean

CLEANFILES=$(ENC) $(AFM) $(PFB) $(TFM) $(all_OVF) $(all_OVP) $(all_OFM) *.pe

all: $(FONTS)

clean:
	rm $(CLEANFILES)

install:
	python install.py
	
.DEFAULT_GOAL := all
