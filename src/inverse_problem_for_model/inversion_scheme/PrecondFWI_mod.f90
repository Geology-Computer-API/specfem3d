module precond_mod

  !! IMPORT VARIABLES FROM SPECFEM -------------------------------------------------------------------------------------------------
  use specfem_par, only: CUSTOM_REAL, NGLLX, NGLLY, NGLLZ, NSPEC_ADJOINT, myrank, &
                         ibool, xstore, ystore, zstore


 !---------------------------------------------------------------------------------------------------------------------------------

  use inverse_problem_par

  implicit none

contains

  subroutine SetPrecond(iter_inverse, inversion_param, current_gradient, hess_approxim, fwi_precond)

    type(inver),                                               intent(in)    :: inversion_param
    integer,                                                   intent(in)    :: iter_inverse
    real(kind=CUSTOM_REAL), dimension(:,:,:,:,:), allocatable, intent(inout) :: current_gradient, fwi_precond, hess_approxim
    real(kind=CUSTOM_REAL)                                                   :: taper, x,y,z
    integer                                                                  :: i,j,k,ispec, iglob

    if (inversion_param%use_taper) then

       if (DEBUG_MODE) then
          write(IIDD,*)
          write(IIDD,*) '       iteration FWI : ', iter_inverse
          write(IIDD,*)
          write(IIDD,*) ' ADD taper X:',  inversion_param%xmin_taper,   inversion_param%xmax_taper
          write(IIDD,*) ' ADD taper Y:',  inversion_param%ymin_taper,   inversion_param%ymax_taper
          write(IIDD,*) ' ADD taper Z:',  inversion_param%zmin_taper,   inversion_param%zmax_taper
          write(IIDD,*)
          write(IIDD,*)
       endif

       do ispec=1, NSPEC_ADJOINT
          do k=1,NGLLZ
             do j=1,NGLLY
                do i=1,NGLLX

                   iglob=ibool(i,j,k,ispec)

                   x=xstore(iglob)
                   y=ystore(iglob)
                   z=zstore(iglob)

!!$                   taperx = 1.
!!$                   tapery = 1.
!!$                   taperz = 1.
!!$
!!$   if (x < inversion_param%xmin_taper) taperx = cos_taper(inversion_param%xmin_taper, inversion_param%xmin_taper, x)
!!$   if (x > inversion_param%xmax_taper) taperx = cos_taper(inversion_param%xmax_taper, inversion_param%xmax, x)
!!$   if (y < inversion_param%ymin_taper) tapery = cos_taper(inversion_param%ymin_taper, inversion_param%xmin_taper, y)
!!$   if (y > inversion_param%ymax_taper) tapery = cos_taper(inversion_param%ymax_taper, inversion_param%xmax, y)
!!$   if (z < inversion_param%zmin_taper) taperz = cos_taper(inversion_param%zmin_taper, inversion_param%xmin_taper, z)
!!$   if (z > inversion_param%zmax_taper) taperz = cos_taper(inversion_param%zmax_taper, , z)

                   if (x > inversion_param%xmin_taper .and. x < inversion_param%xmax_taper .and. &
                       y > inversion_param%ymin_taper .and. y < inversion_param%ymax_taper .and. &
                       z > inversion_param%zmin_taper .and. z < inversion_param%zmax_taper ) then
                      taper = 1.
                   else
                      taper = 0.
                   endif

                   current_gradient(i,j,k,ispec,:) = taper *   current_gradient(i,j,k,ispec,:)

                enddo
             enddo
          enddo
       enddo


    endif

    !! only need to define the Z2 precond once.
    if (inversion_param%z2_precond .and. iter_inverse == 0) then
        if (DEBUG_MODE) then
          write(IIDD,*)
          write(IIDD,*) '       iteration FWI : ', iter_inverse
          write(IIDD,*)
          write(IIDD,*) '             define Z*Z Precond :'
          write(IIDD,*)
          write(IIDD,*)
       endif

       do ispec=1, NSPEC_ADJOINT
          do k=1,NGLLZ
             do j=1,NGLLY
                do i=1,NGLLX

                   iglob=ibool(i,j,k,ispec)
                   z=zstore(iglob)
                   fwi_precond(i,j,k,ispec,:) = z*z

                enddo
             enddo
          enddo
       enddo


    endif

    if (inversion_param%shin_precond .and. iter_inverse == 0) then
 
       if (DEBUG_MODE) then
          write(IIDD,*)
          write(IIDD,*) '       iteration FWI : ', iter_inverse
          write(IIDD,*)
          write(IIDD,*) '             define Shin Precond :'
          write(IIDD,*)
          write(IIDD,*)
       endif
       
       fwi_precond(:,:,:,:,:) = 1._CUSTOM_REAL / abs(hess_approxim(:,:,:,:,:))
       

    end if

    
    if (inversion_param%energy_precond .and. iter_inverse == 0) then
 
       if (DEBUG_MODE) then
          write(IIDD,*)
          write(IIDD,*) '       iteration FWI : ', iter_inverse
          write(IIDD,*)
          write(IIDD,*) '             define energy Precond :'
          write(IIDD,*)
          write(IIDD,*)
       endif
       
       do i=1,inversion_param%NinvPar
          fwi_precond(:,:,:,:,i) = 1._CUSTOM_REAL / abs(hess_approxim(:,:,:,:,1))
       end do

    end if


  end subroutine SetPrecond

end module precond_mod
