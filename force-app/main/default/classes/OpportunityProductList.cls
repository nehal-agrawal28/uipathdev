public class OpportunityProductList {
 public List<OpportunityLineItem> listOpptyProduct{get;set;}
    public OpportunityProductList(ApexPages.StandardController con){ 
        Case cs = [Select Opportunity__c from Case where Id=:con.getid()];
        listOpptyProduct = new List<OpportunityLineItem>([Select Id, Opportunity_Product_Type__c,Comments__c,Product2.Name,UnitPrice, ServiceDate,End_Date__c, Quantity,License_Codes__c,Product_Version__c from OpportunityLineItem
                    Where OpportunityId=:cs.Opportunity__c]);    
    }
}