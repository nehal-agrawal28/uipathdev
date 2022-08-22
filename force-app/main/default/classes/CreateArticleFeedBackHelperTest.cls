@IsTest(isParallel=true)
public with sharing class CreateArticleFeedBackHelperTest {

    public static TestMethod void testMethod1(){
        Account newAccount = new Account();
        newAccount.Name =  'Unassigned Account';
        newAccount.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
        newAccount.BillingStreet = 'Test  Street';
        newAccount.BillingCity = 'Test City';
        newAccount.BillingPostalCode = '123abc';
        newAccount.BillingCountry = 'United Kingdom';
        newAccount.Phone = '12345678';
        newAccount.Industry = 'Others';
        Id csmUserId;
        try {
            csmUserId = [SELECT Id FROM User WHERE Profile.Name = 'Customer Success Manager' AND IsActive = TRUE LIMIT 1].Id;
        } catch (Exception e) {
            csmUserId = UserInfo.getUserId();
        }
        newAccount.CSM__c = csmUserId;
        insert newAccount;
        
        //Inserting Contact
        Contact newContact = new Contact();
        newContact.AccountId = newAccount.id;
        newContact.FirstName = 'Test';
        newContact.LastName = String.valueOf(System.now());
        newContact.Email = 'test123123asd@asdawe.com';
        newContact.Title = 'Title';
        newContact.Department__c = 'IT';
        insert newContact;
        
        List<Case> casesToInsert = new List<Case>();
        //Inserting Case
        Case newCase = new Case();
        newCase.RecordTypeId = CaseMetadata_SV.IncidentRecordType;
        newCase.AccountId = newAccount.Id;
        newCase.ContactId = newContact.Id;
        newCase.Status = 'New';
        casesToInsert.add(newCase);
        
        Case newCase1 = new Case();
        newCase1.RecordTypeId = CaseMetadata_SV.IncidentRecordType;
        newCase1.AccountId = newAccount.Id;
        newCase1.ContactId = newContact.Id;
        newCase1.Status = 'Customer Action';
        casesToInsert.add(newCase1);
        
        insert casesToInsert;

        test.startTest();
        List<FeedItem> fiList = new List<FeedItem>();
        
        FeedItem fi = new feeditem();
        fi.ParentId = newCase.Id;
        fi.Body = 'Test comment';
        fiList.add(fi);
        
        FeedItem fi1 = new feeditem();
        fi1.ParentId = newCase1.Id;
        fi1.Body = 'Test comment';
        fiList.add(fi1);
        
        insert fiList;

        Map<Id,Case> checkCase = new Map<Id, Case>([Select id,status from Case]);
        system.assertEquals(checkCase.get(newCase.Id).Status,'New');
        system.assertEquals(checkCase.get(newCase1.Id).Status,'In Process');
        test.stopTest();
    }

}