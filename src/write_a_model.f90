PROGRAM WRITE_A_MODEL

  ! Routine to create one model Hess diagram convolved
  ! with an MDF, a SFH, and a P(Mpix)

  USE nrtype; USE pixcmd_utils; USE pixcmd_vars
  USE nr, ONLY : locate
  IMPLICIT NONE
  
  INTEGER  :: i,j,k
  REAL(SP) :: mpix,wgt,zmet0,zmets,tau,tot
  CHARACTER(50) :: infile
  REAL(SP), DIMENSION(nx,ny) :: onemodel
  REAL(SP), DIMENSION(npix,npix,nfil) :: f1,cf1,of1
  REAL(SP), DIMENSION(nage)  :: sfh
  REAL(SP), DIMENSION(nz)    :: mdf,zz
  CHARACTER(10) :: time

  !------------------------------------------------------------!

  infile = 'model_M2.0_t15_Z5_new'
  mpix   = 2.0
  zmet0  = 0.0
  zmets  = 0.05
  tau    = 2.0

  !setup the model grid
  CALL SETUP_MODELS()

  !(nm,nz,nage,nx,ny)
  !mpixarr, zmetarr, agesarr

  !MDF
  zz  = LOG10(zmetarr/0.0190)
  !mdf = EXP(-(zz-zmet0)**2/2/zmets)
  mdf = 1.0
  
  !SFH
  sfh = EXP(-(10**10.201-10**agesarr)/1E9/tau)
  sfh=0.
  sfh(15:15)=1.0

  tot=0.
  DO i=1,nage
     DO j=1,nz
        tot = tot + mdf(j)*sfh(i)
     ENDDO
  ENDDO

  f1 = 0.0
  DO j=1,nage
     DO i=1,nz
        wgt = mdf(i)*sfh(j)/tot
        f1  = f1+wgt*model(:,:,:,i,j)
     ENDDO
  ENDDO

  f1 = model(:,:,:,nz,nage)

  !convolve with PSF
  cf1 = -2.5*LOG10(convolve(f1))

  !add obs errors
  of1 = add_obs_err(cf1)

  !compute Hess diagram
  onemodel = hist_2d(of1(:,:,1)-of1(:,:,2),of1(:,:,2),&
       xhess,yhess,nx,ny,npix)

  !save the Hess diagram to file
  OPEN(1,FILE=TRIM(PIXCMD_HOME)//'data/'//TRIM(infile)//'.hess',&
       FORM='UNFORMATTED',STATUS='REPLACE',access='direct',&
       recl=nx*ny*4)
  WRITE(1,rec=1) onemodel
  CLOSE(1)


END PROGRAM WRITE_A_MODEL
