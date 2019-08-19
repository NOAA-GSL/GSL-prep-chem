program cycle_smoke
  use module_io
  use module_var_info
  implicit none

  integer :: narg, iarg, arglen
  character(len=:), pointer :: infile=>NULL()
  character(len=:), pointer :: outfile=>NULL()
  character(len=:), pointer :: varname=>NULL()

  integer :: ncin, ncout
  logical :: am_defining
  type(var_info), allocatable, dimension(:) :: from_vars, to_vars

  narg=command_argument_count()

  if(narg<3) then
     write(0,'(A)') 'Syntax: cycle_smoke varname [varname [...] ] infile.nc outfile.nc'
     write(0,'(A)') 'Synopsis:'
     write(0,'(A)') '  Will read specified variables from infile.nc and write to outfile.nc'
     write(0,'(A)') '  Variables must already be defined in both files, and must have the'
     write(0,'(A)') '  same type, dimension count, and dimension sizes.'
     write(0,'(A)') 'Return status:'
     write(0,'(A)') '  Program exits with status 0 on success, non-zero on failure.'
     write(0,'(A)') '  Upon failure, variables before the failing variable have been written.'
     stop 5
  endif

  print 20,narg-2
  call get_command_argument(number=narg-1,length=arglen)
  allocate(character(len=arglen) :: infile)
  call get_command_argument(number=narg-1,value=infile)

  print 13,infile,'read from this file'

  call get_command_argument(number=narg,length=arglen)
  allocate(character(len=arglen) :: outfile)
  call get_command_argument(number=narg,value=outfile)

  print 13,outfile,'write to this file'

  call open_files(infile,outfile,ncin,ncout)

  allocate(from_vars(narg-2))
  allocate(to_vars(narg-2))
  am_defining=.false.

  scan_and_define: do iarg=1,narg-2
     call get_command_argument(number=iarg,length=arglen)
     allocate(character(len=arglen) :: varname)
     call get_command_argument(number=iarg,value=varname)

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

  copy_data: do iarg=1,narg-2
     call read_var(infile,ncin,from_vars(iarg))
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
end program cycle_smoke
