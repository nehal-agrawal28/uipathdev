public with sharing class QuotelineBillingSegment {
    @AuraEnabled
    public SBQQ__QuoteLine__c quoteLine;

    @AuraEnabled
    public List<Decimal> segmentAmounts;
}