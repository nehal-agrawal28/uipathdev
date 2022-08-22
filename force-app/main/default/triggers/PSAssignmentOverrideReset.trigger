trigger PSAssignmentOverrideReset on pse__Assignment__c (after insert,after update) {
    Set<Id> pseIdSet = new Set<Id>();
    for(pse__Assignment__c pse: trigger.new){
        if(pse.TC_Lock_Override__c){
            pseIdSet.add(pse.Id);
        }
    }
    if(pseIdSet.size()>0){
        Datetime sysTime = System.now();

       // this would increase the time to 24 hours after current time
        sysTime = sysTime.addHours(24);

        String chron_exp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        
        //Schedule the next job, and give it the system time so name is unique
        System.schedule('New PSA Reassignment Schedule ' + sysTime.getTime(),chron_exp,new ScheduledPSAAssignmentOverrideReset(pseIdSet));
   
       
    }

}