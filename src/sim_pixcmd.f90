PROGRAM SIM_PIXCMD

  ! Program to compute a pixel CMD and from it a Hess diagram
  ! syntax: sim_pixcmd.exe log(Mpix) Z

  ! Note that the model Hess diagrams are likely not completely
  ! converted at Npix=1E3.  Should at some point try 1E4 (!)
  
  USE pixcmd_vars; USE pixcmd_utils
  USE nr, ONLY : poidev; USE nrtype 
  IMPLICIT NONE

  REAL(SP), PARAMETER    :: bkgnd = 1E-10

  TYPE TISO
     !band order is BVIJH
     REAL(SP), DIMENSION(nfil) :: bands
     REAL(SP) :: imf=-66.
  END TYPE TISO
  
  INTEGER :: i,j,k,t,iseed,nn,niso,stat
  REAL(SP) :: mpix,zmet,age,iage=0.,d1,d2,d3,d4,d5,phase
  REAL(SP), DIMENSION(5)  :: dum5
  REAL(SP), DIMENSION(27) :: dum27
  REAL(SP), DIMENSION(nfil,npix,npix)  :: flux=0.,cflux=0.,oflux=0.
  REAL(SP), DIMENSION(npsf,npsf) :: psf=0.
  TYPE(TISO), DIMENSION(niso_max) :: iso
  CHARACTER(10) :: time
  CHARACTER(50) :: file='',tag=''
  CHARACTER(6)  :: zstr
  CHARACTER(4)  :: mstr

  !variables for 2D histogram in B-I vs. I
  REAL(SP), DIMENSION(nx) :: xarr
  REAL(SP), DIMENSION(ny) :: yarr
  REAL(SP), DIMENSION(nage,nx,ny) :: hess=0.

  !data-specific parameters
  REAL(SP) :: dm=24.47  !M31 distance modulus
  !exposure times B,I
  REAL(SP), DIMENSION(nfil) :: exptime=(/1720.+1900.,1520.+1715./)
  !zero-points, B,I
  REAL(SP), DIMENSION(nfil) :: zpt=(/26.0593,25.9433/)
  
  !----------------------------------------------------------------!

  IF (IARGC().LT.1) THEN
     mpix = 1E3
     zmet = 0.0190
  ELSE IF (IARGC().EQ.1.OR.IARGC().GT.2) THEN
     WRITE(*,*) 'PIXCMD ERROR: incorrect syntax, returning'
     STOP
  ELSE
     CALL GETARG(1,file)
     READ(file,*) mpix
     mpix = 10**mpix
     CALL GETARG(2,file)
     READ(file,'(F6.4)') zmet
  ENDIF
  WRITE(zstr,'(F6.4)') zmet
  WRITE(mstr,'(F4.2)') LOG10(mpix)

  WRITE(*,'("log Mpix  =",F6.2)') LOG10(mpix)
  WRITE(*,'("log Z/Zsol=",F6.2)') LOG10(zmet/0.0190)

  !set a background flux level
  flux = bkgnd

  !set up the Hess arrays
  DO i=1,nx
     xarr(i) = xmin+(i-1)*dx
  ENDDO
  DO i=1,ny
     yarr(i) = ymin+(i-1)*dy
  ENDDO

  !initialize the random number generator
  CALL INIT_RANDOM_SEED()

  !read in the ACS F814W PSF (log PSF in the file)
  OPEN(12,file='../psf/f814w.psf',STATUS='OLD',iostat=stat,ACTION='READ')
  IF (stat.NE.0) THEN
     WRITE(*,*) 'PIXCMD ERROR: PSF file not found'
     STOP
  ENDIF
  DO i=1,npsf
     READ(12,*) psf(:,i)
  ENDDO
  psf = 10**psf

  !open the isochrone file
  OPEN(10,file='../isoc/SSP_MISTv29_BaSeL_Salpeter_Z'//zstr//&
       '_default.out.cmd',STATUS='OLD',iostat=stat,ACTION='READ')
  IF (stat.NE.0) THEN
     WRITE(*,*) 'PIXCMD ERROR: isoc file not found'
     STOP
  ENDIF
  READ(10,*)

  CALL DATE_AND_TIME(TIME=time)
  WRITE(*,*) 'Start Time '//time(1:2)//':'//time(3:4)//':'//time(5:6)

  !--------------------Loop on population age--------------------!

  DO t=1,nage

     age = age0+(t-1)*dage

     !----------------Read in the input isochrone info----------------!

     !burn the young models
     DO WHILE (iage-age.LT.-0.01) 
        READ(10,*,IOSTAT=stat) iage
     ENDDO

     BACKSPACE(10)
     i=1
     iso%imf = -99.
     DO WHILE (ABS(iage-age).LT.1E-2) 
        IF (i.GT.niso_max) THEN
           WRITE(*,*) 'PIXCMD ERROR niso_max reached',i
           STOP
        ENDIF
        READ(10,*,IOSTAT=stat) iage,dum5,phase,d5,iso(i)%imf,&
             dum27,iso(i)%bands(1),d1,d2,d3,d4,iso(i)%bands(2)
        IF (phase.NE.6) i=i+1  !skip the post-AGB
        IF (stat.NE.0) GOTO 20
     ENDDO
20   CONTINUE

     niso = i-1
     iso(1:niso)%imf   = 10**iso(1:niso)%imf
     !convert to flux
     iso(1:niso)%bands(1) = 10**(-2./5*iso(1:niso)%bands(1))
     iso(1:niso)%bands(2) = 10**(-2./5*iso(1:niso)%bands(2))

     WRITE(*,'(F6.2,1x,I4)') age,niso

     !----------------Compute the model at each pixel-----------------!

     !compute the model over an NxN image
     flux = 0.0
     DO j=1,npix
        DO i=1,npix
           DO k=1,niso
              nn = poidev(mpix*iso(k)%imf)
              flux(:,i,j) = flux(:,i,j) + nn*iso(k)%bands
           ENDDO
        ENDDO
     ENDDO

     !-------------------Convolve with the ACS PSF--------------------!

     cflux = convolve(flux,psf,npix,nfil,npsf)

     !convert to mags
     cflux = -2.5*LOG10(cflux)

     !--------------------Add observational errors--------------------!

     oflux = add_obs_err(cflux,dm,exptime,zpt)

     !---------------Compute a Hess diagram in B-I vs. I--------------!

     hess(t,:,:) = hist_2d(oflux(1,:,:)-oflux(2,:,:),oflux(2,:,:),&
          xarr,yarr,nx,ny,npix)

  ENDDO

  CLOSE(10)

  OPEN(11,FILE='../hess/hess_M'//mstr//'_Z'//zstr//'.dat',&
       FORM='UNFORMATTED',STATUS='REPLACE',access='direct',&
       recl=nage*nx*ny*4)
  WRITE(11,rec=1) hess
  CLOSE(11)

  CALL DATE_AND_TIME(TIME=time)
  WRITE(*,*) 'End Time '//time(1:2)//':'//time(3:4)//':'//time(5:6)


END PROGRAM SIM_PIXCMD
