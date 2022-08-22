/**
 * THIS CLASS HAS NO ORIGINAL COMMENTS OR ATTRIBUTION
 * October 2019 - Copied EditProductsController for Community
 */
public with sharing class CommunityEditProductsController 
{
    public Opportunity opportunity {get; set;} 
    public List<OLIWrapper> opportunityLineItemList {get; set;}
    public boolean showLicenseCodes {get; set;} 
      public Boolean selectPriceBook {get; set;}
      public String selectedPriceBookId {get; set;}
      public List<SelectOption> priceBookOptions {get; set;}
    public Boolean showErrorMessage {get; set;}
    public OpportunityLineItem PremiumSupport;
    public Decimal PremiumPercent;
    public Decimal PremiumCarePercent;
    public OpportunityLineItem PremiumProductCare;
    
    public CommunityEditProductsController(ApexPages.StandardController ctrl) 
    

    {
        Id opportunityId = ctrl.getId();
        selectPriceBook = false;
          selectPriceBook = false;
          selectedPriceBookId = '';

        
        showErrorMessage = false;
        PremiumSupport = new OpportunityLineItem();
        PremiumProductCare = new OpportunityLineItem();
        
        opportunityLineItemList = new List<OLIWrapper>();

        opportunity = [SELECT Id, Pricebook2Id, CurrencyIsoCode, Type, CloseDate, AccountId, Account.Maintenance_Flag__c, Account.Eligible_for_Premium_Care__c, Account.Annual_Contract_Value__c FROM Opportunity WHERE Id = :opportunityId];

        if (opportunity.Pricebook2Id == null) 
        {
              selectPriceBook = true;

              List<Pricebook2> priceBookList = 
                  [
                      SELECT Id, Name
                      FROM Pricebook2 
                      WHERE IsActive = true 
                  ];
            
              priceBookOptions = new List<SelectOption>();
              priceBookOptions.add(new SelectOption('','-- Select --'));

              for(Pricebook2 priceBook : priceBookList)
              {
                  priceBookOptions.add(new SelectOption(priceBook.Id, priceBook.Name));
              }
        } 
        else
        {           
                EditProductInit();         
    }
    
    }
    
    public void EditProductInit()
    {
        // 価格表を選択させないようにする
        if (opportunity.Pricebook2Id == null)
        {
            List<Pricebook2> priceBookList = [SELECT Id, Name FROM Pricebook2 WHERE IsActive = true LIMIT 1];
            opportunity.Pricebook2Id = priceBookList[0].Id;
            update opportunity;
        }
        
        if(OpportunityLineItem.License_Codes__c.getDescribe().isAccessible() && OpportunityLineItem.License_Codes__c.getDescribe().isUpdateable())
        {
            showLicenseCodes = true;
        }
        else
        {
            showLicenseCodes = false;
        }

        BuildProductList();

        NewProductPopup = false;
//        AddOnPopup = false; 
    }
// here start
    public void SavePriceBook()
    {
        
        if(String.isEmpty(selectedPriceBookId))
        {
            showErrorMessage = true;
            selectPriceBook = true;
        }
        else
        {
            opportunity.Pricebook2Id = selectedPriceBookId;
            try {
                update opportunity;
            } catch (Exception ex) {
                ApexPages.addMessages(ex);
                return;
            }
            showErrorMessage = false;
            selectPriceBook = false;
        }
        
    }
// here end   
    public void BuildProductList() {
        Map<Id, OLIWrapper> oppMap = new Map<Id, OLIWrapper>();
        opportunityLineItemList = new List<OLIWrapper>();
        PremiumPercent = 0;
        PremiumCarePercent = 0;
        for (OpportunityLineItem oli : [SELECT Vendor__c, Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.Premium_Care_Percentage__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Vendor__c, PricebookEntry.Product2.Apply_Premium_Percentage__c, PricebookEntry.Product2.Apply_Premium_Care__c, PricebookEntry.Product2.Premium_Percentage__c, Quantity, UnitPrice, Yearly_Unit_Price__c, Comments__c,
                                        License_Codes__c, Existing_Orchestrator__c,PricebookEntry.Product2.Price_Type__c, Discount,  Product_Version__c, ServiceDate, End_Date__c, TotalPrice, CurrencyIsoCode, Business_Type__c, ListPrice, PricebookEntry.Product2.Editable_Price__c
                                        FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id AND Add_On_For__c = null]) 
        {
            if (oli.Yearly_Unit_Price__c == null && oli.ListPrice != null) {
                oli.Yearly_Unit_Price__c = oli.ListPrice;
            }
            if(oli.PricebookEntry.Product2.Apply_Premium_Percentage__c == true)
            {
                PremiumSupport = oli;
                PremiumPercent = oli.PricebookEntry.Product2.Premium_Percentage__c;
            }
            if(oli.PricebookEntry.Product2.Apply_Premium_Care__c == true)
            {
                PremiumProductCare = oli;
                PremiumCarePercent = oli.PricebookEntry.Product2.Premium_Care_Percentage__c;
            }
            
            oppMap.put(oli.Id, new OLIWrapper(oli, opportunity));
        }
//        for (OpportunityLineItem oli : [SELECT Vendor__c, Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.Price_Type__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Vendor__c, Quantity, UnitPrice, 
//                                         License_Codes__c, Discount, Existing_Orchestrator__c,ServiceDate, End_Date__c, TotalPrice, CurrencyIsoCode, Add_On_For__c, ListPrice, PricebookEntry.Product2.Add_On_Percent__c,
//                                          Business_Type__c, Yearly_Unit_Price__c, Comments__c, PricebookEntry.Product2.Apply_Premium_Percentage__c  
//                                        FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id AND Add_On_For__c IN :oppMap.keyset()]) {
//            oppMap.get(oli.Add_On_For__c).addOns.add(new OLIAddOnWrapper(oli, oppMap.get(oli.Add_On_For__c).oli));
//        }
        
        opportunityLineItemList = oppMap.values();
        opportunityLineItemList.sort();
        
        RecalculatePrices();
    }
    
    // New Products
    public class NewProductEntry implements Comparable
    {
        public PricebookEntry pbe { get; set; }
        public boolean selected { get; set; }
        public NewProductEntry(PricebookEntry pbe) 
        {
            this.pbe = pbe;
            selected = false;
        }

        public Integer compareTo(Object compareTo) 
        {
            NewProductEntry productEntry = (NewProductEntry)(compareTo);

            if(this.pbe.Product2.Vendor__c == 'UiPath' && productEntry.pbe.Product2.Vendor__c != 'UiPath') 
            {
                return -1;
            }
            if(this.pbe.Product2.Vendor__c != 'UiPath' && productEntry.pbe.Product2.Vendor__c == 'UiPath')
            {
                return 1;
            }
            return this.pbe.Product2.Name.compareTo(productEntry.pbe.Product2.Name);
        }
    }
    public List<NewProductEntry> NewProducts { get; set; }
    public boolean NewProductPopup { get; set; }
    /**
     * This method is understood to populate the product list that is returned to a user when then initiate
     * adding a new product
     * March 2019 - modification to exclude CPQ products - any product with a true Product2/CPQ_Exclusive__c flag is assumed to be an exclusively CPQ product
     */
    public void ShowNewProduct() {
        // New products list
        NewProducts = new List<NewProductEntry>();
        for (PricebookEntry pbe : [SELECT Product2.Vendor__c, Id, UnitPrice, Product2.Price_Type__c, Product2.Apply_Premium_Percentage__c, Product2.Apply_Premium_Care__c, Product2.Premium_Care_Percentage__c, Product2.Premium_Percentage__c, Product2.Name,Product2.Description, Product2.CPQ_Exclusive__c, CurrencyIsoCode FROM PricebookEntry
                                   WHERE Pricebook2Id = :opportunity.Pricebook2Id
                                   AND CurrencyIsoCode = :opportunity.CurrencyIsoCode
                                   AND Product2.Is_Add_On__c = false
                                   AND IsActive = true
                                   AND Product2.CPQ_Exclusive__c = false
                                   AND Product2.Use_Community__c = true
                                   ]) {
                                       NewProducts.add(new NewProductEntry(pbe));
                                   }
        NewProducts.sort();
        NewProductPopup = true;
    }
    public void HideNewProduct() {
        NewProductPopup = false;
    }
    
    
    public void AddNewProduct() {
        opportunity = [SELECT Id, Pricebook2Id, CurrencyIsoCode, Type, CloseDate, AccountId, Account.Maintenance_Flag__c, Account.Eligible_for_Premium_Care__c, Account.Annual_Contract_Value__c, Contract_Start_Date__c, Contract_End_Date__c FROM Opportunity WHERE Id = :opportunity.Id];

        List<OpportunityLineItem> toInsert = new List<OpportunityLineItem>();
        Boolean insertPremium = false;
        Boolean insertPremiumCare = false;
        for (NewProductEntry npe : NewProducts) {
            if(npe.selected)
            {
                if(npe.pbe.Product2.Apply_Premium_Percentage__c == false)
                {
                    if(npe.pbe.Product2.Apply_Premium_Care__c == false)
                    {
                        OpportunityLineItem newOli = new OpportunityLineItem();
                        newOli.Add_On_For__c = null;
                        newOli.OpportunityId = opportunity.Id;
                        newOli.PriceBookEntryId = npe.pbe.Id;
                        newOli.Quantity = 1;
                        newOli.UnitPrice = npe.pbe.UnitPrice;
                        newOli.Yearly_Unit_Price__c = newOli.UnitPrice;
                        newOli.Business_Type__c = opportunity.Type;
                        //newOli.ServiceDate = opportunity.CloseDate;
                        //newOli.End_Date__c = opportunity.CloseDate.addYears(1).addDays(-1);
                        newOli.ServiceDate = opportunity.Contract_Start_Date__c;
                        newOli.End_Date__c = opportunity.Contract_End_Date__c;
                        
                        // 選択した製品がOrchestratorの場合はNoを初期値にセット
                        if (npe.pbe.Product2.Name.contains('UiPath - Orchestrator')) {
                            newOli.Existing_Orchestrator__c = 'No';
                        }
                        
                        toInsert.add(newOli);
                    } else {
                        PremiumProductCare = new OpportunityLineItem();
                        PremiumProductCare.Add_On_For__c = null;
                        PremiumProductCare.OpportunityId = opportunity.Id;
                        PremiumProductCare.PriceBookEntryId = npe.pbe.Id;
                        PremiumProductCare.Business_Type__c = opportunity.Type;
                        PremiumProductCare.Quantity = 1;
                        insertPremiumCare = true;
                        PremiumCarePercent = npe.pbe.Product2.Premium_Care_Percentage__c;
                    }
                } else {
                    
                    PremiumSupport = new OpportunityLineItem();
                    PremiumSupport.Add_On_For__c = null;
                    PremiumSupport.OpportunityId = opportunity.Id;
                    PremiumSupport.PriceBookEntryId = npe.pbe.Id;
                    PremiumSupport.Business_Type__c = opportunity.Type;
                    PremiumSupport.Quantity = 1;
                    //PremiumSupport.ServiceDate = opportunity.CloseDate;
                    //PremiumSupport.End_Date__c = opportunity.CloseDate.addYears(1).addDays(-1);
                    insertPremium = true;
                    PremiumPercent = npe.pbe.Product2.Premium_Percentage__c;
                }
            }
        }

        try {
            insert toInsert;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
            return;
        }
         
        Decimal totalAmount = 0;
        Decimal totalAmountUIPath = 0;
        List<OpportunityLineItem> OpportunityLI = [SELECT Id, PricebookEntry.Product2.Name, TotalPrice, PricebookEntry.Product2.Apply_Premium_Percentage__c, PricebookEntry.Product2.Apply_Premium_Care__c
                                           FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id];
        for (OpportunityLineItem newOli : OpportunityLI) {
            if(newOli.PricebookEntry.Product2.Apply_Premium_Percentage__c == false && newOli.PricebookEntry.Product2.Apply_Premium_Care__c == false)
                totalAmount += newOli.TotalPrice;
            if(newOli.PricebookEntry.Product2.Apply_Premium_Percentage__c == false && newOli.PricebookEntry.Product2.Apply_Premium_Care__c == false && (newOli.PricebookEntry.Product2.Name).contains('UiPath'))
                totalAmountUIPath += newOli.TotalPrice;
        }
        
        /*
        decimal consideredValue = (opportunity.Type == 'New Business') ? totalAmount : opportunity.Account.Annual_Contract_Value__c;
        if(consideredValue != null && consideredValue < 75000 && opportunity.Account.Eligible_for_Premium_Care__c == 'No' && insertPremiumCare == true) {
            
            NewProductPopup = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The customer is not eligible for Premium Care as his Annual Contract Value is below 75.000 USD'));
            
        } else {
            PremiumProductCare.UnitPrice = 0;
            if (consideredValue != null && consideredValue >= 75000 && consideredValue < 100000) {
                PremiumProductCare.UnitPrice = 12000;
            } else if (consideredValue != null && consideredValue < 500000)
      {
                
                if(opportunity.Account.Maintenance_Flag__c == 'Premium')
                    if (PremiumCarePercent != null)
                        PremiumProductCare.UnitPrice = totalAmountUIPath * PremiumCarePercent / 100;
        if((opportunity.Account.Maintenance_Flag__c == 'Standard' || opportunity.Account.Maintenance_Flag__c == '' || opportunity.Account.Maintenance_Flag__c == null) && opportunity.Account.Eligible_for_Premium_Care__c == 'Yes') { 
          if (PremiumCarePercent != null)
            PremiumProductCare.UnitPrice = consideredValue * PremiumCarePercent / 100;        
                } 
        
            }
            
            try {   
                if(PremiumProductCare.Id != null)
                    update PremiumProductCare;
                
                if(insertPremiumCare == true)
                {
                    System.debug(PremiumProductCare);
                    insert PremiumProductCare; 
                }   
                
            } catch (Exception ex) {
                ApexPages.addMessages(ex);
                return;
            }
        }*/
        
        if (opportunity.Type == 'New Business') {
            if (totalAmount >= 75000) {
                PremiumProductCare.UnitPrice = 0.12 * totalAmount;
            } else {
                NewProductPopup = false;
//              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'The customer is not eligible for Premium Care as his Annual Contract Value is below 75.000 USD'));
            }
        } else {
            if (opportunity.Account.Eligible_for_Premium_Care__c == 'Yes' && opportunity.Account.Annual_Contract_Value__c <= 100000) {
                PremiumProductCare.UnitPrice = 12000;
            } else if (opportunity.Account.Eligible_for_Premium_Care__c == 'Yes' && opportunity.Account.Annual_Contract_Value__c > 100000 && opportunity.Account.Annual_Contract_Value__c <= 1000000) {
                PremiumProductCare.UnitPrice = 0.12 * opportunity.Account.Annual_Contract_Value__c;
            } else if (opportunity.Account.Eligible_for_Premium_Care__c == 'Yes' && opportunity.Account.Annual_Contract_Value__c > 1000000) {
                PremiumProductCare.UnitPrice = 0.12 * opportunity.Account.Annual_Contract_Value__c;
            }
        }
        
        if (PremiumProductCare.UnitPrice != null) {
          PremiumProductCare.Yearly_Unit_Price__c = PremiumSupport.UnitPrice;
            try {   
                if(PremiumProductCare.Id != null)
                    update PremiumProductCare;
                
                if(insertPremiumCare == true)
                {
                    System.debug(PremiumProductCare);
                    insert PremiumProductCare; 
                }   
                
            } catch (Exception ex) {
                ApexPages.addMessages(ex);
                return;
            }
        }
        
        if (PremiumPercent != null)
          PremiumSupport.UnitPrice = totalAmount * PremiumPercent / 100;
        else 
            PremiumSupport.UnitPrice = 0;
        PremiumSupport.Yearly_Unit_Price__c = PremiumSupport.UnitPrice;
        
        try {   
            if(PremiumSupport.Id != null)
                update PremiumSupport;
            
            if(insertPremium == true)
            {
                insert PremiumSupport; 
            }   
            
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
            return;
        }
        
        
        /*for (OpportunityLineItem newOli : [SELECT Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.Price_Type__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Apply_Premium_Percentage__c , 
                                           PricebookEntry.Product2.Vendor__c, Quantity, UnitPrice, ListPrice, Business_Type__c, Yearly_Unit_Price__c, Comments__c,
                                           License_Codes__c, Discount, ServiceDate, Product_Version__c, End_Date__c, TotalPrice, CurrencyIsoCode, PricebookEntry.Product2.Add_On_Percent__c, 
                                           PricebookEntry.Product2.Editable_Price__c
                                           FROM OpportunityLineItem WHERE Id IN :toInsert]) {
             opportunityLineItemList.add(new OLIWrapper(newOli, opportunity));
            
        }*/
       
        NewProductPopup = false;
        //RecalculatePrices();
        BuildProductList();
    }
    
   
    
//    // Add Ons
//    public List<SelectOption> AddOns {
//        get {
//            Set<Id> existing = new Set<Id>();
//            for (OpportunityLineItem oli : [SELECT PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id]) {
//                existing.add(oli.PricebookEntryId);
//            }
//            
//            List<SelectOption> toReturn = new List<SelectOption>();
//            if (AddOnFor != null) {
//                List<OpportunityLineItem> olis = [SELECT PricebookEntry.Product2Id FROM OpportunityLineItem WHERE Id = :AddOnFor];
//                if (olis.size() > 0) {
//                    OpportunityLineItem oli = olis[0];
//                    for (PriceBookEntry pbe : [SELECT Id, Product2.Name FROM PricebookEntry 
//                                               WHERE Pricebook2Id = :opportunity.Pricebook2Id AND CurrencyIsoCode = :opportunity.CurrencyIsoCode AND Product2.Is_Add_On__c = true 
//                                                 AND Product2.Add_On_For__c = :oli.PricebookEntry.Product2Id AND IsActive = true AND (NOT Id IN :existing)]) {
//                        toReturn.add(new SelectOption(pbe.Id, pbe.Product2.Name));                               
//                    }
//                }
//            }
//            return toReturn;
//        }
//    }
//    public Id AddOnFor { get; set; }
//    public boolean AddOnPopup { get; set; }
//    public String selectedAddOn { get; set; }
//    public void ShowAddOn() {
//        AddOnPopup = true;
//    }
//    public void HideAddOn() {
//        AddOnPopup = false;
//    }
//    public void AddAddOn() {
//        for (OLIWrapper oliW : opportunityLineItemList) {
//            if (oliW.oli.Id == AddOnFor) {
//                OpportunityLineItem newOli = new OpportunityLineItem();
//                newOli.Add_On_For__c = AddOnFor;
//                newOli.OpportunityId = opportunity.Id;
//                newOli.PriceBookEntryId = selectedAddOn;
//                newOli.Quantity = oliW.oli.Quantity;
//                newOli.UnitPrice = 1;
//                newOli.Business_Type__c = opportunity.Type;
//                try {
//                    insert newOli;
//                } catch (Exception ex) {
//                    ApexPages.addMessages(ex);
//                    return;
//                }
//                newOli = [SELECT Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.Price_Type__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Vendor__c, Quantity, UnitPrice, Business_Type__c,
//                          License_Codes__c,Discount, ServiceDate, End_Date__c, TotalPrice, Existing_Orchestrator__c,CurrencyIsoCode, Add_On_For__c, ListPrice, PricebookEntry.Product2.Add_On_Percent__c, Yearly_Unit_Price__c, Comments__c
//                          FROM OpportunityLineItem WHERE Id = :newOli.Id];
//                oliW.addOns.add(new OliAddOnWrapper(newOli, oliW.oli));
//            }
//        }
//        AddOnPopup = false;
//        RecalculatePrices();
//    }

    public String DelOliId { get; set; }
    public void deleteRecordOnServer()
    {
        OpportunityLineItem delOli = new OpportunityLineItem();
        delOli.Id = DelOliId;
        try {
            delete delOli;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        
        if(PremiumSupport.Id != null)
        {
            List<OpportunityLineItem> PSupport = [SELECT Id FROM OpportunityLineItem WHERE Id =: PremiumSupport.Id];
            if(PSupport.size() == 1)
            {
                Decimal totalAmount = 0;
                List<OpportunityLineItem> OpportunityLI = [SELECT Id, PricebookEntry.Product2.Name, TotalPrice, PricebookEntry.Product2.Apply_Premium_Percentage__c
                                                   FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id];
                for (OpportunityLineItem newOli : OpportunityLI) {
                    if(newOli.PricebookEntry.Product2.Apply_Premium_Percentage__c == false)
                        totalAmount += newOli.TotalPrice;
                }
        
                
                PremiumSupport.UnitPrice = totalAmount * PremiumPercent / 100;
                PremiumSupport.Yearly_Unit_Price__c = totalAmount * PremiumPercent / 100;
                try {   
                    update PremiumSupport;
                } catch (Exception ex) {
                    ApexPages.addMessages(ex);
                    return;
                }
            } else {
                PremiumSupport = new OpportunityLineItem();
            }
        }
        BuildProductList();
    }
    
    public static decimal CalculatePeriod(Date startDate, Date endDate) {
        if (startDate == null || endDate == null) {
            return 0;
        }
        Date calculationDate = startDate;
        decimal yearsPassed = 0;
        while (calculationDate.addYears(1) < endDate) {
            calculationDate = calculationDate.addYears(1);
            yearsPassed += 1;
        }
        boolean overLeapYear = false;
        if (Date.isLeapYear(calculationDate.Year())) {
            Date day29 = Date.newInstance(calculationDate.Year(), 2, 29);
            if (day29 >= calculationDate && day29 <= endDate) {
                overLeapYear = true;
            } 
        }
        if (Date.isLeapYear(endDate.Year())) {
            Date day29 = Date.newInstance(endDate.Year(), 2, 29);
            if (day29 >= calculationDate && day29 <= endDate) {
                overLeapYear = true;
            } 
        }
        yearsPassed += (calculationDate.daysBetween(endDate) + 1) / (overLeapYear ? 366.0 : 365.0);
        return yearsPassed;
    }

    public PageReference saveChanges()
    {
        RecalculatePrices();
        
        List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
        for (OLIWrapper oliW : opportunityLineItemList) {
            decimal period = 1;
            if (oliW.oli.ServiceDate != null && oliW.oli.End_Date__c != null) {
                period = CalculatePeriod(oliW.oli.ServiceDate, oliW.oli.End_Date__c);
            }
            oliW.oli.Current_List_Price_Variation__c = oliW.discountedPrice - oliW.oli.ListPrice;
            toUpdate.add(oliW.oli);
//            for (OLIAddOnWrapper oliA : oliW.addOns) {
//                toUpdate.add(oliA.oli);
//            }
        }
        try {
            update toUpdate;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
        
        if(PremiumSupport.Id != null)
        {
            Decimal totalAmount = 0;
            List<OpportunityLineItem> OpportunityLI = [SELECT Id, PricebookEntry.Product2.Name, TotalPrice, PricebookEntry.Product2.Apply_Premium_Percentage__c
                                               FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id];
            for (OpportunityLineItem newOli : OpportunityLI) {
                if(newOli.PricebookEntry.Product2.Apply_Premium_Percentage__c == false)
                    totalAmount += newOli.TotalPrice;
            }
            
            PremiumSupport.UnitPrice = totalAmount * PremiumPercent / 100;
            PremiumSupport.Yearly_Unit_Price__c = totalAmount * PremiumPercent / 100;
            
            try {
                update PremiumSupport;
                
            } catch (Exception ex) {
                ApexPages.addMessages(ex);
                return null;
            }
        }
        
        return null;
    }

    public PageReference cancel()
    {
        //PageReference retURL = new PageReference(URL.getSalesforceBaseUrl().toExternalForm() + '/' + opportunity.Id);
        PageReference retURL = new PageReference('/' + opportunity.Id);
        retURL.setRedirect(true);
        return retURL;
    }
    
    public void RecalculatePrices() {
        for (OLIWrapper oliW : opportunityLineItemList) {
            if (oliW.oli.Business_Type__c == null) {
                oliW.oli.Business_Type__c = opportunity.Type;
            }
            
            if (!oliW.editable || oliW.premiumPercentage || oliW.premiumCare) {
                oliW.oli.Yearly_Unit_Price__c = oliW.oli.ListPrice;
            }
            decimal period = 1;
            if (oliW.oli.ServiceDate != null && oliW.oli.End_Date__c != null && 
                oliW.oli.PricebookEntry.Product2.Family != 'Professional Service' && oliW.oli.PricebookEntry.Product2.Family != 'Training')
            {
                period = CalculatePeriod(oliW.oli.ServiceDate, oliW.oli.End_Date__c);
            }
            if(oliW.oli.ServiceDate != null && oliW.oli.End_Date__c != null) 
                oliW.oli.UnitPrice = oliW.oli.Yearly_Unit_Price__c * period;
            
//            for (OLIAddOnWrapper addOnW : oliW.addOns) {
//                addOnW.oli.Quantity = oliW.oli.Quantity;
//                if(addOnW.oli.PricebookEntry.Product2.Add_On_Percent__c == null)
//                {
//                    addOnW.oli.PricebookEntry.Product2.Add_On_Percent__c = 0;
//                }
//                if (addOnW.addonPercentDisplay) {
//                    addOnW.oli.UnitPrice = oliW.oli.UnitPrice * addOnW.oli.PricebookEntry.Product2.Add_On_Percent__c / 100;
//                    if (oliW.oli.Discount != null) {
//                        addOnW.oli.UnitPrice *= (100 - oliW.oli.Discount) / 100;
//                    }
//                } else {
//                    addOnW.oli.UnitPrice = addOnW.oli.ListPrice;
//                }
//            }
        }
        
    }
    
    public boolean profileCanEdit {
        get {
            Set<String> profileNames = new Set<String>(Label.EditProductsPremiumEditableProfiles.split(';'));
            if (profileNames.contains([SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name)) {
                return true;
            }
            return false;
        }
    }

    public class OLIWrapper implements Comparable 
    {
        public Opportunity opportunity { get; set; }
        public OpportunityLineItem oli { get; set; }
        public boolean CommentsVisible {
            get {
                return Schema.sObjectType.OpportunityLineItem.fields.Comments__c.isUpdateable();
            }
        }
        
        public decimal discountedPrice 
        {
            get 
            {
                if (oli.UnitPrice == null)
                    return 0;
                if (oli.Discount == null)
                    return oli.UnitPrice;
                return oli.UnitPrice * (100 - oli.Discount) / 100;
            }
        }
        
        public Integer Quantity
        {
            get
            {
                return (Integer)oli.Quantity;
            }
            set
            {
                oli.Quantity = value;
            }
        }
        
        public decimal totalPrice 
        {
            get 
            {
                return discountedPrice * oli.Quantity;
            }
        }

        public boolean editable {
            get {
                try {
                    if (oli.PricebookEntry.Product2.Editable_Price__c == true)
                        return true;
                } catch (Exception ex) {}
                //if(oli.PricebookEntry.Product2.Apply_Premium_Percentage__c == true)   
                    //return false;
                if (opportunity.Type != 'New Business' && oli.PricebookEntry.Product2.Vendor__c == 'UiPath')
                    return true;
                
                return false;
            }
        }
        
        public boolean premiumPercentage {
            get {
                try {
                    if (oli.PricebookEntry.Product2.Apply_Premium_Percentage__c == true)
                        return true;
                } catch (Exception ex) {}
                return false;
            }
        }
        
        public boolean premiumCare {
            get {
                try {
                    if (oli.PricebookEntry.Product2.Apply_Premium_Care__c == true)
                        return true;
                } catch (Exception ex) {}
                
                return false;
            }
        }
        
        public boolean PremiumCareDiscount {
            get {
                try {
                    if (oli.PricebookEntry.Product2.Apply_Premium_Care__c == true && opportunity.Account.Annual_Contract_Value__c >= 500000 && (opportunity.Account.Maintenance_Flag__c == 'Standard' || opportunity.Account.Maintenance_Flag__c == '' || opportunity.Account.Maintenance_Flag__c == null))
                        return true;
                } catch (Exception ex) {}
                return false;
            }
        }
        
        
//        public List<OLIAddOnWrapper> addOns { get; set; }
        
        public OLIWrapper(OpportunityLineItem oli, Opportunity opportunity) 
        {
            this.opportunity = opportunity;
            this.oli = oli;
//            addOns = new List<OLIAddOnWrapper>();
        }

        public Integer compareTo(Object compareTo) 
        {
            OLIWrapper oliWrapper = (OLIWrapper)(compareTo);

            if(this.oli.PricebookEntry.Product2.Vendor__c == 'UiPath' && oliWrapper.oli.PricebookEntry.Product2.Vendor__c != 'UiPath') 
            {
                return -1;
            }
            if(this.oli.PricebookEntry.Product2.Vendor__c != 'UiPath' && oliWrapper.oli.PricebookEntry.Product2.Vendor__c == 'UiPath')
            {
                return 1;
            }
            return this.oli.PricebookEntry.Product2.Name.compareTo(oliWrapper.oli.PricebookEntry.Product2.Name);
        }
    }
    
//    public class OLIAddOnWrapper {
//        public OpportunityLineItem oli { get; set; }
//        public OpportunityLineItem parent { get; set; }
//        public boolean addonPercentDisplay 
//        {
//            get
//            {
//                if(oli.PricebookEntry.Product2.Price_Type__c == 'Amount')
//                    return false;
//                
//                return true;
//            }
//        }
//        public decimal totalPrice { 
//            get {
//                return this.oli.UnitPrice * this.oli.Quantity;
//            }
//        }
//        
//        public OLIAddOnWrapper(OpportunityLineItem oli, OpportunityLineItem parent) {
//            this.oli = oli; 
//            this.parent = parent;
//        }
//    }
}