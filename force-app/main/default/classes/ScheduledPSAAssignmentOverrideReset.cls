global class ScheduledPSAAssignmentOverrideReset Implements Schedulable
    {
        global Set<Id> pseIdSet ;
        global ScheduledPSAAssignmentOverrideReset(Set<Id> pseIdSet ){
            this.pseIdSet = pseIdSet ;
        }
        global void execute(SchedulableContext sc)
        {
            setToAssignmentOverride(pseIdSet);
        }

        public void setToAssignmentOverride(Set<Id> pseIdSet)
        {
            
            List<pse__Assignment__c>  listAssignment = [SELECT Id,TC_Lock_Override__c FROM pse__Assignment__c WHERE Id In:pseIdSet];

            for(pse__Assignment__c pa : listAssignment)
            {
                if(pa.TC_Lock_Override__c){
                    pa.TC_Lock_Override__c = false;
                }
            }

            update listAssignment;
        }
    }