global class SetPrimaryContactSchedulable implements Schedulable 
{
    public static void runScheduleClass()
    {
        string scheduleName = (Test.isRunningTest())? 'Set Primary Contact Schedulable Test ' : 'Set Primary Contact Schedulable ';
        // Run the class every 5 minutes
        System.schedule(scheduleName + '1', '0 0 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '2', '0 5 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '3', '0 10 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '4', '0 15 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '5', '0 20 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '6', '0 25 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '7', '0 30 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '8', '0 35 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '9', '0 40 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '10', '0 45 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '11', '0 50 * * * ?', new SetPrimaryContactSchedulable());
        System.schedule(scheduleName + '12', '0 55 * * * ?', new SetPrimaryContactSchedulable());
    }

    global void execute(SchedulableContext sc) 
    {
        Set<Id> contactRoleIdSet = new Set<id>();
        List<Opportunity> opportunityListToUpdate = new List<Opportunity>();        
        List<OpportunityContactRole> contactRoleList = new List<OpportunityContactRole>();

        List<RunSchedulableClassTimer__c> runSchedulableClassTimerList =
            [
                SELECT Id, Last_Run_Time__c
                FROM RunSchedulableClassTimer__c
                WHERE Name = 'RunSchedulableClassTimer'
            ];

        if(runSchedulableClassTimerList.size() > 0)
        {
            DateTime lastExecutionTime = runSchedulableClassTimerList[0].Last_Run_Time__c;

            contactRoleList =
                [
                    SELECT Id, ContactId, IsPrimary, OpportunityId
                    FROM OpportunityContactRole
                    WHERE LastModifiedDate >= :lastExecutionTime
                ];

            runSchedulableClassTimerList[0].Last_Run_Time__c = Datetime.now();
            update runSchedulableClassTimerList[0];
        }
        else
        {
            contactRoleList =
                [
                    SELECT Id, ContactId, IsPrimary, OpportunityId
                    FROM OpportunityContactRole
                ];

            RunSchedulableClassTimer__c timer = new RunSchedulableClassTimer__c();
            timer.Name = 'RunSchedulableClassTimer';
            timer.Last_Run_Time__c = Datetime.now();
            insert timer;
        }

        for(OpportunityContactRole contactRole : contactRoleList)
        {
            contactRoleIdSet.add(contactRole.OpportunityId);
        }

        /** CPQ Controls **/
        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_SetPrimaryContactSchedulable__c FROM CPQ_Controls__mdt LIMIT 1];

            if(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null){
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }

        List<Opportunity> opportunityList;

        //CPQ
        //1. if CPQ controls have not been set; 2. CPQ processing is enabled
        if(cpqRtId == null || cpqControls.Opp_C_SetPrimaryContactSchedulable__c){
            //CPQ included
            opportunityList =
            [
                    SELECT Id, Customer_Primary_Contact__c, CloseDate,
                    (
                            SELECT Id, ContactId, IsPrimary
                            FROM OpportunityContactRoles
                            WHERE IsPrimary = true
                    )
                    FROM Opportunity
                    WHERE Id IN :contactRoleIdSet
            ];
        }
        else{
            //CPQ excluded
            opportunityList =
            [
                    SELECT Id, Customer_Primary_Contact__c, CloseDate,
                    (
                            SELECT Id, ContactId, IsPrimary
                            FROM OpportunityContactRoles
                            WHERE IsPrimary = true
                    )
                    FROM Opportunity
                    WHERE Id IN :contactRoleIdSet
                    AND RecordTypeId != : cpqRtId
            ];

        }
        /** **/

        for(Opportunity opportunity : opportunityList)
        {
            opportunity.Customer_Primary_Contact__c = null;
            // You cannot update an Opportunity with a Close Date in the past
            if(opportunity.CloseDate >= Date.today() && opportunity.OpportunityContactRoles.size() > 0 && opportunity.Customer_Primary_Contact__c != opportunity.OpportunityContactRoles[0].ContactId)
            {   
                opportunity.Customer_Primary_Contact__c = opportunity.OpportunityContactRoles[0].ContactId;
                opportunityListToUpdate.add(opportunity);
            }
        }

        if(opportunityListToUpdate.size() > 0)
        {
            Database.update(opportunityListToUpdate, false);
        }
    }
}