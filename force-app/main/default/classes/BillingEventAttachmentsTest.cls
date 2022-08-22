/**
 * Created by roxana.anghel on 6/15/2020.
 */
@isTest
public with sharing class BillingEventAttachmentsTest {
    public static ContentDocumentLink testAttachment;
    public static ContentDocument contentVersion_1;

    public static void createTestData() {

        Account acc = new Account (
                Name = 'newAcc1',
                BillingCountry ='United Kingdom',
                Industry = 'Others'
        );
        insert acc;

        Opportunity o = new Opportunity(
            accountId = acc.id,
            StageName = 'Discovery',
            CloseDate = system.today(),
            Name = 'Test Op',
            Type = 'Upsell',
            CurrencyIsoCode = 'EUR',
            Deal_Type__c = 'Direct',
            Won_Reasons__c = 'Product Roadmap',
            LeadSource = 'Partner'
        );

            insert o;

        pse__Billing_Event__c billingEvent = new pse__Billing_Event__c (
            BE_Friendly_Name__c = 'Testing Billing Event',
            Customer_Response__c = 'Awaiting Customer Approval',
            PO_Number_Current__c = '1234567',
            pse__Date__c = System.today()
        );

        insert billingEvent;

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
        testAttachment.LinkedEntityId = billingEvent.Id;
        testAttachment.Visibility = 'AllUsers';
        testAttachment.ContentDocumentId = documents[0].Id;
        testAttachment.shareType = 'V';
        insert testAttachment;


        Case testCase = new Case(AccountId = acc.Id, Opportunity__c = o.id, Billing_Event__c = billingEvent.Id);
    }

    public static testMethod void updateRelatedCasesFileTest() {

        createTestData();
    }
}