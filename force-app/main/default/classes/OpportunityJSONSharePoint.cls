@RestResource(urlMapping='/SharePointOpportunityData') //endpoint definition > {Salesforce Base URL}/services/apexrest/SharePointOpportunityData
global with sharing class OpportunityJSONSharePoint {

    global class JSONProducts { 
        String name;
        Decimal quantity;
        global JSONProducts(String n, Decimal q) { 
            name = n; 
            quantity = q;
        }
    }
    
    global class OpportunityWrapper {
        public String id {get;set;}
        public String accountName {get;set;}
        public Decimal revenue {get;set;}
        public String acccurrency {get;set;}
        public Decimal revenueScore {get;set;}
        public String customerStage {get;set;}
        public Decimal customerScore {get;set;}
        public Decimal usedEffort {get;set;}
        public Decimal recommendedEffort {get;set;}
        public String industry {get;set;}
        public Decimal industryScore {get;set;}
        public Decimal employeeScore {get;set;}
        public Integer orders {get;set;}
        public Decimal ordersize {get;set;}
        public String lastOrderDate {get;set;}
        public List<ProductsWrapper> products {get;set;}
        public List<ProductsWrapper> expiredproducts {get;set;}
        
    }
    
    public class ProductsWrapper {
        public String name {get;set;}
        public String quantity {get;set;}
    }
    

    @HttpGet //HttpGet request
    global static OpportunityWrapper getOpportunityJSONSharePoint()
    {
        String oppId = RestContext.request.params.get('opportunityid');
        // String accountId = ApexPages.currentPage().getParameters().get('id');
        Opportunity currentOpp = [SELECT Id, CloseDate, AccountId, Account.Name, Account.CurrencyIsoCode, Account.AnnualRevenue, 
                            Account.Revenue_Score__c, Account.Customer_Stage__c, Account.Customer_Stage_Score__c, 
                            Account.Used_Effort__c, Account.Recommended_Effort__c,  Account.Industry, Account.Industry_Score__c,
                            Account.Employees_Score__c, Opportunity_Priority__c, convertCurrency(Amount) 
                                FROM Opportunity WHERE Id =:oppId];

        AccountJSONSharePoint.setRecommendedEffort(currentOpp.AccountId);
        AccountJSONSharePoint.setUsedEffort(currentOpp.AccountId);
        
        
        List<Opportunity> accOpps = [SELECT Id, CloseDate, convertCurrency(Amount)  
                                        FROM Opportunity 
                                        WHERE AccountId =: currentOpp.AccountId AND StageName = 'Closed Won Booked' 
                                        ORDER BY CloseDate DESC];
        
        Decimal orderSize = 0;
        for(Opportunity opp: accOpps){
            if(opp.Amount != null)
                orderSize += opp.Amount;
        }
        
        List<OpportunityLineItem> accProducts = [SELECT Id, Name, Quantity, Product2Id, Product2.Name, ServiceDate, End_Date__c
                            FROM OpportunityLineItem
                            WHERE OpportunityId IN: accOpps ]; 
        
        
        
        Map<String, Decimal> productsMap = new Map<String, Decimal>();
        Map<String, Decimal> productsExpiredMap = new Map<String, Decimal>();
        Date todayDate = Date.today();
        for(OpportunityLineItem oli: accProducts)
        {
            if(oli.ServiceDate <= todayDate && oli.End_Date__c >= todayDate) {
                if(!productsMap.containsKey(oli.Product2.Name)) {
                    productsMap.put(oli.Product2.Name, oli.Quantity);
                } else {
                    Decimal pQuantity = productsMap.get(oli.Product2.Name) + oli.Quantity;
                    productsMap.put(oli.Product2.Name, pQuantity);
                }
            } else {
                if(oli.End_Date__c < todayDate) {
                    if(!productsExpiredMap.containsKey(oli.Product2.Name)) {
                        productsExpiredMap.put(oli.Product2.Name, oli.Quantity);
                    } else {
                        Decimal pQuantity = productsExpiredMap.get(oli.Product2.Name) + oli.Quantity;
                        productsExpiredMap.put(oli.Product2.Name, pQuantity);
                    }
                }
            }
        }
        
        List<JSONProducts> allProducts = new List<JSONProducts>();
        for(String s: productsMap.keySet()) {
            JSONProducts x = new JSONProducts(s, productsMap.get(s));
            allProducts.add(x);
        }
        
        List<JSONProducts> allExpiredProducts = new List<JSONProducts>();
        for(String s: productsExpiredMap.keySet()) {
            JSONProducts x = new JSONProducts(s, productsExpiredMap.get(s));
            allExpiredProducts.add(x);
        }

        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject();
        gen.writeStringField('id', String.valueOf(currentOpp.Id));
        if(currentOpp.Amount != null)
            gen.writeStringField('oppAmount', String.valueOf(currentOpp.Amount));
        else
            gen.writeStringField('oppAmount', '0.00');
        
        if(currentOpp.Opportunity_Priority__c != null)
            gen.writeStringField('oppPriority', String.valueOf(currentOpp.Opportunity_Priority__c));
        else
            gen.writeStringField('oppPriority', '');
        gen.writeStringField('closeDate', String.valueOf(currentOpp.CloseDate));
        gen.writeStringField('accountName', String.valueOf(currentOpp.Account.Name));
        
        
        if(currentOpp.Account.AnnualRevenue != null)
            gen.writeStringField('revenue', String.valueOf(currentOpp.Account.AnnualRevenue));
        else
            gen.writeStringField('revenue', '0.00');
        
        gen.writeStringField('currency', String.valueOf(currentOpp.Account.CurrencyIsoCode));
        
        
        if(currentOpp.Account.Revenue_Score__c != null)
            gen.writeNumberField('revenueScore', currentOpp.Account.Revenue_Score__c);
        else
            gen.writeNumberField('revenueScore', 0);
        
        if(!String.isEmpty(currentOpp.Account.Customer_Stage__c))
            gen.writeStringField('customerStage', String.valueOf(currentOpp.Account.Customer_Stage__c));
        else
            gen.writeStringField('customerStage', '');
        
        if(currentOpp.Account.Customer_Stage_Score__c != null)
            gen.writeNumberField('customerScore', currentOpp.Account.Customer_Stage_Score__c);
        else
            gen.writeNumberField('customerScore', 0);
       
        if(currentOpp.Account.Used_Effort__c != null)
            gen.writeNumberField('usedEffort', currentOpp.Account.Used_Effort__c);
        else
            gen.writeNumberField('usedEffort', 0);
        
        if(currentOpp.Account.Recommended_Effort__c != null)
            gen.writeNumberField('recommendedEffort', currentOpp.Account.Recommended_Effort__c);
        else
            gen.writeNumberField('recommendedEffort', 0);
        
        if(!String.isEmpty(currentOpp.Account.Industry))
            gen.writeStringField('industry', String.valueOf(currentOpp.Account.Industry));
        else
            gen.writeStringField('industry', '');
        
        if(currentOpp.Account.Industry_Score__c != null)
            gen.writeNumberField('industryScore', currentOpp.Account.Industry_Score__c);
        else
            gen.writeNumberField('industryScore', 0);
        
        if(currentOpp.Account.Employees_Score__c != null)
            gen.writeNumberField('employeeScore', currentOpp.Account.Employees_Score__c);
        else
            gen.writeNumberField('employeeScore', 0);

        if(accOpps != null && accOpps.size() > 0)
        {
            gen.writeNumberField('orders', accOpps.size());
            gen.writeNumberField('ordersize', orderSize);
            gen.writeDateField('lastOrderDate', accOpps[0].CloseDate);
        } else {
            gen.writeNumberField('orders', 0);
            gen.writeNumberField('ordersize', 0);
            gen.writeStringField('lastOrderDate', 'null');
        }
        gen.writeFieldName('products');
        gen.writeObject(allProducts);
        
        gen.writeFieldName('expiredproducts');
        gen.writeObject(allExpiredProducts);
        
        gen.writeEndObject();
        // Get the JSON string.
        String oppJSON = gen.getAsString();

        //return oppJSON;
        System.debug('oppJSON ======> '+oppJSON);
        OpportunityWrapper dataToreturn = (OpportunityWrapper)JSON.deserialize(oppJSON, OpportunityWrapper.class);
        return dataToreturn;
    }
    
    /*@HttpGet //HttpGet request
    global static String getResourceBookingList() { 
        retrun Json.serialize(resourceBookingList);        
    }*/
}