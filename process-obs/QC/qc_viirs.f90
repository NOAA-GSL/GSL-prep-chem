program qc_viirs
  ! Takes VIIRS NPP or J01 data into stdin, discards invalid lines,
  ! writes valid lines to stdout, and logs to stderr.

  implicit none

  ! Data fields read in, declared in order:
  INTEGER :: yy, mm, dd, hour, minute
  REAL :: lon_vi, lat_vi
  INTEGER :: mask, confi
  REAL :: t13, frp_v
  INTEGER :: posy, posx, bowtie

  ! Max length of a line
  integer, parameter :: LINE_LEN = 500

  ! Buffer for reading each line:
  CHARACTER(len=LINE_LEN) :: line

  ! Count the lines read in:
  integer :: nread, nwrote

  ! Detect parser errors in data lines:
  integer :: ios

  READ(5,'(A500)',iostat=ios,err=100,end=101) line
  print '(A)',trim(line)

40 format("Discard line ",I5," ",A," ",G20.12)
50 format("Discard line ",I5," ",A," ",I0)
 
  nread=0
  nwrote=0
  line_loop: do
     READ(5,'(A)', iostat=ios, err=200, end=201) line
     ios=0
     READ(line, *, iostat=ios) &
          yy,mm,dd,hour,minute,lon_vi,lat_vi,mask,confi,t13,frp_v, &
          posy,posx,bowtie

     if(ios/=0) then
        write(0,50) nread+1,'with parser error iostat =',ios
        cycle
     endif

     nread=nread+1
     
     if ((frp_v<1.) .OR. (frp_v>10000.)) then
        write(0,40) nread+1,"with implausible frp_v value",frp_v
     else if(lon_vi<-180.0 .or. lon_vi>180.0) then
        write(0,40) nread+1,'with longitude lon_vi outside [-180,180]',lon_vi
     else if(lat_vi>90.0 .or. lat_vi<-90.0) then
        write(0,40) nread+1,"with invalid lat_vi latitude",lat_vi
     else if(yy<1000 .or. yy>9999) then
        write(0,50) nread+1,"with non-four-digit year",yy
     else if(mm<1 .or. mm>12) then
        write(0,50) nread+1,"with invalid month",mm
     else if(dd<1 .or. dd>31) then
        write(0,50) nread+1,"with invalid day",dd
     else
        print '(A)',trim(line)
        nwrote=nwrote+1
     end if
  end do line_loop

100 continue ! Error handling for EOF on stdin for header
  write(0,'(A)') 'No header line seen; file is empty.'
  stop 0

101 continue ! Error handling for IO error on header
  write(0,'(A,I0)') 'Unable to read header from input: iostat=',ios
  stop 1

200 continue ! Error handling for IO error on data lines
  write(0,'(A,I0)') 'Error reading from input: iostat=',ios
  stop 2

201 continue ! EOF on stdin for data lines; normal exit
210 format("Data lines: read ",I0," wrote ",I0," discarded ",I0)
  write(0,210) nread,nwrote,nread-nwrote
  
end program qc_viirs
