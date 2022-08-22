/**
 * Created by roxana.anghel on 6/15/2020.
 * Used to display attachments from Billing Events on a visualforce page that will sit on the finance case layout
 */

public with sharing class BillingEventAttachments {



    public List<ContentDocumentLink> contentDocumentLinks {get; set;}

    private final Case c;

    public BillingEventAttachments(ApexPages.StandardController stdController) {

        this.c = (Case)stdController.getRecord();

        contentDocumentLinks = [SELECT Id, ContentDocumentId ,ContentDocument.title,ContentDocument.LastModifiedDate, LinkedEntityId FROM ContentDocumentLink
        WHERE LinkedEntityId IN (SELECT Billing_Event__c FROM Case WHERE Id =: c.Id) AND LinkedEntity.Type = 'pse__Billing_Event__c'];
    }


    public list <ContentDocumentLink> getfile() {

        return contentDocumentLinks;
    }
}