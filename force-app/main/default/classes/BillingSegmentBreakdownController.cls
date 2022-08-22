/**
* @author:   Slalom
* @date:     20/10/2020
* @description: Controller for billingSegmentBreakdown LWC
*/
public with sharing class BillingSegmentBreakdownController {
    /**
    *  @description: Wired method that returns Segmentation Data to LWC
    *  @param:      Id quoteId                       Id of current quote on LWC
    *  @return:      BillingSegmentWrapper wrapper    Wrapper that contains all Segmentation data of Quote
    */
    @AuraEnabled(cacheable=true)
    public static BillingSegmentWrapper getSegmentationData(Id quoteId) {
        List<SBQQ__Quote__c> quote = getQuote(quoteId);

        //System.debug('BillingSegmentBreakdownController : getSegmentationData : Quote ' + quote.get(0));
        //System.debug('BillingSegmentBreakdownController : getSegmentationData : Lineitems ' + quote[0].SBQQ__LineItems__r);

        BillingSegmentationCalculation bsc = new BillingSegmentationCalculation();
        bsc.calculateSegments(quote.get(0), quote[0].SBQQ__LineItems__r);
        
        return bsc.wrapper;
    }

    /**
    *  @description: Given a Quote Id, returns Quote and QuoteLine items 
    *  @param:      Id quoteId              Id of current quote on LWC
    *  @return:     List<SBQQ__Quote__c>    Quote with Quoteline Items
    */
    public static List<SBQQ__Quote__c> getQuote(Id quoteId){
        return [SELECT Id, 
                    Name, 
                    SBQQ__BillingFrequency__c,
                    First_Anniversary_Date__c,
                    SBQQ__StartDate__c,
                    SBQQ__EndDate__c, 
                    Quote_Duration__c,
                    SBQQ__NetAmount__c,
                    SBQQ__Type__c,
                    SBQQ__MasterContract__c, 
                    CurrencyIsoCode,
                    Quote_Duration_YMD__c,
                        (SELECT Id, 
                        SBQQ__Product__r.Name,
                        SBQQ__EffectiveStartDate__c,
                        SBQQ__EffectiveEndDate__c,
                        SBQQ__NetTotal__c,
                        SBQQ__Number__c,
                        SBQQ__Dimension__c,
                        SBQQ__ProrateMultiplier__c,
                        SBQQ__SubscriptionPricing__c
                        FROM SBQQ__LineItems__r 
                        ORDER BY SBQQ__Number__c ASC)
                    FROM SBQQ__Quote__c  
                    WHERE Id = :quoteId
                ];
    }
}