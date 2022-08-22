@IsTest(isParallel=true)
public class LeadSetOwnerBatchTest
{
   
     @isTest
    public static void trstLeadSetOwnerBatch()
    {
        //create leads
        Id recordTypeBPId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Business_Partner_Onboarding').getRecordTypeId();
        Id recordTypeAAId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Academic_Alliance').getRecordTypeId();
        Id recordTypeTAId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Technology_Alliance').getRecordTypeId();
        
        List<Lead> leads = new List<Lead>{
        new Lead(
            LastName = 'Test',
            Company = 'Google',
            Country = 'United States',
            Industry = 'Insurance',
            Progressed_to_MQL__c = true,
            Status = 'Working',
            Email = 'joe@NOT.com',
            Last_Change_Status_Date__c = (Date.Today()).addDays(-1),
            
            First_Contact_Us_Date__c = Date.Today(),
            Disable_Owner_Change__c = false),
        new Lead(
            LastName = 'Test',
            Company = 'Apple',
            website = 'http://www.apple.com',
            Country = 'United States',
            Industry = 'Insurance',
            RecordTypeId = recordTypeBPId,
            Email = 'joe@apple.com',
            Status='New',
            
            Last_Change_Status_Date__c = (Date.Today()).addDays(-1),
            Disable_Owner_Change__c = false,
            First_Contact_Us_Date__c = Date.Today(),
            Progressed_to_MQL__c = true),
        new Lead(
            LastName = 'Test',
            Company = 'Dummy',
            Country = 'Macao',
            Industry = 'Insurance',
            Last_Change_Status_Date__c = (Date.Today()).addDays(-1),
            Disable_Owner_Change__c = false,
            First_Contact_Us_Date__c = Date.Today(),
            Status='New',
            Email = 'joe.test@testjoe.com'),
        new Lead(
            LastName = 'Test',
            Company = 'NewT',
            Country = 'Romania',
            Progressed_to_MQL__c = true,
            Industry = 'Insurance',
            RecordTypeId = recordTypeAAId,
            Status='New',
            Last_Change_Status_Date__c = (Date.Today()).addDays(-1),
            Disable_Owner_Change__c = false,
            First_Contact_Us_Date__c = Date.Today(),
            Email = 'new2.test@nt.com'),
        new Lead(
            LastName = 'Test2',
            Company = 'NewS',
            Country = 'China',
            Industry = 'Insurance',
            Status='New',
            Last_Change_Status_Date__c = (Date.Today()).addDays(-1),
            Email = 'newtest@testnnew.com' ,
            RecordTypeId = recordTypeTAId,
            
            Disable_Owner_Change__c = false,
            Website = 'http://www.testnnew.com/ro/longurl'),
        new Lead(
            LastName = 'Test2',
            Company = 'NewS',
            Country = 'China',
            Industry = 'Insurance',
            RecordTypeId = recordTypeBPId,
            Status='New',
            Progressed_to_MQL__c = true,
            Last_Change_Status_Date__c = (Date.Today()).addDays(-2),
            Disable_Owner_Change__c = false,
            First_Contact_Us_Date__c = Date.Today(),
            Email = 'newtest@testnnew.com')};


        //inserting three at a time to check bulk logic
        insert leads;
        
        
        
        List<Lead> allLeads = [SELECT Id,LastName , Territory__c ,Status, OwnerId, Owner.Name, RecordType.Name, Last_Change_Status_Date__c, No_of_days_in_current_status__c, Disable_Owner_Change__c FROM Lead];
        for(Lead l: allLeads)
            l.Last_Change_Status_Date__c = (Date.Today()).addDays(-1);
        update allLeads;
        
        for(Lead l: allLeads) {
             system.debug('l.RecordType.Name =====> ' + l.RecordType.Name);
             system.debug('l.Owner.Name =====> ' + l.Owner.Name);
             system.debug('l.Territory__c =====> ' + l.Territory__c );
        }
        
        Test.startTest();
            LeadSetOwnerBatch lso = new LeadSetOwnerBatch();
            database.executeBatch(lso);  
        Test.stopTest();
        
        List<Lead> allUpdatedLeads = [SELECT Id, Status, OwnerId, Territory__c, Owner.Name, Country, Disable_Owner_Change__c, RecordTypeId, RecordType.Name FROM Lead WHERE Disable_Owner_Change__c = true];
        /*system.debug('allUpdatedLeads  =====> ' + allUpdatedLeads );
        for(Lead l: allUpdatedLeads ) {
             system.debug('l.Status =====> ' + l.Status);
             system.debug('l.Country =====> ' + l.Country);
             system.debug('l.RecordType.Name =====> ' + l.RecordType.Name);
             system.debug('l.Owner.Name =====> ' + l.Owner.Name);
             system.debug('l.Territory__c =====> ' + l.Territory__c );
         }*/
        System.AssertEquals(1, allUpdatedLeads.size());
    }
}