@isTest
public class CasesTrigger_PPTest {
@isTest
    public static void test(){
        List<Case> caseList = new List<Case>();
        Account ac1 = new Account();
    ac1.Name = 'Unassigned Account';
    ac1.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
    ac1.BillingStreet = 'Test  Street';
    ac1.BillingCity = 'Test City';
    ac1.BillingPostalCode = '123abc';
    ac1.BillingCountry = 'Uganda';
    ac1.Country__c = 'Uganda';
    ac1.Phone = '12345678';
    ac1.Industry = 'Others';
    insert ac1;

    //Inserting Contact
    Contact con = new Contact();
    con.AccountId = ac1.id;
    con.FirstName = 'Test';
    con.LastName = String.valueOf(System.now());
    con.Email = 'test123123asd@asdawe.com';
    con.Title = 'Title';
    con.Department__c = 'IT';
    insert con;

        Case c1 = new Case();
        c1.Status ='Deal Hub Review';
        c1.Deal_Hub_Owner__c = null;
        c1.AccountId = ac1.Id;
        c1.ContactId = con.Id;
        caseList.add(c1);       
        
        Case c2 = new Case();
        c2.Status ='Legal Review';
        c2.Legal_Owner__c  = null;
        c2.AccountId = ac1.Id;
        c2.ContactId = con.Id;
        caseList.add(c2); 
        
        Case c3 = new Case();
        c3.Status ='Finance Review';
        c3.Finance_Owner__c = null;
        c3.AccountId = ac1.Id;
        c3.ContactId = con.Id;
        caseList.add(c3); 
        Test.startTest();
       Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Legal Request').getRecordTypeId();
        Case c4 = new Case();
        c4.AccountId = ac1.Id;
        c4.ContactId = con.Id;
        c4.Status ='Ready for signature';
        c4.Deal_Hub_Owner__c  = null;
        c4.RecordTypeId = devRecordTypeId;
        caseList.add(c4); 
       
        Id devRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Finance Request').getRecordTypeId();
        Case c5 = new Case();
        c5.AccountId = ac1.Id;
        c5.ContactId = con.Id;
        c5.Status ='Master Data Review';
        c5.Master_Data_Owner__c  = null;
        c5.RecordTypeId=devRecTypeId;
        caseList.add(c5); 
        
        insert caseList;
        Test.stopTest(); 
    }
}