#   
# Calculates start/end year days for year Y01
# relative to year Y00
# with dDay intervals
# same code as 103dates.awk  
#   
# Usage: echo "YRDAY2MDAY" | awk -f dates.awk y01=098 d01=1,...,366
#      converts year day to month day
#      provides year, month, day for y01, d01
#   
#       echo "START DAY" | awk -f dates.awk y01=098 dd=7 
#       provides 1st day to start relative to HYCOM start date 1900, Dec. 31
#   
#       echo "END DAY" |  awk -f dates.awk y01=098
#       provides last day in the year: 365 or 366
#   
#       echo "AB2MM" | awk -f dates.awk AB=a
#        converts months a,b,c,d,...,l -> 01,02,03,...,12
#          
#       echo "MM2AB" | awk -f dates.awk i=4
#        converts months i=1,2,3,4 -> AB=a,b,c,d,...,l 
#   
#       echo "YRMO START DAY" | awk -f dates.awk y01=097 MM=04 dd=7
#   or  echo "YRMO START DAY" | awk -f dates.awk y01=1997 MM=04 dd=7
#       returns Start and End year day numbers in month MM in current eyar y01
#       the dates are skipped dd days starting from Dec.31, year=1900 24hr
#         
#  Dmitry Dukhovskoy, FSU
#  Jan, 2017
#
#  Updates: 
#
#    May 2023: 
#  Convert month day to year day:
#         echo "MDAY2YRDAY" | awk -f dates.awk YR=2023 MM=3 DD=31
#
#  Find YYYY MM DD after adding/subtracting N days 
#         echo "ADD DAYS" | awk -f dates.awk yr1=2023 mo1=03 d1=31 ndays=-3       
#         echo "ADD DAYS" | awk -f dates.awk yr1=2023 mo1=03 d1=31 ndays=3       
#
#  Convert YY MM DD to HYCOM date
#         echo "DATE2HYCOM" | awk -f dates.awk YR=2023 MM=03 DD=31 
#
# Start day in HYCOM is calculated relative to Dec. 31, 1900
# for nest files (if bnestfq > 1 day, i.e. dd>1) need to have
# 1 day before the start of the simulation
#       echo "START DAY" | awk -f dates.awk y01=098 dd=7
/^START DAY/ {
        y00 = 001  # HYCOM Start year
  if ( y01 > 1900 ) {
          YR = y01 
          y01 =y01 - 1900
  } 
#        dYR = y01-y00
#        printf( "N.full years=  %4i\n", dYR )
    
        Ndays = 0
        for ( iyr=y00; iyr < y01; iyr++) {
      if ( iyr%4 == 0 ) 
              Ndays = Ndays + 366
            else
              Ndays = Ndays + 365
  }
        Ndays = Ndays + 1 # HYCOM correction due tp day 1= Dec. 31, 1900
        nres = Ndays%dd
#        printf( " Ndays= %i\n",Ndays )
#        printf(" nres= %7.2f\n",nres)
        dstart = dd-nres+1  # start day, in Jan. year y01
        if ( nres == 0 )
          dstart = 1
        printf( "START Jan  %i %i\n",dstart,y01+1900)
} 
# 
# Convert year=y01 day=d01 -> YYYY, MM, DD
# echo "YRDAY2MDAY" | awk -f dates.awk y01=098 d01=1,...,366
# 
/^YRDAY2MDAY/ {
    if ( y01 > 1900 ) {
      y01 =y01 - 1900
    }
    YR = y01 + 1900
    md[0]  = 0
    md[1]  = 31
    md[2]  = 59
    md[3]  = 90
    md[4]  = 120
    md[5]  = 151
    md[6]  = 181
    md[7]  = 212
    md[8]  = 243
    md[9]  = 273
    md[10] = 304
    md[11] = 334
    md[12] = 365
    if ( YR%4 == 0) {
  for ( i=2; i < 13; i++) {
           md[i] = md[i] + 1
  }
    }
    MM = 0
    DD = 0
    for ( i=1; i<13; i++ ) {
  if ( d01 <= md[i] && MM == 0) {
          MM = i
          DD = d01 - md[i-1]
  }
    }

    printf(" %4.4i %2.2i %2.2i\n",YR,MM,DD)

}
# 
# End day: 365 or 366
/^END DAY/ {
    YR = y01 + 1900
    if ( YR%4 == 0 )
      DEnd = 366
    else
      DEnd = 365

    printf( " %i\n",DEnd)

}
# Convert HYCOM month notations
# a,b,c,...,l
# to 01, 02, ..., 12
/^AB2MM/ {
  M["a"] = 1
  M["b"] = 2
  M["c"] = 3
  M["d"] = 4
  M["e"] = 5
  M["f"] = 6
  M["g"] = 7
  M["h"] = 8
  M["i"] = 9
  M["j"] = 10
  M["k"] = 11
  M["l"] = 12

  MM = M[AB]
  printf( " %2.2i\n",MM)

}
# Convert Months numbers into HYCOM a,b,c,...
# notations
#
/^MM2AB/ {
  M[1]="a"
  M[2]="b"
  M[3]="c"
  M[4]="d"
  M[5]="e"
  M[6]="f"
  M[7]="g"
  M[8]="h"
  M[9]="i"
  M[10]="j"
  M[11]="k"
  M[12]="l"

  i = i + 0 # to force conversion string->numbers in case "01"  is used instead of "1"
  AB = M[i]
  printf( " %s\n",AB)

}

#
# echo "YRMO START DAY" | awk -f nest_dates.awk y01=097 MM=04 dd=7
# y01 can be in 093 or 1993 format
# Convert year=y01 month=MM
# to the 1st and last year days
# for the current year
# that are dDay spaced starting
# year y00 - HYCOM 1900, Dec. 31
# this is needed to construct nest
# file names
/^YRMO START DAY/ {
    if ( y01 < 1900 ) {
      YR = y01 + 1900
    }
    else {
      YR = y01
      y01 =y01 - 1900
    }
    y00 = 001  # HYCOM Start year

    md[0]  = 0
    md[1]  = 31
    md[2]  = 59
    md[3]  = 90
    md[4]  = 120
    md[5]  = 151
    md[6]  = 181
    md[7]  = 212
    md[8]  = 243
    md[9]  = 273
    md[10] = 304
    md[11] = 334
    md[12] = 365
    if ( YR%4 == 0) {
  for ( i=2; i < 13; i++) {
           md[i] = md[i] + 1
  }
    }
#    for ( i=0; i<13; i++) {
# printf(" i=%i,  md[i]=%i\n",i, md[i])
#    }

#    printf( " MM = %i\n",MM)
# Year Day 
    i = sprintf("%i",MM-1)
    YD1 = md[i] + 1
    YD2 = md[i+1]
#    printf( " YD1 = %i, YD2 = %i\n",YD1, YD2) # Start and End should be >=YD1 and <= YD2

# Find Start day in January of this year with dd skipping
    Ndays = 0
    for ( iyr=y00; iyr < y01; iyr++) {
  if ( iyr%4 == 0 )
    Ndays = Ndays + 366
  else
    Ndays = Ndays + 365
    }
    Ndays = Ndays + 1  # HYCOM correction
    nres = Ndays%dd
#        printf( " Ndays= %i\n",Ndays )
#        printf(" nres= %7.2f\n",nres)
    dstart = dd-nres+1  # start day, in Jan. year y01
    if ( nres == 0 )
      dstart = 1
#    printf( "START Jan  %i %i\n",dstart, YR)

# Find Start/ End dates in the month:
    dSM = 0
    dEM = 0
    for ( day=dstart-dd; day <= YD2; day+=dd) {
      if ( day >= YD1 && dSM == 0 )
        dSM = day
    }
    dEM = day-dd

    printf(" %3.3i %3.3i\n",dSM, dEM)

}

/^MDAY2YRDAY/{
# Convert mo day to year day:
# echo "MDAY2YRDAY" | awk -f dates.awk YR=2023 MM=03 DD=31
    md[0]  = 0
    md[1]  = 31
    md[2]  = 59
    md[3]  = 90
    md[4]  = 120
    md[5]  = 151
    md[6]  = 181
    md[7]  = 212
    md[8]  = 243
    md[9]  = 273
    md[10] = 304
    md[11] = 334
    md[12] = 365
    if ( YR%4 == 0) {
      for ( i=2; i < 13; i++) {
           md[i] = md[i] + 1
      }
    }

    yday = md[MM-1]
    yday = yday + DD
    printf(" %4.4i %3.3i\n",YR, yday)
}

# Add/ subtract N days from the current day return YYYY MM DD
# echo "ADD DAYS" | awk -f dates.awk yr1=2023 mo1=03 d1=31 ndays=-3 
#  ndays is < 365/366 - possible error if > 1 year
/^ADD DAYS/{
# Convert mo day to jday:
#    printf(" yr1=%4i mo1=%2.2i d1=%2.2i ndays=%i\n", yr1, mo1, d1, ndays)
    YR = yr1
    MM = mo1
    DD = d1
    md[0]  = 0
    md[1]  = 31
    md[2]  = 59
    md[3]  = 90
    md[4]  = 120
    md[5]  = 151
    md[6]  = 181
    md[7]  = 212
    md[8]  = 243
    md[9]  = 273
    md[10] = 304
    md[11] = 334
    md[12] = 365
    if ( YR%4 == 0) {
      for ( i=2; i < 13; i++) {
           md[i] = md[i] + 1
      }
    }

    yday = md[MM-1]
    yday = yday + DD

# Convert to numbday - HYCOM day
    dnmb = 0
    for ( YS=1901; YS < YR; YS++ ) {
      if ( YS%4 == 0 ) {
        dnmb = dnmb + 366
        }
      else {
        dnmb = dnmb + 365
        }
      }
    dnmb = dnmb + yday

    dnmb_new = dnmb + ndays
#    printf("dnmb=%6i, dnmb_new = %6i \n",dnmb, dnmb_new)
    
# Convert back to YR and YR day
    dnmb0 = dnmb_new
    YR_new = 1900
    while ( dnmb0 > 0 ) {
      yday_new = dnmb0
      YR_new++
#      printf("YR=%i, dnmb0=%i\n", YR_new, dnmb0)
      if ( (YR_new)%4 == 0 ) {
        dnmb0 = dnmb0 - 366
        }
      else { 
        dnmb0 = dnmb0 - 365
        }
      } 

#    printf(" YR_new=%4.4i  yday_new=%3.3i \n",YR_new,yday_new)
# Convert back to YR MM DD
    md[0]  = 0
    md[1]  = 31
    md[2]  = 59
    md[3]  = 90
    md[4]  = 120
    md[5]  = 151
    md[6]  = 181
    md[7]  = 212
    md[8]  = 243
    md[9]  = 273
    md[10] = 304
    md[11] = 334
    md[12] = 365
    if ( YR_new%4 == 0) {
  for ( i=2; i < 13; i++) {
           md[i] = md[i] + 1
  }
    }
    MM_new = 0
    DD_new = 0
    for ( i=1; i<13; i++ ) {
  if ( yday_new <= md[i] && MM_new == 0) {
          MM_new = i
          DD_new = yday_new - md[i-1]
  }
    }

    printf(" %4.4i %2.2i %2.2i\n",YR_new,MM_new,DD_new)
 
}

# Convert YY MM DD to HYCOM date
# echo "DATE2HYCOM" | awk -f dates.awk YR=2023 MM=03 DD=31 
/^DATE2HYCOM/{
# Convert mo day to jday:
    md[0]  = 0
    md[1]  = 31
    md[2]  = 59
    md[3]  = 90
    md[4]  = 120
    md[5]  = 151
    md[6]  = 181
    md[7]  = 212
    md[8]  = 243
    md[9]  = 273
    md[10] = 304
    md[11] = 334
    md[12] = 365
    if ( YR%4 == 0) {
      for ( i=2; i < 13; i++) {
           md[i] = md[i] + 1
      }
    }

    yday = md[MM-1]
    yday = yday + DD

# Convert to numbday - HYCOM day
    dnmb = 0
    for ( YS=1901; YS < YR; YS++ ) {
      if ( YS%4 == 0 ) {
        dnmb = dnmb + 366
        }
      else {
        dnmb = dnmb + 365
        }
      }
    dnmb = dnmb + yday

  printf(" %i\n",dnmb)
}

