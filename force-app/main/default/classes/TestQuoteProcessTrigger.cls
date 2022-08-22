@isTest
private class TestQuoteProcessTrigger { 
    private static testMethod void Test_QuoteProcessTrigger () { 
        try{
            SBQQ__Quote__c fw = new SBQQ__Quote__c(); 
            insert fw; 
            System.assertNotEquals(null, fw.id); 
            update fw; 
            delete fw;
        } catch(Exception e){
            FSTR.COTestFactory.FillAllFields=true;
            SBQQ__Quote__c fw = (SBQQ__Quote__c)FSTR.COTestFactory.createSObject('SBQQ__Quote__c',true); 
            insert fw; 
            System.assertNotEquals(null, fw.id); 
            update fw; 
            delete fw;
        }
    } 
}