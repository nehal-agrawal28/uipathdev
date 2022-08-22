@isTest
private class TestManaged_ClauseStepTrigger { 
    private static testMethod void Test_Managed_ClauseStepTrigger () { 
        try{
            APXT_Redlining__Managed_Clause__c cso = new APXT_Redlining__Managed_Clause__c(); 
            insert cso; 
            update cso; 
            delete cso;  
        }catch(Exception e){
            FSTR.COTestFactory.FillAllFields=true;
            APXT_Redlining__Managed_Clause__c cso = (APXT_Redlining__Managed_Clause__c)FSTR.COTestFactory.createSObject('APXT_Redlining__Managed_Clause__c',true);
            insert cso; 
            update cso; 
            delete cso;  
        }
    } 
}