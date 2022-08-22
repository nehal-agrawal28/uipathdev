/**
* @author Slalom
* @date 11/09/2020
* @description Event listeners for Subscription Trigger.
*/
public without sharing class CPQSubscriptionTriggerHandler extends TriggerHandler{
    /** 
    * TriggerContext override
    */
    public override void beforeInsert(){
        updateSubscriptionFields(null, trigger.new);
        processAdditionalDiscountPercent(trigger.new);
    }
    public override void beforeUpdate(){
        updateSubscriptionFields(trigger.oldMap,trigger.new);
        processAdditionalDiscountPercent(trigger.new);
    }

    
    /** 
    * @Description: Update the  License Code field on Subscription from related order product.
    */
    private void updateSubscriptionFields(Map<Id, SObject> oldMap, List<SObject> newList){  
        //initialisze map 
        Map<Id,SBQQ__Subscription__c> oldSubscriptionMap = oldMap != null ? (Map<Id,SBQQ__Subscription__c>)oldMap : null;
        list<SBQQ__Subscription__c> newSubscriptionList = (list<SBQQ__Subscription__c>)newList;
        
        // Populate License_Codes__c field from related Order Product record
        Map<id,SBQQ__Subscription__c>  subsToProcessMap = new  Map<id,SBQQ__Subscription__c>();
        Set<Id> orderProductIds = new Set<Id>();
        for(SBQQ__Subscription__c sub : newSubscriptionList){
            if (sub.SBQQ__OrderProduct__c != null && sub.License_Codes__c == null) {
                subsToProcessMap.put(sub.id, sub);
                orderProductIds.add(sub.SBQQ__OrderProduct__c);
            }
        }
        if(!subsToProcessMap.isEmpty()){
            // Update the License_Codes__c on Subscription 
            this.updateLicenseCodeOnSubscription(subsToProcessMap,orderProductIds);
        }
    }

    /** 
    * @Description: Set License Code on Subscription from related Order Product record
    */
    private void updateLicenseCodeOnSubscription(Map<Id, SBQQ__Subscription__c> newSubscriptionMap , set<Id> orderProductIds){
        //Query Order product to get License code.
        Map<id, OrderItem> orderItemMap = new Map<id, OrderItem>([SELECT id, License_Codes__c FROM OrderItem WHERE ID IN: orderProductIds]);
        for(SBQQ__Subscription__c Sub : newSubscriptionMap.values()){
                //set subsctiption license code equals to Order product license code.
                newSubscriptionMap.get(sub.id).License_Codes__c = orderItemMap.get(sub.SBQQ__OrderProduct__c).License_Codes__c;    
         }
    }

    /**
	 * Populate additional discount percent from additional discount amount
	 */
	private void processAdditionalDiscountPercent(List<SObject> newList) {
        List<SBQQ__Subscription__c> subToCheckForQuoteLevelDiscount = new List<SBQQ__Subscription__c>();
        Map<Id, SBQQ__QuoteLine__c> quoteLinesToFetch = new Map<Id, SBQQ__QuoteLine__c> ();

		for (SBQQ__Subscription__c sub : (List<SBQQ__Subscription__c>) newList) {
            if (
                sub.SBQQ__AdditionalDiscountAmount__c != null &&
                sub.SBQQ__AdditionalDiscountAmount__c != 0 &&
                sub.SBQQ__ProrateMultiplier__c > 0 &&
                sub.SBQQ__Quantity__c > 0 &&
                sub.SBQQ__SpecialPrice__c > 0
            ) {
				Decimal discountPercentage =
					(((sub.SBQQ__RegularPrice__c - sub.SBQQ__CustomerPrice__c) / sub.SBQQ__ProrateMultiplier__c) /
					(sub.SBQQ__SpecialPrice__c)) * 100;
                
                sub.SBQQ__Discount__c = discountPercentage;
                sub.SBQQ__AdditionalDiscountAmount__c = null;
            }
            else if(sub.SBQQ__AdditionalDiscountAmount__c == null && sub.SBQQ__Discount__c == null && sub.SBQQ__QuoteLine__c != null){
                subToCheckForQuoteLevelDiscount.add(sub);
                quoteLinesToFetch.put(sub.SBQQ__QuoteLine__c, null);
            }
        }
        additionalDiscountFromQuoteHeader(subToCheckForQuoteLevelDiscount, quoteLinesToFetch);
    }
    private void additionalDiscountFromQuoteHeader(List<SBQQ__Subscription__c> subList, Map<Id, SBQQ__QuoteLine__c> quoteLinesToFetch){
        if(subList.size() > 0){
            quoteLinesToFetch = new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, SBQQ__Quote__r.SBQQ__CustomerDiscount__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :quoteLinesToFetch.keyset()
            ]);

            for(SBQQ__Subscription__c sub : subList){
                if(quoteLinesToFetch.containsKey(sub.SBQQ__QuoteLine__c)){
                    Decimal quoteAddDisc = quoteLinesToFetch.get(sub.SBQQ__QuoteLine__c).SBQQ__Quote__r.SBQQ__CustomerDiscount__c;
                    if( quoteAddDisc != null){
                        sub.SBQQ__Discount__c = quoteAddDisc;
                    }
                }
            }
        }
    }
}