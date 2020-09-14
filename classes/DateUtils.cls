public class DateUtils {
    
    public static Boolean isWeekendDay(Date dateParam){
        boolean result     = false;
        system.debug('dateParam = '+dateParam); 
        //Recover the day of the week
        Date startOfWeek   = dateParam.toStartOfWeek();
        system.debug('startOfWeek = '+startOfWeek);
        Integer dayOfWeek  = dateParam.day() - startOfWeek.day();
        system.debug('dayOfWeek = '+dayOfWeek);
        // if start of week is the month before the month we are now  
        if (dayOfWeek < 0){
            Integer monthDays = date.daysInMonth(startOfWeek.year(), startOfWeek.month());
            dayOfWeek = monthDays + dayOfWeek;          
        }       
        //  Make sure to check the user locale
        if (UserInfo.getLocale() == 'en_US') {
            result = dayOfWeek == 0 || dayOfWeek == 6 ? true : false; // Sunday & Saturday (US)
        } else {
            
            result = dayOfWeek == 5 || dayOfWeek == 6 ? true : false; // Sunday & Saturday (EU)
        }
        return result;
    }
    
    
    public static Date AddBusinessDays(Date StartDate, integer BusinessDaysToAdd )
    {
        //Add or decrease in BusinessDaysToAdd days 
        Date finalDate = StartDate;
        system.debug('finaldate = '+finalDate);
        integer direction = BusinessDaysToAdd < 0 ? -1 : 1;
        system.debug('direction = '+direction);
        while(BusinessDaysToAdd != 0)
        {
            finalDate = finalDate.AddDays(direction);
            system.debug('BusinessDaysToAdd = '+BusinessDaysToAdd);            
            system.debug('finaldate = '+finalDate);
            if (!isWeekendDay(finalDate))
            {
                BusinessDaysToAdd -= direction;
                
            }
        }
        
        return finalDate;
    }
    
}