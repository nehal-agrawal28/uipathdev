@isTest 
public class OpportunityAttachmentsTest {
public static ContentDocumentLink testAttachment;
public static ContentDocument contentVersion_1;

    public static void createTestData() {
        
        Account acc = new Account (
        Name = 'newAcc1',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );        
        insert acc;
        
        Opportunity o = new Opportunity();
        
       {            
            o.accountid = acc.id;
            o.StageName = 'Discovery';
            o.CloseDate = system.today();
            o.name = 'Test Op';
            o.Type = 'Upsell';
            o.CurrencyIsoCode = 'EUR';
            o.Led_by__c = 'Direct Led';
            o.Won_Reasons__c = 'Product Roadmap';
            o.Features_the_customer_liked_didn_t_like__c = 'The best products are here';
            o.Name_of_competition_last_round__c = 'We are our own competition';
            o.Name_of_our_partner__c = 'The best partner';
            o.UiPath_team_part_of_the_bid_process__c = 'The whole company';
            o.Closeout_Reason__c = 'We Won the account today!';
            o.LeadSource = 'Partner';      
            insert o;
        }
        
        list<Opportunity> oppList = new list<Opportunity>();
        oppList.add(o);
        
     //  List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentVersion contentVersion_1 = new ContentVersion();
      contentVersion_1.Title = 'Penguins';
      contentVersion_1.PathOnClient = 'Penguins.jpg';
      contentVersion_1.VersionData = Blob.valueOf('Test Content');
      contentVersion_1.IsMajorVersion = true;
       insert contentVersion_1;
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        
          
        
        testAttachment = new ContentDocumentLink();
        testAttachment.LinkedEntityId = o.Id;
        testAttachment.Visibility = 'AllUsers'; 
        testAttachment.ContentDocumentId = documents[0].Id;
        testAttachment.shareType = 'V';
            insert testAttachment;
        
        
         Case testCase = new Case(AccountId = acc.Id, Opportunity__c = o.id);
    }
    
    public static testMethod void updateRelatedCasesFileTest() {
        
        createTestData();
    }
}