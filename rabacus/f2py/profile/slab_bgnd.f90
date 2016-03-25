!
! Routines to calculate ionization and / or temperature equilibrium for 
! slab gas distributions with uniform background radiation incident from
! both sides. 
!
!------------------------------------------------------------------------

module slab_bgnd
  use types
  use physical_constants, only: ev_2_erg, pi
  use ion_solver, only: solve_pce, solve_pcte
  use chem_cool_rates, only: get_kchem

  use slab_base, only: set_optical_depths
  use slab_base, only: set_recomb_photons

  use photo_xsections, only: return_E_H1_th, return_sigma_H1
  use photo_xsections, only: return_E_He1_th, return_sigma_He1
  use photo_xsections, only: return_E_He2_th, return_sigma_He2

  use source_background, only: bgnd_src_return_ionrate_thin
  use source_background, only: bgnd_src_return_heatrate_thin

  use source_background, only: bgnd_src_return_ionrate_shld_ei
  use source_background, only: bgnd_src_return_heatrate_shld_ei


  implicit none


  real(real64), parameter :: zero = 0.0d0
  real(real64), parameter :: half = 0.5d0
  real(real64), parameter :: one = 1.0d0
  real(real64), parameter :: two = 2.0d0
  real(real64), parameter :: four = 4.0d0
  integer(int32), parameter :: MAX_ITER = 500


contains

  
  !======================================================================
  ! slab_bgnd_solve
  !
  ! Main driver for slab solutions.  Distance is measured from one of the 
  ! slab faces (the situation is symmetric so it doesn't matter which).  Nl 
  ! is the number of layers in the slab.  
  !
  ! Input: 
  !   Edges: z-coordinates of layer edges [cm] (Nl+1 entries)
  !   nH: hydrogen number density in each layer [cm^-3]
  !   nHe: helium number density in each layer [cm^-3]
  !   Tmprtr: temperature in each layer [K]
  ! -----------------------------------------------------------------
  !   E_eV: energy samples for spectrum [eV]
  !   shape: shape of spectrum polychromatic=[erg/(s sr Hz cm^2)], 
  !                            monochromatic=[erg/(s sr cm^2)]
  ! -----------------------------------------------------------------
  !   i_rec_meth: how to treat recombinations? {1=fixed, 2=ray}
  !   fixed_fcA: If i_rec_meth=1, constant caseA fraction
  ! -----------------------------------------------------------------
  !   i_photo_fit: photo_xsection fits {1=verner96}
  !   i_rate_fit: atomic rate fits {1=hg97}
  !   i_find_Teq: solve for eqlbrm T {0=no,1=yes} if no, Tmprtr is constant
  !   i_thin: return optically thin values
  ! -----------------------------------------------------------------
  !   z: redshift, only used if i_find_Teq=1
  !   tol: tolerance for all convergence tests
  !   Nl: number of layers
  !   Nnu: number of energy samples in spectrum
  !
  ! Output: 
  !   Tmprtr: temperature in each layer [K]
  !   xH1: H1 ionization fraction = nH1 / nH
  !   xH2: H2 ionization fraction = nH2 / nH
  !   xHe1: He1 ionization fraction = nHe1 / nHe
  !   xHe2: He2 ionization fraction = nHe2 / nHe
  !   xHe3: He3 ionization fraction = nHe3 / nHe
  !   H1i_src: H1 source photoionization rate 
  !   He1i_src: He1 source photoionization rate 
  !   He2i_src: He2 source photoionization rate 
  !   H1i_rec: H1 recombination photoionization rate 
  !   He1i_rec: He1 recombination photoionization rate 
  !   He2i_rec: He2 recombination photoionization rate 
  !   H1h_src: H1 source photoheating rate
  !   He1h_src: He1 source photoheating rate
  !   He2h_src: He2 source photoheating rate
  !   H1h_rec: H1 recombination photoheating rate
  !   He1h_rec: He1 recombination photoheating rate
  !   He2h_rec: He2 recombination photoheating rate
  !
  !======================================================================
  
  subroutine slab_bgnd_solve( &
       Edges, nH, nHe, Tmprtr, &
       E_eV, shape, &
       i_rec_meth, fixed_fcA, &   
       i_photo_fit, i_rate_fit, i_find_Teq, &
       i_thin, z, tol, Nl, Nnu, &
       xH1, xH2, xHe1, xHe2, xHe3, &
       H1i_src, He1i_src, He2i_src, &
       H1i_rec, He1i_rec, He2i_rec, &
       H1h_src, He1h_src, He2h_src, &
       H1h_rec, He1h_rec, He2h_rec  )
    
    ! arguments
    !--------------------------------------------------------
    real(real64), dimension(0:Nl), intent(in) :: Edges  
    real(real64), dimension(0:Nl-1), intent(in) :: nH, nHe
    real(real64), dimension(0:Nl-1), intent(inout) :: Tmprtr  
    real(real64), dimension(0:Nnu-1), intent(in) :: E_eV  
    real(real64), dimension(0:Nnu-1), intent(in) :: shape 

    integer(int32), intent(in) :: i_rec_meth
    real(real64), intent(in) :: fixed_fcA

    integer(int32), intent(in) :: i_photo_fit   
    integer(int32), intent(in) :: i_rate_fit    
    integer(int32), intent(in) :: i_find_Teq
    integer(int32), intent(in) :: i_thin

    real(real64), intent(in) :: z          
    real(real64), intent(in) :: tol
    integer(int32), intent(in) :: Nl       
    integer(int32), intent(in) :: Nnu       

    real(real64), dimension(0:Nl-1), intent(out) :: xH1, xH2
    real(real64), dimension(0:Nl-1), intent(out) :: xHe1, xHe2, xHe3
    real(real64), dimension(0:Nl-1), intent(out) :: H1i_src, H1i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He1i_src, He1i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He2i_src, He2i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: H1h_src, H1h_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He1h_src, He1h_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He2h_src, He2h_rec


    ! local
    !--------------------------------------------------------
    real(real64) :: E_H1_th, E_He1_th, E_He2_th
    real(real64) :: sigma_H1_th, sigma_He1_th, sigma_He2_th
    real(real64), dimension(0:Nnu-1) :: sigma_H1, sigma_He1, sigma_He2

    integer(int32) :: iter
    logical :: not_converged
    real(real64), dimension(0:Nl-1) :: ne
    real(real64), dimension(0:Nl-1) :: conv_old, conv_new, conv_change





    !=======================================
    ! Initialize 
    !=======================================

    ! ionization thresholds 
    !---------------------------------------------
    E_H1_th = return_E_H1_th( i_rate_fit )
    E_He1_th = return_E_He1_th( i_rate_fit )
    E_He2_th = return_E_He2_th( i_rate_fit )

    ! photoionization xsections at thresholds
    ! (scalar quantities)
    !---------------------------------------------
    sigma_H1_th  = sum( return_sigma_H1(  (/E_H1_th/), i_photo_fit, 1 ) )
    sigma_He1_th = sum( return_sigma_He1( (/E_He1_th/), i_photo_fit, 1 ) )
    sigma_He2_th = sum( return_sigma_He2( (/E_He2_th/), i_photo_fit, 1 ) )

    ! photoionization xsections 
    ! (frequency dependent vectors)
    !---------------------------------------------
    sigma_H1 = return_sigma_H1( E_eV, i_photo_fit, Nnu )
    sigma_He1 = return_sigma_He1( E_eV, i_photo_fit, Nnu )
    sigma_He2 = return_sigma_He2( E_eV, i_photo_fit, Nnu )


    !=======================================
    ! Set optically thin values 
    !=======================================
    call slab_bgnd_optically_thin( &
         Edges, nH, nHe, Tmprtr, &
         E_eV, shape, &
         sigma_H1, sigma_He1, sigma_He2, &
         E_H1_th, E_He1_th, E_He2_th, &
         fixed_fcA, i_find_Teq, z, &
         i_rate_fit, tol, Nl, Nnu, &
         xH1, xH2, xHe1, xHe2, xHe3, &
         H1i_src, He1i_src, He2i_src, &
         H1i_rec, He1i_rec, He2i_rec, &
         H1h_src, He1h_src, He2h_src, &
         H1h_rec, He1h_rec, He2h_rec  ) 

    if ( i_thin == 1 ) then
       return
    end if


    !=======================================
    ! Perform sweeps 
    !=======================================


    ! begin iterations 
    !---------------------------------------------
    iter = 0
    ne = xH2 * nH + ( xHe2 + two * xHe3 ) * nHe

    conv_old = ne
    not_converged = .true. 
    do while( not_converged )

       call slab_bgnd_sweep( &
            xH1, xH2, xHe1, xHe2, xHe3, &
            Edges, nH, nHe, Tmprtr, &
            E_eV, shape, &
            sigma_H1, sigma_He1, sigma_He2, &
            sigma_H1_th, sigma_He1_th, sigma_He2_th, &
            E_H1_th, E_He1_th, E_He2_th, &
            i_rec_meth, fixed_fcA, &
            i_find_Teq, z, &
            i_photo_fit, i_rate_fit,  &
            tol, Nl, Nnu, &
            H1i_src, He1i_src, He2i_src, &
            H1i_rec, He1i_rec, He2i_rec, &
            H1h_src, He1h_src, He2h_src, &
            H1h_rec, He1h_rec, He2h_rec  ) 
       

       ! check convergence 
       !------------------------------------------------
       if ( iter == 100 ) then
          write(*,*) "  Warning: 100 iterations in slab_bgnd_solve.f90"
       end if

       if ( iter > MAX_ITER ) then
          write(*,*) "MAX ITER in slab_bgnd_solve.f90"
          stop
       end if

       iter = iter + 1
       ne = xH2 * nH + ( xHe2 + two * xHe3 ) * nHe

       conv_new = ne
       conv_change = conv_new / conv_old - one
       if ( all( abs(conv_change) < tol ) ) then
          not_converged = .false.
          write(*,*) 'iterations to converge: ', iter
       end if
       conv_old = conv_new


    end do


  end subroutine slab_bgnd_solve



  !======================================================================
  ! slab_bgnd_optically_thin
  !
  ! Sets optically thin ionization fractions. 
  !
  ! Input: 
  !   Edges: distance from z=0 surface [cm] (Nl+1 entries)
  !   nH: hydrogen number density in each layer [cm^-3]
  !   nHe: helium number density in each layer [cm^-3]
  !   Tmprtr: temperature in each layer [K]
  ! ---------------------------------------------------------------
  !   E_eV: energy samples for spectrum [eV]
  !   shape: shape of spectrum polychromatic=[erg/(s sr Hz cm^2)], 
  !                            monochromatic=[erg/(s sr cm^2)]
  ! ---------------------------------------------------------------
  !   sigma_H1: H1 photo_xsection at each energy in E_eV [cm^2]
  !   sigma_He1: He1 photo_xsection at each energy in E_eV [cm^2]
  !   sigma_He2: He2 photo_xsection at each energy in E_eV [cm^2]
  ! ---------------------------------------------------------------
  !   E_H1_th: H1 ionization threshold [eV]
  !   E_He1_th: He1 ionization threshold [eV]
  !   E_He2_th: He2 ionization threshold [eV]
  ! ---------------------------------------------------------------
  !   fixed_fcA: If i_rec_meth=1, constant caseA fraction
  !   i_find_Teq: solve for eqlbrm T {0=no,1=yes} if no, Tmprtr is constant
  !   z: redshift, only used if i_find_Teq=1
  !   i_rate_fit: atomic rate fits {1=hg97}
  ! ---------------------------------------------------------------
  !   tol: tolerance for all convergence tests
  !   Nl: number of layers
  !   Nnu: number of energy samples in spectrum
  !
  ! Output: 
  !   Tmprtr: temperature in each layer [K]
  !   xH1: H1 ionization fraction = nH1 / nH
  !   xH2: H2 ionization fraction = nH2 / nH
  !   xHe1: He1 ionization fraction = nHe1 / nHe
  !   xHe2: He2 ionization fraction = nHe2 / nHe
  !   xHe3: He3 ionization fraction = nHe3 / nHe
  !   H1i_src: H1 source photoionization rate 
  !   He1i_src: He1 source photoionization rate 
  !   He2i_src: He2 source photoionization rate 
  !   H1i_rec: H1 recombination photoionization rate 
  !   He1i_rec: He1 recombination photoionization rate 
  !   He2i_rec: He2 recombination photoionization rate 
  !   H1h_src: H1 source photoheating rate
  !   He1h_src: He1 source photoheating rate
  !   He2h_src: He2 source photoheating rate
  !   H1h_rec: H1 recombination photoheating rate
  !   He1h_rec: He1 recombination photoheating rate
  !   He2h_rec: He2 recombination photoheating rate
  !
  !======================================================================
  subroutine slab_bgnd_optically_thin( &
       Edges, nH, nHe, Tmprtr, &
       E_eV, shape, &
       sigma_H1, sigma_He1, sigma_He2, &
       E_H1_th, E_He1_th, E_He2_th, &
       fixed_fcA, i_find_Teq, z, &
       i_rate_fit, tol, Nl, Nnu, &
       xH1, xH2, xHe1, xHe2, xHe3, &
       H1i_src, He1i_src, He2i_src, &
       H1i_rec, He1i_rec, He2i_rec, &
       H1h_src, He1h_src, He2h_src, &
       H1h_rec, He1h_rec, He2h_rec  )

    ! Arguments
    !-------------------------------------------------------------
    real(real64), dimension(0:Nl), intent(in) :: Edges
    real(real64), dimension(0:Nl-1), intent(in) :: nH, nHe
    real(real64), dimension(0:Nl-1), intent(inout) :: Tmprtr
    real(real64), dimension(0:Nnu-1), intent(in) :: E_eV, shape
    real(real64), dimension(0:Nnu-1), intent(in) :: sigma_H1
    real(real64), dimension(0:Nnu-1), intent(in) :: sigma_He1
    real(real64), dimension(0:Nnu-1), intent(in) :: sigma_He2
    real(real64), intent(in) :: E_H1_th, E_He1_th, E_He2_th

    real(real64), intent(in) :: fixed_fcA
    integer(int32), intent(in) :: i_find_Teq
    real(real64), intent(in) :: z
    integer(int32), intent(in) :: i_rate_fit

    real(real64), intent(in) :: tol
    integer(int32), intent(in) :: Nl
    integer(int32), intent(in) :: Nnu

    real(real64), dimension(0:Nl-1), intent(out) :: xH1, xH2
    real(real64), dimension(0:Nl-1), intent(out) :: xHe1, xHe2, xHe3
    real(real64), dimension(0:Nl-1), intent(out) :: H1i_src, H1i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He1i_src, He1i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He2i_src, He2i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: H1h_src, H1h_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He1h_src, He1h_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He2h_src, He2h_rec

    ! Local
    !---------------------------------------------------------------
    real(real64), dimension(0:Nl-1) :: fcA_H2, fcA_He2, fcA_He3
    real(real64), dimension(0:Nl-1) :: reH2, reHe2, reHe3
    real(real64), dimension(0:Nl-1) :: ciH1, ciHe1, ciHe2    




    ! get chemistry rates at initial temperature 
    !---------------------------------------------
    fcA_H2 = fixed_fcA
    fcA_He2 = fixed_fcA
    fcA_He3 = fixed_fcA

    call get_kchem( Tmprtr, fcA_H2, fcA_He2, fcA_He3, &
         i_rate_fit, reH2, reHe2, reHe3, ciH1, ciHe1, ciHe2, Nl )


    ! get source optically thin photo ionization/heating rates 
    !---------------------------------------------
    H1i_src = bgnd_src_return_ionrate_thin( &
         E_eV, shape, sigma_H1, Nnu ) 

    He1i_src = bgnd_src_return_ionrate_thin( &
         E_eV, shape, sigma_He1, Nnu ) 

    He2i_src = bgnd_src_return_ionrate_thin( &
         E_eV, shape, sigma_He2, Nnu ) 


    H1h_src = bgnd_src_return_heatrate_thin( &
         E_eV, shape, sigma_H1, E_H1_th, Nnu ) 

    He1h_src = bgnd_src_return_heatrate_thin( &
         E_eV, shape, sigma_He1, E_He1_th, Nnu ) 

    He2h_src = bgnd_src_return_heatrate_thin( &
         E_eV, shape, sigma_He2, E_He2_th, Nnu ) 


    ! solve for equilibrium with only source photons
    !------------------------------------------------

    if ( i_find_Teq == 1 ) then
          
       call solve_pcte( nH, nHe, &
            H1i_src, He1i_src, He2i_src, &
            H1h_src, He1h_src, He2h_src, &
            z, fcA_H2, fcA_He2, fcA_He3, i_rate_fit, &
            xH1, xH2, xHe1, xHe2, xHe3, Tmprtr, tol, Nl )

    else

       call solve_pce( nH, nHe, reH2, reHe2, reHe3, &
            ciH1, ciHe1, ciHe2, H1i_src, He1i_src, He2i_src, &
            xH1, xH2, xHe1, xHe2, xHe3, tol, Nl )
       
    end if


    ! In the optically thin case, the intensity from photons travelling 
    ! in the x-y plane would be infinite so we ignore them. 
    !----------------------------------------------------------------
    H1i_rec = zero
    He1i_rec = zero
    He2i_rec = zero

    H1h_rec = zero
    He1h_rec = zero
    He2h_rec = zero

    
  end subroutine slab_bgnd_optically_thin



  !======================================================================
  ! slab_bgnd_sweep
  ! 
  ! Performs one sweep through the layers.
  !
  ! Input: 
  !   xH1: H1 ionization fraction = nH1 / nH
  !   xH2: H2 ionization fraction = nH2 / nH
  !   xHe1: He1 ionization fraction = nHe1 / nHe
  !   xHe2: He2 ionization fraction = nHe2 / nHe
  !   xHe3: He3 ionization fraction = nHe3 / nHe
  ! ---------------------------------------------------------------
  !   Edges: distance from z=0 surface [cm] (Nl+1 entries)
  !   Tmprtr: temperature in each layer [K]
  !   nH: hydrogen number density in each layer [cm^-3]
  !   nHe: helium number density in each layer [cm^-3]
  ! ---------------------------------------------------------------
  !   E_eV: energy samples for spectrum [eV]
  !   shape: shape of spectrum polychromatic=[erg/(s sr Hz cm^2)], 
  !                            monochromatic=[erg/(s sr cm^2)]
  ! ---------------------------------------------------------------
  !   sigma_H1: H1 photo_xsection at each energy in E_eV [cm^2]
  !   sigma_He1: He1 photo_xsection at each energy in E_eV [cm^2]
  !   sigma_He2: He2 photo_xsection at each energy in E_eV [cm^2]
  !------------------------------------------------------
  !   sigma_H1_th: H1 photo_xsection at H1 ionization threshold [cm^2]
  !   sigma_He1_th: He1 photo_xsection at He1 ionization threshold [cm^2]
  !   sigma_He2_th: He2 photo_xsection at He2 ionization threshold [cm^2]
  ! ---------------------------------------------------------------
  !   E_H1_th: H1 ionization threshold [eV]
  !   E_He1_th: He1 ionization threshold [eV]
  !   E_He2_th: He2 ionization threshold [eV]
  ! ---------------------------------------------------------------
  !   i_rec_meth: how to treat recombinations? {1=fixed, 2=ray}
  !   fixed_fcA: If i_rec_meth=1, constant caseA fraction
  ! ---------------------------------------------------------------
  !   i_find_Teq: solve for eqlbrm T {0=no,1=yes} if no, Tmprtr is constant
  !   z: redshift, only used if i_find_Teq=1
  ! ---------------------------------------------------------------
  !   i_photo_fit: photo_xsection fits {1=verner96}
  !   i_rate_fit: atomic rate fits {1=hg97}
  ! ---------------------------------------------------------------
  !   tol: tolerance for all convergence tests
  !   Nl: number of layers
  !   Nnu: number of energy samples in spectrum
  !
  ! Output: 
  !   xH1: H1 ionization fraction = nH1 / nH
  !   xH2: H2 ionization fraction = nH2 / nH
  !   xHe1: He1 ionization fraction = nHe1 / nHe
  !   xHe2: He2 ionization fraction = nHe2 / nHe
  !   xHe3: He3 ionization fraction = nHe3 / nHe
  !   Tmprtr: temperature in each layer [K]
  !   H1i_src: H1 source photoionization rate 
  !   He1i_src: He1 source photoionization rate 
  !   He2i_src: He2 source photoionization rate 
  !   H1i_rec: H1 recombination photoionization rate 
  !   He1i_rec: He1 recombination photoionization rate 
  !   He2i_rec: He2 recombination photoionization rate 
  !   H1h_src: H1 source photoheating rate
  !   He1h_src: He1 source photoheating rate
  !   He2h_src: He2 source photoheating rate
  !   H1h_rec: H1 recombination photoheating rate
  !   He1h_rec: He1 recombination photoheating rate
  !   He2h_rec: He2 recombination photoheating rate
  !
  !======================================================================
  subroutine slab_bgnd_sweep( &
       xH1, xH2, xHe1, xHe2, xHe3, &
       Edges, nH, nHe, Tmprtr, &
       E_eV, shape, &
       sigma_H1, sigma_He1, sigma_He2, &
       sigma_H1_th, sigma_He1_th, sigma_He2_th, &
       E_H1_th, E_He1_th, E_He2_th, &
       i_rec_meth, fixed_fcA, &
       i_find_Teq, z, &
       i_photo_fit, i_rate_fit,  &
       tol, Nl, Nnu, &
       H1i_src, He1i_src, He2i_src, &
       H1i_rec, He1i_rec, He2i_rec, &
       H1h_src, He1h_src, He2h_src, &
       H1h_rec, He1h_rec, He2h_rec  )

    ! arguments
    !--------------------------------------------------------------
    real(real64), dimension(0:Nl-1), intent(inout) :: xH1, xH2
    real(real64), dimension(0:Nl-1), intent(inout) :: xHe1, xHe2, xHe3
    real(real64), dimension(0:Nl), intent(in) :: Edges
    real(real64), dimension(0:Nl-1), intent(in) :: nH, nHe
    real(real64), dimension(0:Nl-1), intent(inout) :: Tmprtr
    real(real64), dimension(0:Nnu-1), intent(in) :: E_eV, shape

    real(real64), dimension(0:Nnu-1), intent(in) :: sigma_H1
    real(real64), dimension(0:Nnu-1), intent(in) :: sigma_He1
    real(real64), dimension(0:Nnu-1), intent(in) :: sigma_He2
    real(real64), intent(in) :: sigma_H1_th, sigma_He1_th, sigma_He2_th
    real(real64), intent(in) :: E_H1_th, E_He1_th, E_He2_th
    integer(int32), intent(in) :: i_rec_meth
    real(real64), intent(in) :: fixed_fcA
    integer(int32), intent(in) :: i_find_Teq
    real(real64), intent(in) :: z          
    integer(int32), intent(in) :: i_photo_fit
    integer(int32), intent(in) :: i_rate_fit
    real(real64), intent(in) :: tol
    integer(int32), intent(in) :: Nl, Nnu

    real(real64), dimension(0:Nl-1), intent(out) :: H1i_src, H1i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He1i_src, He1i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He2i_src, He2i_rec
    real(real64), dimension(0:Nl-1), intent(out) :: H1h_src, H1h_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He1h_src, He1h_rec
    real(real64), dimension(0:Nl-1), intent(out) :: He2h_src, He2h_rec


    ! locals
    !--------------------------------------------------------------
    real(real64), dimension(0:Nl-1) :: dl, l_c, dNH, dNHe    
    real(real64), dimension(0:Nl-1) :: dtau_H1_th, dtau_He1_th, dtau_He2_th
    real(real64), dimension(0:Nl-1) :: fcA_H2, fcA_He2, fcA_He3
    real(real64), dimension(0:Nl-1) :: tau_H1_th_lo, tau_H1_th_hi
    real(real64), dimension(0:Nl-1) :: tau_He1_th_lo, tau_He1_th_hi
    real(real64), dimension(0:Nl-1) :: tau_He2_th_lo, tau_He2_th_hi
    real(real64), dimension(0:Nl-1) :: H1i, He1i, He2i
    real(real64), dimension(0:Nl-1) :: H1h, He1h, He2h
    real(real64), dimension(0:Nnu-1) :: tau_H1, sigma_H1_ra
    real(real64), dimension(0:Nnu-1) :: tau_He1, sigma_He1_ra
    real(real64), dimension(0:Nnu-1) :: tau_He2, sigma_He2_ra
    
    real(real64), dimension(0:Nl-1) :: reH2, reHe2, reHe3
    real(real64), dimension(0:Nl-1) :: ciH1, ciHe1, ciHe2    

    real(real64), dimension(0:Nnu-1) :: tau_H1_lo, tau_He1_lo, tau_He2_lo 
    real(real64), dimension(0:Nnu-1) :: tau_H1_hi, tau_He1_hi, tau_He2_hi 

    real(real64), dimension(0:Nnu-1) :: tau_H1_lo_it, tau_H1_hi_it
    real(real64), dimension(0:Nnu-1) :: tau_He1_lo_it, tau_He1_hi_it
    real(real64), dimension(0:Nnu-1) :: tau_He2_lo_it, tau_He2_hi_it


    real(real64) :: H1i_lo, He1i_lo, He2i_lo
    real(real64) :: H1i_hi, He1i_hi, He2i_hi

    real(real64) :: H1h_lo, He1h_lo, He2h_lo
    real(real64) :: H1h_hi, He1h_hi, He2h_hi

    integer(int32) :: Nl2, inl, imir
    integer(int32) :: ii, ff


    ! geometry
    !---------------------------------------------
    Nl2 = Nl / 2
    dl = Edges(1:Nl) - Edges(0:Nl-1)
    l_c = Edges(0:Nl-1) + dl * half

    dNH = dl * nH
    dNHe = dl * nHe

    ! sigma ratios
    !---------------------------------------------
    sigma_H1_ra = sigma_H1 / sigma_H1_th
    sigma_He1_ra = sigma_He1 / sigma_He1_th
    sigma_He2_ra = sigma_He2 / sigma_He2_th

    ! initialize  dtauXX_th
    !---------------------------------------------       
    dtau_H1_th = dNH * xH1 * sigma_H1_th
    dtau_He1_th = dNHe * xHe1 * sigma_He1_th
    dtau_He2_th = dNHe * xHe2 * sigma_He2_th

    ! set case A fractions
    !---------------------------------------------
    if ( i_rec_meth == 1 ) then
       fcA_H2 = fixed_fcA
       fcA_He2 = fixed_fcA
       fcA_He3 = fixed_fcA
    else 
       fcA_H2 = one
       fcA_He2 = one
       fcA_He3 = one
    end if

    ! calculate photoionization and heating rates due 
    ! to recombinations to the ground state
    ! i_rec_meth = 1: fixed fcA
    ! i_rec_meth = 2: transfer photons
    !---------------------------------------------       
    if ( i_rec_meth == 1 ) then
       H1i_rec = zero
       He1i_rec = zero
       He2i_rec = zero
       H1h_rec = zero
       He1h_rec = zero
       He2h_rec = zero

    else if ( i_rec_meth == 2 ) then

       call set_recomb_photons( &
            xH1, xH2, xHe1, xHe2, xHe3, &
            Edges, nH, nHe, Tmprtr, &
            sigma_H1_th, sigma_He1_th, sigma_He2_th, &
            E_H1_th, E_He1_th, E_He2_th, &
            i_photo_fit, i_rate_fit, &
            H1i_rec, He1i_rec, He2i_rec, &
            H1h_rec, He1h_rec, He2h_rec, Nl )

    end if


    
    ! sweep through half of the layers (symmetry)
    ! and calculate photo ion/heat rates
    !---------------------------------------------

    !$omp parallel 

    !$omp  do private(inl, tau_H1_lo, tau_He1_lo, tau_He2_lo, &
    !$omp&  tau_H1_hi, tau_He1_hi, tau_He2_hi, H1i_lo, He1i_lo, He2i_lo, &
    !$omp&  H1i_hi, He1i_hi, He2i_hi, H1h_lo, He1h_lo, He2h_lo, &
    !$omp&  H1h_hi, He1h_hi, He2h_hi, imir )
    do inl = 0, Nl2-1


       ! calculate the optical depth at the ionization 
       ! threshold above and below this layer 
       !------------------------------------------------
       call set_optical_depths( &
            inl, dtau_H1_th, dtau_He1_th, dtau_He2_th, &
            tau_H1_th_lo(inl), tau_He1_th_lo(inl), tau_He2_th_lo(inl), &
            tau_H1_th_hi(inl), tau_He1_th_hi(inl), tau_He2_th_hi(inl), Nl )


       ! calculate the optical depth at all frequencies
       ! above and below this layer (normal to slab)
       !-------------------------------------------------------------
       tau_H1_lo  = ( tau_H1_th_lo(iNl) + &
            half * dtau_H1_th(iNl) ) * sigma_H1_ra
       tau_He1_lo = ( tau_He1_th_lo(iNl) + &
            half * dtau_He1_th(iNl) ) * sigma_He1_ra
       tau_He2_lo = ( tau_He2_th_lo(iNl) + &
            half * dtau_He2_th(iNl) ) * sigma_He2_ra
       
       tau_H1_hi  = ( tau_H1_th_hi(iNl) + &
            half * dtau_H1_th(iNl) ) * sigma_H1_ra
       tau_He1_hi = ( tau_He1_th_hi(iNl) + &
            half * dtau_He1_th(iNl) ) * sigma_He1_ra
       tau_He2_hi = ( tau_He2_th_hi(iNl) + &
            half * dtau_He2_th(iNl) ) * sigma_He2_ra


       ! calculate the shielded source photoionization rates
       !-------------------------------------------------------------
       H1i_lo = &
            bgnd_src_return_ionrate_shld_ei( E_eV, shape, sigma_H1, &
            tau_H1_lo, tau_He1_lo, tau_He2_lo, Nnu ) * half
       
       H1i_hi = &
            bgnd_src_return_ionrate_shld_ei( E_eV, shape, sigma_H1, &
            tau_H1_hi, tau_He1_hi, tau_He2_hi, Nnu ) * half
       
       !-------------------------------------------------------------
       He1i_lo = &
            bgnd_src_return_ionrate_shld_ei( E_eV, shape, sigma_He1, &
            tau_H1_lo, tau_He1_lo, tau_He2_lo, Nnu ) * half
       
       He1i_hi = &
            bgnd_src_return_ionrate_shld_ei( E_eV, shape, sigma_He1, &
            tau_H1_hi, tau_He1_hi, tau_He2_hi, Nnu ) * half
       
       !-------------------------------------------------------------
       He2i_lo = &
            bgnd_src_return_ionrate_shld_ei( E_eV, shape, sigma_He2, &
            tau_H1_lo, tau_He1_lo, tau_He2_lo, Nnu ) * half
       
       He2i_hi = &
            bgnd_src_return_ionrate_shld_ei( E_eV, shape, sigma_He2, &
            tau_H1_hi, tau_He1_hi, tau_He2_hi, Nnu ) * half
       
       !-------------------------------------------------------------
       H1i_src(iNl) = ( H1i_lo + H1i_hi ) 
       He1i_src(iNl) = ( He1i_lo + He1i_hi ) 
       He2i_src(iNl) = ( He2i_lo + He2i_hi ) 

       
       ! set total photoionization rates
       !---------------------------------------------------
       if ( i_rec_meth == 1 ) then
          H1i(inl) = H1i_src(inl) 
          He1i(inl) = He1i_src(inl) 
          He2i(inl) = He2i_src(inl) 
       else 
          H1i(inl) = H1i_src(inl) + H1i_rec(inl) 
          He1i(inl) = He1i_src(inl) + He1i_rec(inl) 
          He2i(inl) = He2i_src(inl) + He2i_rec(inl) 
       end if
       
       
       
       ! calculate the shielded photoionization rates
       !-------------------------------------------------------------
       H1h_lo = &
            bgnd_src_return_heatrate_shld_ei( E_eV, shape, sigma_H1, &
            E_H1_th, tau_H1_lo, tau_He1_lo, tau_He2_lo, Nnu ) * half
       
       H1h_hi = &
            bgnd_src_return_heatrate_shld_ei( E_eV, shape, sigma_H1, &
            E_H1_th, tau_H1_hi, tau_He1_hi, tau_He2_hi, Nnu ) * half
       
       !-------------------------------------------------------------
       He1h_lo = &
            bgnd_src_return_heatrate_shld_ei( E_eV, shape, sigma_He1, &
            E_He1_th, tau_H1_lo, tau_He1_lo, tau_He2_lo, Nnu ) * half
       
       He1h_hi = &
            bgnd_src_return_heatrate_shld_ei( E_eV, shape, sigma_He1, &
            E_He1_th, tau_H1_hi, tau_He1_hi, tau_He2_hi, Nnu ) * half
       
       !-------------------------------------------------------------
       He2h_lo = &
            bgnd_src_return_heatrate_shld_ei( E_eV, shape, sigma_He2, &
            E_He2_th, tau_H1_lo, tau_He1_lo, tau_He2_lo, Nnu ) * half
       
       He2h_hi = &
            bgnd_src_return_heatrate_shld_ei( E_eV, shape, sigma_He2, &
            E_He2_th, tau_H1_hi, tau_He1_hi, tau_He2_hi, Nnu ) * half
       
       !-------------------------------------------------------------
       H1h_src(iNl) = ( H1h_lo + H1h_hi ) 
       He1h_src(iNl) = ( He1h_lo + He1h_hi ) 
       He2h_src(iNl) = ( He2h_lo + He2h_hi ) 
       
       
       ! set total photoheating rates
       !---------------------------------------------------
       if ( i_rec_meth == 1 ) then
          H1h(inl) = H1h_src(inl) 
          He1h(inl) = He1h_src(inl) 
          He2h(inl) = He2h_src(inl) 
       else 
          H1h(inl) = H1h_src(inl) + H1h_rec(inl) 
          He1h(inl) = He1h_src(inl) + He1h_rec(inl) 
          He2h(inl) = He2h_src(inl) + He2h_rec(inl) 
       end if
       


       ! solve for equilibrium
       !-------------------------------------------------------------
       if ( i_find_Teq == 1 ) then
       
          call solve_pcte( &
               nH(inl), nHe(inl), H1i(inl), He1i(inl), He2i(inl), &
               H1h(inl), He1h(inl), He2h(inl), z, &
               fcA_H2(inl), fcA_He2(inl), fcA_He3(inl), i_rate_fit, &
               xH1(inl), xH2(inl), xHe1(inl), xHe2(inl), xHe3(inl), &
               Tmprtr(inl), tol, 1 )
          
       else
          
          call get_kchem( &
               Tmprtr(inl), fcA_H2(inl), fcA_He2(inl), fcA_He3(inl), &
               i_rate_fit, reH2(inl), reHe2(inl), reHe3(inl), &
               ciH1(inl), ciHe1(inl), ciHe2(inl), 1 ) 
          
          call solve_pce( &
               nH(inl), nHe(inl), reH2(inl), reHe2(inl), reHe3(inl), &
               ciH1(inl), ciHe1(inl), ciHe2(inl), &
               H1i(inl), He1i(inl), He2i(inl), &
               xH1(inl), xH2(inl), xHe1(inl), xHe2(inl), xHe3(inl), &
               tol, 1 )
          
       end if
       

       ! reflect the rates and solution 
       !-------------------------------------------------------------
       imir = Nl - 1 - iNl
              
       H1i(imir) = H1i(iNl)
       He1i(imir) = He1i(iNl)
       He2i(imir) = He2i(iNl)
       
       H1i_src(imir) = H1i_src(iNl)
       He1i_src(imir) = He1i_src(iNl)
       He2i_src(imir) = He2i_src(iNl)
       
       H1i_rec(imir) = H1i_rec(iNl)
       He1i_rec(imir) = He1i_rec(iNl)
       He2i_rec(imir) = He2i_rec(iNl)
       
       H1h(imir) = H1h(iNl)
       He1h(imir) = He1h(iNl)
       He2h(imir) = He2h(iNl)
       
       H1h_src(imir) = H1h_src(iNl)
       He1h_src(imir) = He1h_src(iNl)
       He2h_src(imir) = He2h_src(iNl)
       
       H1h_rec(imir) = H1h_rec(iNl)
       He1h_rec(imir) = He1h_rec(iNl)
       He2h_rec(imir) = He2h_rec(iNl)

       xH1(imir) = xH1(iNl)
       xH2(imir) = xH2(iNl)
       xHe1(imir) = xHe1(iNl)
       xHe2(imir) = xHe2(iNl)
       xHe3(imir) = xHe3(iNl)
       Tmprtr(imir) = Tmprtr(iNl)



                
    end do ! end loop over layers

    !$omp end parallel 




    
    
    



  end subroutine slab_bgnd_sweep





end module slab_bgnd
