subroutine openfiles(printnum, sumnum, printerr, sumerr, printfile, sumfile)

    ! inputs
    integer, intent(in) :: printnum, sumnum
    character*250, intent(in) :: printfile, sumfile

    ! outputs
    integer, intent(out) :: printerr, sumerr

    if (printnum > 0) then
        open(printnum, file=printfile, action='write', status='replace', iostat=printerr)
    end if
    if (sumnum /= 6 .and. sumnum > 0) then
        open(sumnum, file=sumfile, action='write', status='replace', iostat=sumerr)
    end if

end subroutine


subroutine closefiles(printnum, sumnum)

    ! inputs
    integer, intent(in) :: printnum, sumnum

    if (printnum > 0) then
        close(printnum)
    end if
    if (sumnum /= 6 .and. sumnum > 0) then 
        close(sumnum)
    end if

end subroutine


subroutine flushfiles(printnum, sumnum)

    ! inputs
    integer, intent(in) :: printnum, sumnum

    if (printnum > 0) then
        flush(printnum)
    end if
    if (sumnum /= 6 .and. sumnum > 0) then
        flush(sumnum)
    end if

end subroutine
