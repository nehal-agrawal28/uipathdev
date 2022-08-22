public class QuoteLineItemHandler {

    public static void PrePopulateEndDate(List<QuoteLineItem> newList) {
        
        Set<Id> oliIds = new Set<Id>();
        for (QuoteLineItem qli : newList) {
            if (qli.OpportunityLineItemId != null) {
                oliIds.add(qli.OpportunityLineItemId);
            }
        }
        
        Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>([SELECT Id, UnitPrice,End_Date__c,Yearly_Unit_Price__c FROM OpportunityLineItem WHERE Id IN :oliIds]);
        
        for (QuoteLineItem qli : newList) {
            if (qli.OpportunityLineItemId != null) {
                if (oliMap.containsKey(qli.OpportunityLineItemId)) {
                    qli.End_Date__c = oliMap.get(qli.OpportunityLineItemId).End_Date__c;
                    qli.Sales_Price_Edited__c = oliMap.get(qli.OpportunityLineItemId).UnitPrice;
                    qli.Yearly_Unit_Price__c = oliMap.get(qli.OpportunityLineItemId).Yearly_Unit_Price__c;
                }
            }
        }
    }
    
}