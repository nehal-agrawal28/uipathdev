@RestResource(urlMapping='/SharePointAccountData') //endpoint definition > {Salesforce Base URL}/services/apexrest/SharePointAccountData
global with sharing class AccountJSONSharePoint {

    /*public Account acct;
    
    public AccountJSONSharePoint(ApexPages.StandardController stdController) { 
        this.acct = (Account)stdController.getRecord();
    }*/

    global class JSONProducts { 
        String name;
        Decimal quantity;
        Date enddate;
        
        global JSONProducts(String n, Decimal q, Date ed) { 
            name = n; 
            quantity = q;
            enddate = ed;
            
        }
    }
    
    global class AccountWrapper {
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
        public Integer employeeISP {get;set;}
        public List<ProductsWrapper> products {get;set;}
        public List<ProductsWrapper> expiredproducts {get;set;}
        
    }
    
    public class ProductsWrapper {
        public String name {get;set;}
        public String quantity {get;set;}
        public String enddate {get;set;}
       
    }
    

    @HttpGet //HttpGet request
    global static AccountWrapper getAccountJSONSharePoint()
    {
        String accountId = RestContext.request.params.get('accountid');

        AccountJSONSharePoint.setRecommendedEffort(accountId);
        AccountJSONSharePoint.setUsedEffort(accountId);

        // String accountId = ApexPages.currentPage().getParameters().get('id');
        Account currentAccount = [SELECT Id, Name, CurrencyIsoCode, Recommended_Effort__c, AnnualRevenue, Revenue_Score__c, Customer_Stage__c, Customer_Stage_Score__c, 
                            Used_Effort__c,  Industry, Industry_Score__c, Employees_Score__c, NumberOfEmployees
                            FROM Account WHERE Id =: accountId LIMIT 1];
        
        List<Opportunity> accOpps = [SELECT Id, CloseDate, CurrencyIsoCode, convertCurrency(Amount) 
                                        FROM Opportunity 
                                        WHERE AccountId =: accountId  AND StageName = 'Closed Won Booked' 
                                        ORDER BY CloseDate DESC];
        
        Decimal orderSize = 0;
        for(Opportunity opp: accOpps){
            if(opp.Amount != null) 
                orderSize += opp.Amount;
 
        }
        
        List<OpportunityLineItem> accProducts = [SELECT Id, Name, Quantity, Product2Id, Product2.Name, ServiceDate, End_Date__c
                            FROM OpportunityLineItem
                            WHERE OpportunityId IN: accOpps ]; 
        
        List<SBQQ__Subscription__c> allSubsctiptions = [SELECT Id, SBQQ__Product__c, SBQQ__Product__r.Name, SBQQ__TerminatedDate__c, SBQQ__EndDate__c FROM SBQQ__Subscription__c WHERE SBQQ__Account__c =: accountId];
        Map<String, SBQQ__Subscription__c> SubscriptionMap = new Map<String, SBQQ__Subscription__c>();
        for(SBQQ__Subscription__c subs: allSubsctiptions)
            SubscriptionMap.put(subs.SBQQ__Product__r.Name, subs);
            
        List<Asset> allAssets = [SELECT Id, Product2Id, Product2.Name, End_Date__c /*SBQQ__SubscriptionEndDate__c*/ FROM Asset WHERE AccountId =: accountId];
        Map<String, Asset> AssetsMap = new Map<String, Asset>();
        for(Asset asst: allAssets)
            AssetsMap.put(asst.Product2.Name, asst);
        
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
            Date endDateSubs = null;
            if(SubscriptionMap.containsKey(s))
                endDateSubs = SubscriptionMap.get(s).SBQQ__EndDate__c;//SBQQ__TerminatedDate__c
            if(endDateSubs == null && AssetsMap.containsKey(s) )
                endDateSubs = AssetsMap.get(s).End_Date__c; 
            
            JSONProducts x = new JSONProducts(s, productsMap.get(s), endDateSubs);
            allProducts.add(x);
        }
        
        List<JSONProducts> allExpiredProducts = new List<JSONProducts>();
        for(String s: productsExpiredMap.keySet()) {
            JSONProducts x = new JSONProducts(s, productsExpiredMap.get(s), null);
            allExpiredProducts.add(x);
        }
        
        
        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject();
        gen.writeStringField('id', String.valueOf(accountId));
        gen.writeStringField('accountName', String.valueOf(currentAccount.Name));
        if(currentAccount.AnnualRevenue != null)
            gen.writeNumberField('revenue', currentAccount.AnnualRevenue);
        else
            gen.writeNumberField('revenue', 0.0);
        
        gen.writeStringField('currency', String.valueOf(currentAccount.CurrencyIsoCode));
        
        
        if(currentAccount.Revenue_Score__c != null)
            gen.writeNumberField('revenueScore', currentAccount.Revenue_Score__c);
        else
            gen.writeNumberField('revenueScore', 0);
        
        if(!String.isEmpty(currentAccount.Customer_Stage__c))
            gen.writeStringField('customerStage', String.valueOf(currentAccount.Customer_Stage__c));
        else
            gen.writeStringField('customerStage', '');
        
        if(currentAccount.Customer_Stage_Score__c != null)
            gen.writeNumberField('customerScore', currentAccount.Customer_Stage_Score__c);
        else
            gen.writeNumberField('customerScore', 0);
       
        if(currentAccount.Used_Effort__c != null)
            gen.writeNumberField('usedEffort', currentAccount.Used_Effort__c);
        else
            gen.writeNumberField('usedEffort', 0);

        if(currentAccount.Recommended_Effort__c != null)
            gen.writeNumberField('recommendedEffort', currentAccount.Recommended_Effort__c);
        else
            gen.writeNumberField('recommendedEffort', 0);
        
        if(!String.isEmpty(currentAccount.Industry))
            gen.writeStringField('industry', String.valueOf(currentAccount.Industry));
        else
            gen.writeStringField('industry', '');
        
        if(currentAccount.Industry_Score__c != null)
            gen.writeNumberField('industryScore', currentAccount.Industry_Score__c);
        else
            gen.writeNumberField('industryScore', 0);
        
        if(currentAccount.Employees_Score__c != null)
            gen.writeNumberField('employeeScore', currentAccount.Employees_Score__c);
        else
            gen.writeNumberField('employeeScore', 0);

        if(currentAccount.NumberOfEmployees != null)
            gen.writeNumberField('employeeISP', currentAccount.NumberOfEmployees);
        else
            gen.writeNumberField('employeeISP', 0);

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
        String accountJSON = gen.getAsString();

        //return accountJSON;
        //System.debug('accountJSON ======> '+accountJSON);
        AccountWrapper dataToreturn = (AccountWrapper)JSON.deserialize(accountJSON, AccountWrapper.class);
        return dataToreturn;
    }
     
    /*@HttpGet //HttpGet request
    global static String getResourceBookingList() { 
        retrun Json.serialize(resourceBookingList);        
    }*/
    

    // ============================================================================
    // added by Mirela Chituc - 11/5/2019 ========================================
    // Set up Recommended Effort - before update
    // Raghu org-cleanup : refactored and moved code from Account trigger 
    // ============================================================================
    public static void setRecommendedEffort(Id accId) {

        if(accId == null) return;

        Account acc = [SELECT Id, Name, Revenue_Score__c, Employees_Score__c, Industry_Score__c, Customer_Stage_Score__c, 
                                Customer_Stage__c, Recommended_Effort__c
                            FROM Account 
                            WHERE Id = :accId];
        
        Decimal CustomerScore = ((acc.Revenue_Score__c + acc.Employees_Score__c)/2 + acc.Industry_Score__c + acc.Customer_Stage_Score__c)/3;

        if((acc.Customer_Stage__c != null) || (CustomerScore != null) ) {
            if(acc.Customer_Stage__c == 'Prove') {
                if(CustomerScore >= 1 && CustomerScore <= 4)
                    acc.Recommended_Effort__c = 26;
                if(CustomerScore > 4 && CustomerScore <= 7)
                    acc.Recommended_Effort__c = 34;
                if(CustomerScore > 7 && CustomerScore <= 10)
                    acc.Recommended_Effort__c = 40;
            }
            if(acc.Customer_Stage__c == 'Establish') {
                if(CustomerScore >= 1 && CustomerScore <= 4)
                    acc.Recommended_Effort__c = 28;
                if(CustomerScore > 4 && CustomerScore <= 7)
                    acc.Recommended_Effort__c = 32;
                if(CustomerScore > 7 && CustomerScore <= 10)
                    acc.Recommended_Effort__c = 36;
            }
            if(acc.Customer_Stage__c == 'Expand') {
                if(CustomerScore >= 1 && CustomerScore <= 4)
                    acc.Recommended_Effort__c = 26;
                if(CustomerScore > 4 && CustomerScore <= 7)
                    acc.Recommended_Effort__c = 30;
                if(CustomerScore > 7 && CustomerScore <= 10)
                    acc.Recommended_Effort__c = 36;
            }
            if(acc.Customer_Stage__c == 'Scale') {
                if(CustomerScore >= 1 && CustomerScore <= 4)
                    acc.Recommended_Effort__c = 34;
                if(CustomerScore > 4 && CustomerScore <= 7)
                    acc.Recommended_Effort__c = 40;
                if(CustomerScore > 7 && CustomerScore <= 10)
                    acc.Recommended_Effort__c = 44;
            }
            if(acc.Customer_Stage__c == 'Conversion') {
                if(CustomerScore >= 1 && CustomerScore <= 4)
                    acc.Recommended_Effort__c = 30;
                if(CustomerScore > 4 && CustomerScore <= 7)
                    acc.Recommended_Effort__c = 38;
                if(CustomerScore > 7 && CustomerScore <= 10)
                    acc.Recommended_Effort__c = 44;
            }
        }
        
        update acc;                        
    }
    
    // ============================================================================
    // added by Mirela Chituc - 10/23/2019 ========================================
    // Set up Used Effort - before update
    // Raghu org-cleanup : refactored and moved code from Account trigger 
    // ============================================================================
    public static void setUsedEffort(Id accId) {
        
        if(accId == null) return;

        Account acc = [SELECT Id, Name, Used_Effort__c
                            FROM Account 
                            WHERE Id = :accId];

        Set<String> allTypes = new Set<String>{'Workshop', 'POC', 'Demo'};
        List<Pre_Sales_Tasks__c> allCurrentPSTasks = [SELECT Id, Opportunity__c, Opportunity__r.AccountId, Duration_in_hours__c
                                                FROM Pre_Sales_Tasks__c WHERE Opportunity__r.AccountId = :accId AND Type__c IN :allTypes];
                                                
        if(allCurrentPSTasks.size() > 0) {
            Map<Id, Decimal> preSalesDurationByAccountMap = new Map<Id, Decimal>();
            
            for(Pre_Sales_Tasks__c pSales: allCurrentPSTasks){
                if(pSales.Duration_in_hours__c != null) {
                    
                    if(!preSalesDurationByAccountMap.containsKey(pSales.Opportunity__r.AccountId)) { 
                        preSalesDurationByAccountMap.put(pSales.Opportunity__r.AccountId, pSales.Duration_in_hours__c);
                    } 
                    else {
                        Decimal totalDuration = preSalesDurationByAccountMap.get(pSales.Opportunity__r.AccountId);
                        totalDuration += pSales.Duration_in_hours__c;
                        preSalesDurationByAccountMap.put(pSales.Opportunity__r.AccountId, totalDuration);
                    }
                }
            }
        
            if(preSalesDurationByAccountMap.containsKey(accId)){
                acc.Used_Effort__c = preSalesDurationByAccountMap.get(acc.Id);

                update acc;
            }
        }                                
    }
}