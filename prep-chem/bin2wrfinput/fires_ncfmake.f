!
!=================================Make Executable============================
!  Make executable:
!
!  Run program:
!      fires_ncfmake input_data_file_name
!
!  Initial version May 2004
!  Cindy Bruyere
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Following subroutines must be in the 'INCLUDEDIR' directory defined as an environment variable, sepcified in compile statement
  include 'species.f'
  include 'netcdf_writroutines.f'
  include 'manipufiles.f'
!-------------------------------------------------------------------------------------------

  program fires_ncmake
! use species, only: plot_dim

  implicit none

  character (len=256)    :: input_file                        
  character (len=10)    :: option                        
  character (len=10)    :: plot_var
  integer               :: length_input, length_option, time1, time2
! integer               :: plot_dim(3)
  integer               :: numarg, i, idummy
  
  integer               :: ts_xy(3)
  real                  :: ts_ll(3)
  character (len=10)    :: ts_var(100)
  integer               :: ts_i
  character (len=2)     :: ts_type
  integer, external     :: iargc
  character (len=256)    :: dummy
  character (len=256)   :: BINRYFIL

       CALL GETENV ('binary_file',BINRYFIL)
  numarg = iargc()
  i = 1
    call getarg(i,dummy)
      input_file = dummy
      length_input = len_trim(input_file)

  if (input_file == " ")then
  write(*,*)' No input file selected, stopping'
  stop
  endif

  write(*,'(2A)')'INPUT FILE IS: ',trim(input_file)
  print*," "


! Now read the file
  call file_manipulate (BINRYFIL,input_file,length_input)


  end program fires_ncmake
