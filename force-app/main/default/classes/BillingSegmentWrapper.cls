/**
* @author:   Slalom
* @date:    20/10/2020
* @description: Wrapper class for billingSegmentBreakdown LWC
*/

public class BillingSegmentWrapper{

    @AuraEnabled
    public SBQQ__Quote__c quote;

    @AuraEnabled
    public List<Billing_Segment__c> billingSegments;
    
    @AuraEnabled
    public List<QuotelineBillingSegment> qlSegmentsList;

    @AuraEnabled
    public Decimal quoteTotalAmount;

    @AuraEnabled
    public Contract contract;

    @AuraEnabled
    public String contractAnniversary;

    @AuraEnabled
    public String errorMessage;

    public BillingSegmentWrapper(){
        billingSegments = new List<Billing_Segment__c>();
        qlSegmentsList = new List<QuotelineBillingSegment>();
        quoteTotalAmount = 0;
    }
}