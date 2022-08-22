@IsTest(isParallel=true)
public class RHX_TEST_CampaignMember {
    static testMethod void RHX_Testmethod() {

        //Create account
        Account acc1 = new Account (Name = 'newAcc1',
                                    BillingCountry ='United Kingdom',
                                    Industry = 'Others');

        insert acc1;

        Contact testContact = new Contact(FirstName = 'firstName', LastName = 'LastName', Email = 'test12312@testemail.com',accountid=acc1.Id, Department__c = 'IT');
        insert testContact;

        Campaign camp = new Campaign(
                Name = 'Test',
                IsActive = TRUE,
                Campaign_Country__c = 'United Kingdom',
                Campaign_City__c='London',
                Campaign_Name_Text__c='Test'
        );

        insert camp;

        CampaignMember newMember = new CampaignMember(ContactId = testContact.id, status='Sent', campaignid = camp.id);
        insert newMember;

        Test.startTest();
            List<sObject> sourceList = [SELECT Id FROM CampaignMember LIMIT 1];
            rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
        Test.stopTest();

    }
}