PRO RUN_PIXCMD, xx=xx

  ;run models with a complex SFH (part a)
  IF xx EQ 1 THEN BEGIN
     FOR m=0,2 DO BEGIN
        print,m
        pixcmd,mbin=10^float(1+m/4.),ssp=10.
        pixcmd,mbin=10^float(1+m/4.),sfh=1. 
        pixcmd,mbin=10^float(1+m/4.),sfh=2. 
        pixcmd,mbin=10^float(1+m/4.),sfh=5. 
        pixcmd,mbin=10^float(1+m/4.),sfh=10.
     ENDFOR
  ENDIF
 
  ;run models with a complex SFH (part b)
  IF xx EQ 2 THEN BEGIN
     FOR m=3,5 DO BEGIN
        print,m
        pixcmd,mbin=10^float(1+m/4.),ssp=10.
        pixcmd,mbin=10^float(1+m/4.),sfh=1. 
        pixcmd,mbin=10^float(1+m/4.),sfh=2. 
        pixcmd,mbin=10^float(1+m/4.),sfh=5. 
        pixcmd,mbin=10^float(1+m/4.),sfh=10.
     ENDFOR
  ENDIF
 
  ;run models with a complex SFH (part c)
  IF xx EQ 3 THEN BEGIN
     FOR m=1,4 DO BEGIN
        pixcmd,mbin=10^float(m),ssp=10.
        pixcmd,mbin=10^float(m),sfh=1. 
        pixcmd,mbin=10^float(m),sfh=2. 
        pixcmd,mbin=10^float(m),sfh=5. 
        pixcmd,mbin=10^float(m),sfh=10.
     ENDFOR
  ENDIF


  ;create large images to be used for illustration purposes
  IF xx EQ 4 THEN BEGIN
     FOR m=0,7 DO BEGIN
        print,m-1
        pixcmd,mbin=10^float(m-1),ssp=10.,nbin=1024,$
               /nosample,/more_eep
     ENDFOR
  ENDIF

  ;grid of metallicity and mass
  IF xx EQ 5 THEN BEGIN
     FOR i=2,7 DO BEGIN
        FOR m=0,5 DO BEGIN
           print,m,i
           pixcmd,mbin=10^float(m),ssp=10.,zh=i
        ENDFOR
     ENDFOR
  ENDIF

 
  ;run tailored model for comparison to data
  IF xx EQ 6 THEN BEGIN
     pixcmd,mbin=10^1.3,ssp=10.0
     pixcmd,mbin=10^1.5,ssp=10.0
  ENDIF


END
