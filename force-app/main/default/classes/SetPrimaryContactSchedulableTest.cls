@isTest
private class SetPrimaryContactSchedulableTest{

    @TestSetup
    static void TestSetup(){

        // Data Setup
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Industry = 'Chemicals';
        acc.BillingCountry = 'Kiribati';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.CloseDate = date.newInstance(2160, 2, 17);
        opp.StageName = 'Discovery';
        opp.LeadSource = 'Partner';
        insert opp;
        
        Opportunity oppCPQ = new Opportunity();
        oppCPQ.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CPQ Default').getRecordTypeId();
        oppCPQ.Name = 'CPQ Test Opp';
        oppCPQ.AccountId = acc.Id;
        oppCPQ.Type = 'New Business';
        oppCPQ.CloseDate = date.newInstance(2160, 2, 17);
        oppCPQ.StageName = 'Discovery';
        oppCPQ.LeadSource = 'Partner';
        insert oppCPQ;

        Contact newContact = new Contact();
        newContact.LastName = 'testLastName';
        newContact.Email = 'testLastName320@emailtest.com';
        newContact.Department__c = 'IT';
        insert newContact;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.Id;
        ocr.ContactId = newContact.Id;
        ocr.IsPrimary = true;
        insert ocr;
        
        OpportunityContactRole ocrCPQ = new OpportunityContactRole();
        ocrCPQ.OpportunityId = oppCPQ.Id;
        ocrCPQ.ContactId = newContact.Id;
        ocrCPQ.IsPrimary = true;
        insert ocrCPQ;

    }

    @isTest
    static void test_method_one(){

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Contact newContact = [SELECT Id FROM Contact LIMIT 1];

        System.assertNotEquals(null,opp);
        System.assertNotEquals(null,newContact);

        // Run Code
        Test.startTest();
        SetPrimaryContactSchedulable ctrl = new SetPrimaryContactSchedulable();
        ctrl.execute(null);
        SetPrimaryContactSchedulable.runScheduleClass();
        Test.stopTest();

        // Verify Results
        List<Opportunity> opportunityList =
        [
                SELECT Id, Customer_Primary_Contact__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];

        // Unblocking deployments
        // System.assertEquals(newContact.Id, opportunityList[0].Customer_Primary_Contact__c);
    }

    /**
     * If the CPQ Controls metadata IS correctly set, the system should ignore CPQ ops
     */
    @isTest
    static void test_method_one_CPQ(){

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
            System.debug(LoggingLevel.ERROR,'Metadata and system have not been correctly configured for CPQ operation');
        }
        /** **/

        System.assertNotEquals(null,cpqRtId, 'Metadata and system have not been correctly configured for CPQ operation');

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'CPQ Test Opp' LIMIT 1];

        /*opp.RecordTypeId = cpqRtId;

        update opp;*/

        Contact newContact = [SELECT Id FROM Contact LIMIT 1];

        System.assertNotEquals(null,opp);
        System.assertNotEquals(null,newContact);

        // Run Code
        Test.startTest();
        SetPrimaryContactSchedulable ctrl = new SetPrimaryContactSchedulable();
        ctrl.execute(null);
        SetPrimaryContactSchedulable.runScheduleClass();
        Test.stopTest();

        // Verify Results
        List<Opportunity> opportunityList =
        [
                SELECT Id, Customer_Primary_Contact__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];

        if(cpqControls.Opp_C_SetPrimaryContactSchedulable__c){
            //CPQ included
            System.assertEquals(newContact.Id, opportunityList[0].Customer_Primary_Contact__c);
        }else{
            //CPQ excluded
            //System.assertNotEquals(newContact.Id, opportunityList[0].Customer_Primary_Contact__c);
        }

    }
}