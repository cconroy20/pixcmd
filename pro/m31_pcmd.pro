PRO M31_PCMD, ir=ir, brick=brick, bias=bias
  
  IF NOT(keyword_set(brick)) THEN brick = '01'
  IF NOT(keyword_set(bias))  THEN bias=0.0
 
  IF keyword_set(ir) THEN BEGIN
     magsol = 4.65 ;M_H_sol
     i1     = 'f110w'
     i2     = 'f160w'
     ytit   = 'H'
     xtit   = 'J-H'
     yr     = [6,-6]
     xr     = [-0.5,1.0]
     zpt    = [26.8223,25.9463]
     exptime = [699.+799.,1596.+1696.]
     str    = '_ir'
  ENDIF ELSE BEGIN
     magsol = 4.52  ;M_I_sol
     i1     = 'f475w'
     i2     = 'f814w'
     ytit   = 'I'
     xtit   = 'B-I'
     yr     = [4,-6]
     xr     = [0,4]
     zpt    = [26.0593,25.9433]
     exptime = [1720.+1900.,1520.+1715.]
     str    = '_opt'
  ENDELSE

  dm  = 24.47 ; McConnachie et al. 2005

  pdir = '~/pixcmd/plots/'

  ;read in model isochrone
  a   = mrdfits('~/pixcmd/isoc/MIST_v29_Zp0.00.fits',1,/sil)
  t1  = a[where(a.logage EQ 10.0,cta)]
  t97 = a[where(a.logage EQ 9.7,cta)]

  ;read in PHAT mosaics
  dir  = '~/DATA/HST/PHAT/'
  im1  = mrdfits(dir+'hlsp_*-m31-b'+brick+'_'+i1+'_v1_drz.fits',1,h1,/sil)
  tim2 = mrdfits(dir+'hlsp_*-m31-b'+brick+'_'+i2+'_v1_drz.fits',1,h2,/sil)
  ;astrometrically align the two images
  hastrom,tim2,h2,im2,newhdr,h1,interp=2,cubic=-0.5,/silent

  ;save S/N and convert ct/s to abs mag
  sn1 = sqrt(im1*exptime[0])
  sn2 = sqrt(im2*exptime[1])
  im1 = -2.5*alog10(im1+bias) + zpt[0] - dm
  im2 = -2.5*alog10(im2+bias) + zpt[1] - dm

  ;luminosity per pixel (I or H)
  lpix = alog10( 10^(2./5*(magsol-im2)) )

  a=read_fsps('SSP/SSP_Padova_BaSeL_Salpeter_Z0.0190.out.mags')
  IF keyword_set(ir) THEN BEGIN
     ;H-band
     m2l = 10^a[92].logmass / 10^(2./5*(magsol-a[92].wfc3_f160w))
  ENDIF ELSE BEGIN
     ;I-band
     m2l = 10^a[92].logmass / 10^(2./5*(magsol-a[92].acs_f814w))
  ENDELSE

  ;mass per pixel
  mpix = alog10( m2l * 10^(2./5*(magsol-im2)) )

  ;approx central coordinate for brick1
  IF keyword_set(ir) THEN BEGIN
     xc = 10545.
     yc = 7680.
  ENDIF ELSE BEGIN
     xc = 10150.
     yc = 6370.
  ENDELSE
  nx = n_elements(im1[*,0])
  ny = n_elements(im1[0,*])
  xx = fltarr(nx,ny)
  yy = fltarr(nx,ny)
  FOR i=0,ny-1 DO xx[*,i] = findgen(nx)
  FOR i=0,nx-1 DO yy[i,*] = findgen(ny)
  ;distance from center in pixels
  rr = sqrt( (xx-xc)^2 + (yy-yc)^2 )
  wh = where(finite(mpix) EQ 0)
  rr[wh] = 0.0

  dir  = '~/pixcmd/results/'
  sage = '10.0'
  m1   = mrdfits(dir+'pixcmd_t'+sage+'_Zp0.00_Mbin1.60.fits',2,/sil)
  nn   = n_elements(m2)

  IF keyword_set(ir) THEN BEGIN
     wht1 = where(tag_names(t1) EQ 'WFC3_F110W')
     wht2 = where(tag_names(t1) EQ 'WFC3_F160W')
     whm1 = where(tag_names(m3) EQ 'J')
     whm2 = where(tag_names(m3) EQ 'H')
  ENDIF ELSE BEGIN
     wht1 = where(tag_names(t1) EQ 'ACS_F475W')
     wht2 = where(tag_names(t1) EQ 'ACS_F814W')
     whm1 = where(tag_names(m1) EQ 'B')
     whm2 = where(tag_names(m1) EQ 'I')
  ENDELSE


  ;--------------------------------------------------------------;
  ;-------------------------brick 01-----------------------------;
  ;--------------------------------------------------------------;

  IF brick EQ '01' THEN BEGIN

     m2   = mrdfits(dir+'pixcmd_t'+sage+'_Zp0.00_Mbin2.00.fits',2,/sil)
     m3   = mrdfits(dir+'pixcmd_t'+sage+'_Zp0.00_Mbin3.00.fits',2,/sil)
     m4   = mrdfits(dir+'pixcmd_t'+sage+'_Zp0.00_Mbin4.00.fits',2,/sil)
     m1 = add_phot_err(m1,whm1,whm2,dm,zpt,exptime)
     m2 = add_phot_err(m2,whm1,whm2,dm,zpt,exptime)
     m3 = add_phot_err(m3,whm1,whm2,dm,zpt,exptime)
     m4 = add_phot_err(m4,whm1,whm2,dm,zpt,exptime)

     tm2  = mrdfits(dir+'pixcmd_t'+sage+'_Zp0.00_Mbin2.00.fits',2,/sil)
     m2zp = mrdfits(dir+'pixcmd_t'+sage+'_Zp0.30_Mbin2.00.fits',2,/sil)
     m2zm = mrdfits(dir+'pixcmd_t'+sage+'_Zm0.52_Mbin2.00.fits',2,/sil)
     mzz  = [tm2,m2zp,m2zp,m2zm]
     ct   = n_elements(mzz)
     mzz  = mzz[(sort(randomu(seed,ct)))[0:nn-1]]
     mzz  = add_phot_err(mzz,whm1,whm2,dm,zpt,exptime)
 
     begplot,name=pdir+'pixcmd_m31_bulge'+str+'.eps',/col,xsize=10,$
             ysize=6,/quiet,/encap
     
       !p.multi=[0,3,2]
       !p.charsize=1.8
     
       wh = where(rr GE 1000 AND rr LE 1300,ct)
       IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]
       plot,im1[wh]-im2[wh],im2[wh],ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       ss = strmid(strtrim(round(median(mpix[wh])*10)/10.,2),0,3)
       legend,['log M!Dpix!N='+ss],box=0,/right,charsize=0.9
       legend,['M31 Bulge'],box=0,/bottom,/right,charsize=0.9

       wh = where(rr GE 6200 AND rr LE 6250 AND finite(im1) EQ 1 $
                  AND xx LE xc,ct)
       IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]
       plot,im1[wh]-im2[wh],im2[wh],ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       ss = strmid(strtrim(round(median(mpix[wh])*10)/10.,2),0,3)
       legend,['log M!Dpix!N='+ss],box=0,/right,charsize=0.9
       legend,['M31 Bulge'],box=0,/bottom,/right,charsize=0.9
       
       wh = where(rr GE max(rr)-200,ct)
       IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]
       plot,im1[wh]-im2[wh],im2[wh],ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       ss = strmid(strtrim(round(median(mpix[wh])*10)/10.,2),0,3)
       legend,['log M!Dpix!N='+ss],box=0,/right,charsize=0.9
       legend,['M31 Bulge'],box=0,/bottom,/right,charsize=0.9

       plot,m3.(whm1)-m3.(whm2),m3.(whm2),ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,['log M!Dpix!N=3.0'],box=0,/right,charsize=0.9
       legend,['model'],box=0,/bottom,/right,charsize=0.9

       plot,m2.(whm1)-m2.(whm2),m2.(whm2),ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,['log M!Dpix!N=2.0'],box=0,/right,charsize=0.9
       legend,['model'],box=0,/bottom,/right,charsize=0.9
       
       plot,m1.(whm1)-m1.(whm2),m1.(whm2),ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,['log M!Dpix!N=1.6'],box=0,/right,charsize=0.9
       legend,['model'],box=0,/bottom,/right,charsize=0.9

    endplot,/quiet

    begplot,name=pdir+'pixcmd_m31_bulge'+str+'_zmix.eps',/col,xsize=9,$
             ysize=3,/quiet,/encap
     
       !p.multi=[0,3,1]
       !p.charsize=1.8
 
       wh = where(rr GE 6200 AND rr LE 6250 AND finite(im1) EQ 1 $
                AND xx LE xc,ct)
       IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]
       plot,im1[wh]-im2[wh],im2[wh],ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2,pos=[0.07,0.15,0.32,0.9]
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       ss = strmid(strtrim(round(median(mpix[wh])*10)/10.,2),0,4)
       legend,['M31 Bulge'],box=0,/right,charsize=0.9
 
       plot,m2.(whm1)-m2.(whm2),m2.(whm2),ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2,pos=[0.4,0.15,0.65,0.9]
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,['10 Gyr'],box=0,/left,charsize=0.9
       legend,['[Z/H]=0.0'],box=0,/right,charsize=0.9
 
       plot,mzz.(whm1)-mzz.(whm2),mzz.(whm2),ps=8,yr=yr,xr=xr,ys=1,xs=1,$
            xtit=xtit,ytit=ytit,symsize=0.2,pos=[0.73,0.15,0.98,0.9]
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,['10 Gyr'],box=0,/left,charsize=0.9
       legend,['-0.5<[Z/H]<0.5'],box=0,/right,charsize=0.9
 
     endplot,/quiet
 
     wh = where(rr GE 6200 AND rr LE 6250 AND finite(im1) EQ 1 $
                AND xx LE xc AND im2 GT -2*(im1-im2)+1.7,ct)

     dd = hist_2d(im1[wh]-im2[wh],im2[wh],bin1=0.05,bin2=0.05,$
                min1=-1.5,max1=4.5,min2=-6,max2=5)
     dd = reverse(dd,2)

     mm = hist_2d(mzz.(whm1)-mzz.(whm2),mzz.(whm2),bin1=0.05,bin2=0.05,$
                  min1=-1.5,max1=4.5,min2=-6,max2=5)
     mm = reverse(mm,2)

     m2h = hist_2d(m2.(whm1)-m2.(whm2),m2.(whm2),bin1=0.05,bin2=0.05,$
                  min1=-1.5,max1=4.5,min2=-6,max2=5)
     m2h = reverse(m2h,2)

     b = read_binary('../hess/hess_M2.00_Zp0.00.dat',$
                     data_dims=[22,121,221],data_type=4)
     bb = reverse(reform(b[20,*,*]),2)

     r = read_binary('../results/hess_best.dat',$
                     data_dims=[121,221],data_type=4)
     r = reverse(r,2)

     b = read_binary('../data/model_tau2.0_mpix3.1_mdf0.0_0.05.hess',$
                     data_dims=[121,221],data_type=4)
     bb = reverse(b,2)

     d=read_binary('../data/m31_bulge.hess',data_dims=[121,221],data_type=4)
     d = reverse(d,2)

     m15 = reverse(read_binary('../data/model_M2.0_t15_Z4.hess',$
                               data_dims=[121,221],data_type=4),2)
     m13 = reverse(read_binary('../data/model_M2.0_t13_Z4.hess',$
                               data_dims=[121,221],data_type=4),2)
     m10 = reverse(read_binary('../data/model_M2.0_t10_Z4.hess',$
                               data_dims=[121,221],data_type=4),2)
     m5 = reverse(read_binary('../data/model_M2.0_t05_Z4.hess',$
                              data_dims=[121,221],data_type=4),2)

     !p.multi=0
     stop

  ENDIF

  ;--------------------------------------------------------------;
  ;--------------------------brick 02----------------------------;
  ;--------------------------------------------------------------;

  IF brick EQ '02' THEN BEGIN

     wh   = where(xx GE 14000 AND xx LE 15000 AND $
                  yy GE 13000 AND yy LE 14000 AND finite(mpix) EQ 1,ct)

     cs   = mrdfits(dir+'pixcmd_tau10.0_Zp0.00_Mbin2.00.fits',2,/sil)
     t01  = mrdfits(dir+'pixcmd_tau1.00_Zp0.00_Mbin1.75.fits',2,/sil)
     t2   = mrdfits(dir+'pixcmd_tau2.00_Zp0.00_Mbin1.75.fits',2,/sil)
     t5   = mrdfits(dir+'pixcmd_tau5.00_Zp0.00_Mbin2.00.fits',2,/sil)
     cs   = add_phot_err(cs,whm1,whm2,dm,zpt,exptime)
     t1   = add_phot_err(t1,whm1,whm2,dm,zpt,exptime)
     t2   = add_phot_err(t2,whm1,whm2,dm,zpt,exptime)
     t5   = add_phot_err(t5,whm1,whm2,dm,zpt,exptime)
     nn   = n_elements(cs)
     IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]

    begplot,name=pdir+'brick2.eps',/col,xsize=7,ysize=6,/quiet,/encap
       !p.multi=[0,2,2]
       !p.charsize=1.0
       plot,im1[wh]-im2[wh],im2[wh],ps=8,xr=[-1,4],yr=[6,-4],$
            xtit='B-I',ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2       
       legend,['M31 B2'],box=0,charsize=0.9,/right
       plot,cs.b-cs.i,cs.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('SSP')],box=0,charsize=0.9,/right
       plot,t01.b-t01.i,t01.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=1 Gyr')],box=0,charsize=0.9,/right
       plot,t2.b-t2.i,t2.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=2 Gyr')],box=0,charsize=0.9,/right
     endplot,/quiet
     spawn,'convert -density 500 '+pdir+'brick2.eps '+pdir+'brick2.png'

     !p.multi=0
     stop



  ENDIF

  ;--------------------------------------------------------------;
  ;--------------------------brick 05----------------------------;
  ;--------------------------------------------------------------;

  IF brick EQ '05' THEN BEGIN

     wh   = where(xx GE 11500 AND xx LE 12000 AND $
                  yy GE 9500 AND yy LE 10000 AND finite(mpix) EQ 1,ct)

     m2   = mrdfits(dir+'pixcmd_t10.0_Zp0.00_Mbin2.00.fits',2,/sil)
     cs   = mrdfits(dir+'pixcmd_tau10.0_Zp0.00_Mbin2.00.fits',2,/sil)
     t22  = mrdfits(dir+'pixcmd_tau1.00_Zp0.00_Mbin1.75.fits',2,/sil)
     t2   = mrdfits(dir+'pixcmd_tau2.00_Zp0.00_Mbin2.00.fits',2,/sil)
     m2   = add_phot_err(m2,whm1,whm2,dm,zpt,exptime)
     cs   = add_phot_err(cs,whm1,whm2,dm,zpt,exptime)
     t22   = add_phot_err(t22,whm1,whm2,dm,zpt,exptime)
     t2   = add_phot_err(t2,whm1,whm2,dm,zpt,exptime)
     nn   = n_elements(m1)
     IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]

     begplot,name=pdir+'brick5.eps',/col,xsize=7,ysize=6,/quiet,/encap
       !p.multi=[0,2,2]
       !p.charsize=1.0
       plot,im1[wh]-im2[wh],im2[wh],ps=8,xr=[-1,4],yr=[6,-4],$
            xtit='B-I',ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2       
       legend,['M31 B5'],box=0,charsize=0.9,/right
       plot,m2.b-m2.i,m2.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('SSP')],box=0,charsize=0.9,/right
       plot,t22.b-t22.i,t22.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=2 Gyr')],box=0,charsize=0.9,/right
       plot,t2.b-t2.i,t2.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=2 Gyr')],box=0,charsize=0.9,/right
     endplot,/quiet
     spawn,'convert -density 500 '+pdir+'brick5.eps '+pdir+'brick5.png'

     !p.multi=0
     stop

  ENDIF

  ;--------------------------------------------------------------;
  ;--------------------------brick 06----------------------------;
  ;--------------------------------------------------------------;

  IF brick EQ '06' THEN BEGIN


     wh   = where(xx GE 13500 AND xx LE 14500 AND $
                  yy GE 11000 AND yy LE 12000 AND finite(mpix) EQ 1,ct)
     ;wh   = where(xx GE 15000 AND xx LE 16000 AND $
     ;             yy GE 11000 AND yy LE 12000 AND finite(mpix) EQ 1,ct)

     m2   = mrdfits(dir+'pixcmd_t10.0_Zp0.00_Mbin1.60.fits',2,/sil)
     cs   = mrdfits(dir+'pixcmd_tau10.0_Zp0.00_Mbin1.50.fits',2,/sil)
     t2   = mrdfits(dir+'pixcmd_tau2.00_Zp0.00_Mbin1.60.fits',2,/sil)
     m2   = add_phot_err(m2,whm1,whm2,dm,zpt,exptime)
     cs   = add_phot_err(cs,whm1,whm2,dm,zpt,exptime)
     t2   = add_phot_err(t2,whm1,whm2,dm,zpt,exptime)
     nn   = n_elements(m1)
     IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]

     begplot,name=pdir+'brick6.eps',/col,xsize=7,ysize=6,/quiet,/encap
       !p.multi=[0,2,2]
       !p.charsize=1.0
       plot,im1[wh]-im2[wh],im2[wh],ps=8,xr=[-1,4],yr=[6,-4],$
            xtit='B-I',ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2       
       legend,['M31 B5'],box=0,charsize=0.9,/right
       plot,m2.b-m2.i,m2.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('SSP')],box=0,charsize=0.9,/right
       plot,cs.b-cs.i,cs.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=2 Gyr')],box=0,charsize=0.9,/right
       plot,t2.b-t2.i,t2.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=2 Gyr')],box=0,charsize=0.9,/right
     endplot,/quiet
     spawn,'convert -density 500 '+pdir+'brick6.eps '+pdir+'brick6.png'

     !p.multi=0
     stop

  ENDIF

  ;--------------------------------------------------------------;
  ;-------------------------brick 17-----------------------------;
  ;--------------------------------------------------------------;

  IF brick EQ '17' THEN BEGIN

     ;wh   = where(xx GE 7000 AND xx LE 7500 AND $
     ;             yy GE 4500 AND yy LE 4700 AND finite(mpix) EQ 1,ct)
     ;wh   = where(xx GE 4000 AND xx LE 4200 AND $
     ;             yy GE 12000 AND yy LE 12200 AND finite(mpix) EQ 1,ct)
     wh   = where(xx GE 5000 AND xx LE 5400 AND $
                  yy GE 12500 AND yy LE 12800 AND finite(mpix) EQ 1,ct)

     m1   = mrdfits(dir+'pixcmd_t10.0_Zp0.00_Mbin1.30.fits',2,/sil)
     ;cs   = mrdfits(dir+'pixcmd_tau10.0_Zp0.00_Mbin1.30.fits',2,/sil)
     cs   = mrdfits(dir+'pixcmd_tau3.00_Zp0.00_Mbin1.50.fits',2,/sil)
     t5   = mrdfits(dir+'pixcmd_tau5.00_Zp0.00_Mbin1.30.fits',2,/sil)
     t2   = mrdfits(dir+'pixcmd_tau2.00_Zp0.00_Mbin1.30.fits',2,/sil)
     m1   = add_phot_err(m1,whm1,whm2,dm,zpt,exptime)
     cs   = add_phot_err(cs,whm1,whm2,dm,zpt,exptime)
     t5   = add_phot_err(t5,whm1,whm2,dm,zpt,exptime)
     t2   = add_phot_err(t2,whm1,whm2,dm,zpt,exptime)
     nn   = n_elements(m1)
     IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]

     begplot,name=pdir+'brick17.eps',/col,xsize=7,ysize=6,/quiet,/encap
       !p.multi=[0,2,2]
       !p.charsize=1.0
       plot,im1[wh]-im2[wh],im2[wh],ps=8,xr=[-1,4],yr=[6,-4],$
            xtit='B-I',ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2       
       legend,['M31 B17'],box=0,charsize=0.9,/right
       plot,cs.b-cs.i,cs.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('SFH=constant')],box=0,charsize=0.9,/right
       plot,t5.b-t5.i,t5.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=5 Gyr')],box=0,charsize=0.9,/right
       plot,t2.b-t2.i,t2.i,ps=8,xr=[-1,4],yr=[6,-4],xtit='B-I',$
            ytit='I',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red,thick=2
       legend,[textoidl('\tau_{SF}=2 Gyr')],box=0,charsize=0.9,/right
     endplot,/quiet
     spawn,'convert -density 500 '+pdir+'brick17.eps '+pdir+'brick17.png'

     !p.multi=0
     stop

  ENDIF


  ;--------------------------------------------------------------;
  ;-------------------------brick 22-----------------------------;
  ;--------------------------------------------------------------;

  IF brick EQ '22' THEN BEGIN

     dir  = '~/pixcmd/results/'
     m10  = mrdfits(dir+'pixcmd_t10.0_Zp0.00_Mbin1.00.fits',2,/sil)
     m10  = add_phot_err(m10,whm1,whm2,dm,zpt,exptime)
     m05  = mrdfits(dir+'pixcmd_t10.0_Zp0.00_Mbin0.50.fits',2,/sil)
     m05  = add_phot_err(m05,whm1,whm2,dm,zpt,exptime)

     file = pdir+'brick22'+str+'.eps'
     begplot,name=file,/col,xsize=8,ysize=7,/quiet,/encap

       !p.multi=[0,2,2]
       !p.charsize=1.2

       ; wh = where(xx GE 5200 and xx LE 7000 AND $
       ;            yy GE 12600 AND yy LE 14000 $
       ;          AND finite(mpix) EQ 1,ct)
     ;  wh = where(xx GE 8500 and xx LE 9000 AND $
     ;             yy GE 6500 AND yy LE 7000 $
     ;             AND finite(mpix) EQ 1,ct)
       wh = where(xx GE 6000 and xx LE 6500 AND $
                  yy GE 13000 AND yy LE 13500 $
                  AND finite(mpix) EQ 1,ct)
       IF ct GT nn THEN wh = wh[(sort(randomu(seed,ct)))[0:nn-1]]

       yr = [6,-6]

       plot,im1[wh]-im2[wh],im2[wh],ps=8,yr=yr,xr=[-1,4],ys=1,xs=1,$
            xtit=xtit,ytit=ytit,tit='M31 Outer Disk (HST)',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red
       legend,['log M!Dpix!N='+strmid(strtrim(median(mpix[wh]),2),0,4)],$
              box=0,/right,charsize=0.9

       plot,m10.(whm1)-m10.(whm2),m10.(whm2),ps=8,yr=yr,xr=[-1,4],ys=1,xs=1,$
            xtit=xtit,ytit=ytit,tit='Model',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red
       legend,['log M!Dpix!N=1.0'],box=0,/right,charsize=0.9
       legend,['age=10 Gyr'],box=0,charsize=0.9

       plot,m05.(whm1)-m05.(whm2),m05.(whm2),ps=8,yr=yr,xr=[-1,4],ys=1,xs=1,$
            xtit=xtit,ytit=ytit,tit='Model',symsize=0.2
       oplot,t1.(wht1)-t1.(wht2),t1.(wht2),col=!red
       legend,['log M!Dpix!N=0.5'],box=0,/right,charsize=0.9
       legend,['age=10 Gyr'],box=0,charsize=0.9

     endplot,/quiet
     spawn,'convert -density 500 '+file+' '+str_replace(file,'.eps','.png')

     !p.multi=0
     stop

  ENDIF


END
