program cycle_smoke
  use module_io
  use module_var_info
  implicit none

  integer :: narg, iarg, arglen
  character(len=:), pointer :: infile=>NULL()
  character(len=:), pointer :: outfile=>NULL()
  character(len=:), pointer :: varname=>NULL()
  character(len=:), pointer :: opt=>NULL()

  integer :: ncin, ncout, arg1
  logical :: am_defining, zero_data
  type(var_info), allocatable, dimension(:) :: from_vars, to_vars

  narg=command_argument_count()

  zero_data=.false.
  arg1=1

  parse_args: do while(arg1<narg-1)
     opt=>getarg(arg1)
     arg1=arg1+1
     if(opt=='--zero' .or. opt=='-0') then
        zero_data=.true.
     else if(opt=='--') then
        exit parse_args
     else if(opt(1:1)=='-') then
        call usage(0,'unknown option "'//opt//'"')
     else if(opt(1:1)/='-') then
        arg1=arg1-1
        exit parse_args
     endif
  end do parse_args

  if(narg<3) then
     call usage(0,'you must specify an input file, an output file, and at least one variable')
  endif

  print 20,narg-2
  infile=>getarg(narg-1)

  print 13,infile,'read from this file'

  outfile=>getarg(narg)

  print 13,outfile,'write to this file'

  call open_files(infile,outfile,ncin,ncout)

  allocate(from_vars(narg-2))
  allocate(to_vars(narg-2))
  am_defining=.false.

  scan_and_define: do iarg=arg1,narg-2
     varname=>getarg(iarg)

     write(0,*) 'varname',varname

     if(.not.get_var_info(varname,infile,ncin,from_vars(iarg))) then
        write(0,13) infile,'no such variable: "'//varname//'"'
        stop 4
     endif

     if(.not.get_var_info(varname,outfile,ncout,to_vars(iarg))) then
        if(.not.am_defining) then
           call start_defining(outfile,ncout)
           am_defining=.true.
        endif
        print 13,outfile,'define variable: '//varname
        call def_var(infile,ncin,from_vars(iarg), &
                     outfile,ncout,to_vars(iarg))
     endif

     deallocate(varname)
     nullify(varname)
  enddo scan_and_define

  if(am_defining) then
     call stop_defining(outfile,ncout)
  endif

  copy_data: do iarg=arg1,narg-2
     call read_var(infile,ncin,from_vars(iarg))
     if(zero_data) then
        print 13,outfile,'will write zeros for: '//from_vars(iarg)%varname
        call zero_var(from_vars(iarg))
     endif
     call write_var(infile,from_vars(iarg), &
                    outfile,ncout,to_vars(iarg))

     call free_var_info(from_vars(iarg))
     call free_var_info(to_vars(iarg))
  enddo copy_data

  call close_files(infile,outfile,ncin,ncout)

  if(narg>3) then
     print 19,narg-2,'s.'
  else
     print 19,narg-2,'.'
  endif

13 format(A,': ',A)
19 format('Successful completion.  Wrote ',I0,' variable',A)
20 format('Number of variables to read and write: ',I0)

contains

  function getarg(iarg) result(carg)
    character(len=:), pointer :: carg
    integer, intent(in) :: iarg
    integer :: arglen

    call get_command_argument(number=iarg,length=arglen)

    allocate(character(len=arglen) :: carg)

    call get_command_argument(number=iarg,value=carg)

  end function getarg

  subroutine usage(stream,why)
    integer, intent(in) :: stream
    character(len=*), optional, intent(in) :: why

     write(stream,'(A)') 'Syntax: cycle_smoke [options] varname [varname [...] ] infile.nc outfile.nc'
     write(stream,'(A)') 'Synopsis:'
     write(stream,'(A)') '  Will read specified variables from infile.nc and write to outfile.nc'
     write(stream,'(A)') '  Variables must already be defined in both files, and must have the'
     write(stream,'(A)') '  same type, dimension count, and dimension sizes.'
     write(stream,'(A)') 'Return status:'
     write(stream,'(A)') '  Program exits with status 0 on success, non-zero on failure.'
     write(stream,'(A)') '  Upon failure, variables before the failing variable have been written.'
     write(stream,'(A)') 'Options:'
     write(stream,'(A)') '  -zero or -0   =   fill variable with zeros'
     write(stream,'(A)') '  --            =   terminate option parsing'

     if(present(why)) then
        write(stream,'(A)') ' '
        write(stream,'(A)') trim(why)
        stop 1
     else
        stop 0
     endif
   end subroutine usage

end program cycle_smoke
