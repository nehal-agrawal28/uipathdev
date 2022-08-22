public with sharing class OpportunityProductListController {
    @AuraEnabled
    public static List<OpportunityLineItem> getProductsForOpportunity(Id oppId) {
        // Get a list of OpportunityLineItems that belong to the Opportunity with the passed ID
        List<OpportunityLineItem> olis = [SELECT Id, Product2.Name, End_Date__c, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :oppId];

        return olis;
    }
}