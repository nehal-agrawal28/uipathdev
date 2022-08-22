/**
 * Created by paul.bircham on 2019-05-16.
 */

@IsTest
private class CPQQuoteContractedPricesServiceTest {


    @TestSetup
    static void testSetup(){

        /** CPQ Controls **/
        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Case_C_CaseTriggerHandler__c FROM CPQ_Controls__mdt LIMIT 1];

            if(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null){
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }
        /** **/

        Account acc = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1,true);

        acc.SBQQ__CONTRACTCOTERMINATION__C = 'Never';
        acc.SBQQ__RENEWALPRICINGMETHOD__C = 'Same';
        acc.SBQQ__TAXEXEMPT__C='No';
        //acc.GLOBAL_ACCOUNT_ID__C= ' ACC-00044530';
        acc.DEFAULT_PAYMENT_TERMS__C = '30 Days Net';
        acc.VAT_NUMBER__C = '1234567';

        update acc;



        Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                RecordTypeId = cpqRtId,
                Name = 'ANON Insert',
                StageName = 'Discovery',
                CloseDate = Date.today(),
                Deal_Type__c = 'Direct',
                Pricebook2Id = Test.getStandardPricebookId(),
                CurrencyIsoCode = 'USD',
                Type = 'New Business',
                CONTRACT_CURRENCY__C='USD',
                RATETOBESET__C=TRUE
                //OPPORTUNITY_TYPE__C='New Business'
        );

        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c =  opp.Id,
                SBQQ__Primary__c = true,
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addDays(365),
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__Status__c = 'Draft',
                SBQQ__PriceBook__c = Test.getStandardPricebookId()

        );

        insert quote;

        opp.SBQQ__PrimaryQuote__c = quote.Id;
        update opp;

        List<Product2> prods = new List<Product2>();

        String[] prodFamily = new String[]{'Core Product','Non-Production','Partner'};

        for(Integer i = 0; i < prodFamily.size(); i++){

            Product2 prod = new Product2();
            prod.Family = prodFamily[i];
            prod.Name = 'Test'+i;
            prod.IsActive = true;
            prod.CurrencyIsoCode = 'USD';
            prod.EDITABLE_PRICE__C = TRUE;
            prod.VENDOR__C = 'UiPath';
            prod.LICENSE_MODEL__C = 'Node Locked';
            prod.UNIT_OF_MEASURE__C = 'Each/User per year';
            prod.SBQQ__QUANTITYEDITABLE__C = TRUE;
            prod.SBQQ__SUBSCRIPTIONPRICING__C = 'Fixed Price';


            prods.add(prod);
        }

        insert prods;

        List<PricebookEntry> pbes = new List<PricebookEntry>();

        Id stdPb = Test.getStandardPricebookId();

        for(Product2 p : prods){

            PricebookEntry pbe = new PricebookEntry(
                    Pricebook2Id = stdPb,
                    UnitPrice = 1000,
                    CurrencyIsoCode = 'USD',
                    Product2Id = p.Id,
                    IsActive = true
            );

            pbes.add(pbe);

        }

        insert pbes;


        //Add base-QLIS - should be deleted as needed by the test scenario
        List<SBQQ__QuoteLine__c> qlis = new List<SBQQ__QuoteLine__c>();

        for(Integer i = 0; i < pbes.size(); i++){
            SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
                    SBQQ__Product__c = pbes.get(i).Product2Id,
                    SBQQ__PricebookEntryId__c = pbes.get(i).Id,
                    SBQQ__Quote__c = quote.Id,
                    CurrencyIsoCode = 'USD',
                    SBQQ__Quantity__c = 1
            );
            qlis.add(qli);
        }

        insert qlis;


    }

    @IsTest
    static void validateDataSetup(){

        //DoinaP
        Test.startTest();
        
        //validate data setup
        List<Account> acc = [SELECT Id FROM Account];
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c];
        List<Product2> prods = [SELECT Id FROM Product2];
        List<PricebookEntry> pbes = [SELECT Id FROM PricebookEntry];
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c];

        System.assertEquals(1, acc.size());
        System.assertEquals(1, opps.size());
        System.assertEquals(3, prods.size());
        System.assertEquals(3, pbes.size());
        System.assertEquals(1, quotes.size());
        System.assertEquals(3,quoteLines.size());
        //
        
        //DoinaP        
        Test.stopTest();

    }

    /**
     * Test cases
     */

    /**
     * Positive - no existing contracted prices > 2 cps created
     */
   // @IsTest
    static void testBehavior1() {

        //DoinaP
        Test.startTest();

        //get setup records
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        SBQQ__Quote__c q = quotes.get(0);
        Opportunity opp = opps.get(0);

        //cycle Quote stages
        q.SBQQ__Status__c = 'Approved';
        update q;
        q.SBQQ__Status__c = 'Accepted';
        update q;
        //

        //trigger contract generation
        opp.SBQQ__Contracted__c = true;
        //force async
        
        //DoinaP - Test.startTest();
        update opp;
        Test.stopTest();
        //

        //assert records created
        List<Contract> contract = [SELECT Id FROM Contract];
        System.assertEquals(1, contract.size());
        List<SBQQ__ContractedPrice__c> cps = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(2,cps.size());
        //
    }

    /**
     * Negative - no existing contracted prices, only partner products > no cps created
    */
    @IsTest
    static void testBehavior2() {

        //DoinaP
        Test.startTest();

        //get setup records
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //amend products for this scenario
        List<Product2> prodsAmend= [SELECT Id, Family FROM Product2 WHERE Family != 'Partner'];

        for(Product2 p : prodsAmend){
            p.Family = 'Partner';
        }
        update prodsAmend;

        List<Product2> partnerProduct2s = [SELECT Id FROM Product2 WHERE Family = 'Partner'];
        System.assertEquals(3, partnerProduct2s.size());
        //


        SBQQ__Quote__c q = quotes.get(0);
        Opportunity opp = opps.get(0);

        //cycle Quote stages
        q.SBQQ__Status__c = 'Approved';
        update q;
        q.SBQQ__Status__c = 'Accepted';
        update q;
        //

        //trigger contract generation
        opp.SBQQ__Contracted__c = true;
        //force async
        
        //DoinaP - Test.startTest();
        update opp;
        Test.stopTest();
        //

        //assert records created
        
        List<Contract> contract = [SELECT Id FROM Contract];
        System.assertEquals(1, contract.size());
        
        
        //List<SBQQ__ContractedPrice__c> cps = [SELECT Id FROM SBQQ__ContractedPrice__c];
        //System.assertEquals(0,cps.size());
        //
    }

    /**
    * Positive -  1 existing contracted prices, 1 created contract price > 2 cps
    */
    //@IsTest
    static void testBehavior3() {
    
        //DoinaP
        Test.startTest();

        //get setup records
        List<Account> acc = [SELECT Id FROM Account];
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a contracted price for one product
        List<Product2> coreProducts= [SELECT Id, Family FROM Product2 WHERE Family = 'Core Product'];
        System.assertEquals(1,coreProducts.size());

        SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(
                SBQQ__Product__c = coreProducts.get(0).Id,
                SBQQ__Account__c = acc.get(0).Id,
                SBQQ__Price__c =1000,
                SBQQ__EffectiveDate__c = Date.today(),
                SBQQ__ExpirationDate__c = Date.today().addYears(1)
        );

        insert cp;

        List<SBQQ__ContractedPrice__c> cps = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(1,cps.size());
        //

        SBQQ__Quote__c q = quotes.get(0);
        Opportunity opp = opps.get(0);

        //cycle Quote stages
        q.SBQQ__Status__c = 'Approved';
        update q;
        q.SBQQ__Status__c = 'Accepted';
        update q;
        //

        //trigger contract generation
        opp.SBQQ__Contracted__c = true;
        //force async
        
        //DoinaP - Test.startTest();
        update opp;
        Test.stopTest();
        //

        //assert records created
        List<Contract> contract = [SELECT Id FROM Contract];
        System.assertEquals(1, contract.size());
        List<SBQQ__ContractedPrice__c> cps2 = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(2,cps2.size());

        //
    }

    /**
    * Positive -  existing contracted prices, but expired > 3 cps (1 existing expired, 2 created)
    */
    //@IsTest
    static void testBehavior4() {
    
        //DoinaP
        Test.startTest();

        //get setup records
        List<Account> acc = [SELECT Id FROM Account];
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a contracted price for one product
        List<Product2> coreProducts= [SELECT Id, Family FROM Product2 WHERE Family = 'Core Product'];
        System.assertEquals(1,coreProducts.size());

        //create an expired contract price
        SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(
                SBQQ__Product__c = coreProducts.get(0).Id,
                SBQQ__Account__c = acc.get(0).Id,
                SBQQ__Price__c =1000,
                SBQQ__EffectiveDate__c = Date.today().addMonths(-13),
                SBQQ__ExpirationDate__c = Date.today().addMonths(-1)
        );

        insert cp;

        List<SBQQ__ContractedPrice__c> cps = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(1,cps.size());
        //

        SBQQ__Quote__c q = quotes.get(0);
        Opportunity opp = opps.get(0);

        //cycle Quote stages
        q.SBQQ__Status__c = 'Approved';
        update q;
        q.SBQQ__Status__c = 'Accepted';
        update q;
        //

        //trigger contract generation
        opp.SBQQ__Contracted__c = true;
        //force async
        
        //DoinaP - Test.startTest();
        update opp;
        Test.stopTest();
        //

        //assert records created
        List<Contract> contract = [SELECT Id FROM Contract];
        System.assertEquals(1, contract.size());
        List<SBQQ__ContractedPrice__c> cps2 = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(3,cps2.size());

        //
    }

    /**
    * Negative -  existing contracted prices, evergreen > 2 cps (1 existing, 1 created)
    */
    //@IsTest
    static void testBehavior6() {
    
        //DoinaP
        Test.startTest();

        //get setup records
        List<Account> acc = [SELECT Id FROM Account];
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a contracted price for one product
        List<Product2> coreProducts= [SELECT Id, Family FROM Product2 WHERE Family = 'Core Product'];
        System.assertEquals(1,coreProducts.size());

        //create an expired contract price
        SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(
                SBQQ__Product__c = coreProducts.get(0).Id,
                SBQQ__Account__c = acc.get(0).Id,
                SBQQ__Price__c =1000,
                SBQQ__EffectiveDate__c = Date.today().addMonths(-1)
        );

        insert cp;

        List<SBQQ__ContractedPrice__c> cps = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(1,cps.size());
        //

        SBQQ__Quote__c q = quotes.get(0);
        Opportunity opp = opps.get(0);

        //cycle Quote stages
        q.SBQQ__Status__c = 'Approved';
        update q;
        q.SBQQ__Status__c = 'Accepted';
        update q;
        //

        //trigger contract generation
        opp.SBQQ__Contracted__c = true;
        //force async
        
        //DoinaP - Test.startTest();
        update opp;
        Test.stopTest();
        //

        //assert records created
        List<Contract> contract = [SELECT Id FROM Contract];
        System.assertEquals(1, contract.size());
        List<SBQQ__ContractedPrice__c> cps2 = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(2,cps2.size());

        //
    }


    /**
     * Units
     **/

    @IsTest
    static void getScopeProductsTest(){

        //DoinaP
        Test.startTest();

        Set<Id> scopeProds = CPQQuoteContractedPricesService.getScopeProducts();
        List<Product2> prods = [SELECT Id FROM Product2];

        System.assertEquals(3,prods.size());
        System.assertEquals(2,scopeProds.size());
        
        //DoinaP
        Test.stopTest();

    }

    @IsTest
    static void getQuoteLinesTest(){
    
        //DoinaP
        Test.startTest();

        //get setup records
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //


        Map<Id,List<SBQQ__QuoteLine__c>> quoteLinesMap = CPQQuoteContractedPricesService.getQuoteLines(quotes);

        System.assertEquals(1, quoteLinesMap.keySet().size());
        System.assertEquals(3, quoteLinesMap.get(quotes.get(0).Id).size());
        
        //DoinaP
        Test.stopTest();

    }

    @IsTest
    static void getContractedPricesTest(){

        //DoinaP
        Test.startTest();
        
        //get setup records
        List<Account> acc = [SELECT Id FROM Account];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a contracted price for one product
        List<Product2> coreProducts= [SELECT Id, Family FROM Product2 WHERE Family = 'Core Product'];
        System.assertEquals(1,coreProducts.size());

        SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(
                SBQQ__Product__c = coreProducts.get(0).Id,
                SBQQ__Account__c = acc.get(0).Id,
                SBQQ__Price__c =1000,
                SBQQ__EffectiveDate__c = Date.today(),
                SBQQ__ExpirationDate__c = Date.today().addYears(1)
        );

        insert cp;


        Map<Id,List<SBQQ__ContractedPrice__c>> contractedPriceAccMap = CPQQuoteContractedPricesService.getContractedPrices(quotes);

        System.assertEquals(1, contractedPriceAccMap.keySet().size());
        System.assertEquals(1, contractedPriceAccMap.get(quotes.get(0).SBQQ__Account__c).size());
        
        //DoinaP
        Test.stopTest();

    }

    @IsTest
    static void getAccContractedPricesByProdIdsTest(){
    
        //DoinaP
        Test.startTest();

        //get setup records
        List<Account> acc = [SELECT Id FROM Account];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a contracted price for one product
        List<Product2> coreProducts= [SELECT Id, Family FROM Product2 WHERE Family = 'Core Product'];
        System.assertEquals(1,coreProducts.size());

        SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(
                SBQQ__Product__c = coreProducts.get(0).Id,
                SBQQ__Account__c = acc.get(0).Id,
                SBQQ__Price__c =1000,
                SBQQ__EffectiveDate__c = Date.today(),
                SBQQ__ExpirationDate__c = Date.today().addYears(1)
        );

        insert cp;

        Map<Id,List<SBQQ__ContractedPrice__c>> contractedPriceAccMap = CPQQuoteContractedPricesService.getContractedPrices(quotes);

        List<SBQQ__ContractedPrice__c> accCps = contractedPriceAccMap.get(acc.get(0).Id);


        Map<Id,List<SBQQ__ContractedPrice__c>> AccContractedPricesByProdIds = CPQQuoteContractedPricesService.getAccContractedPricesByProdIds(accCps);


        System.assertEquals(1, AccContractedPricesByProdIds.get(coreProducts.get(0).Id).size());

        //DoinaP
        Test.stopTest();

    }

    @IsTest
    static void hasActiveContractPrice1(){
    
        //DoinaP
        Test.startTest();

        //get setup records
        List<Account> acc = [SELECT Id FROM Account];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a contracted price for one product
        List<Product2> coreProducts= [SELECT Id, Family FROM Product2 WHERE Family = 'Core Product'];
        System.assertEquals(1,coreProducts.size());

        SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(
                SBQQ__Product__c = coreProducts.get(0).Id,
                SBQQ__Account__c = acc.get(0).Id,
                SBQQ__Price__c =1000,
                SBQQ__EffectiveDate__c = Date.today(),
                SBQQ__ExpirationDate__c = Date.today().addYears(1)
        );

        insert cp;

        Map<Id,List<SBQQ__ContractedPrice__c>> contractedPriceAccMap = CPQQuoteContractedPricesService.getContractedPrices(quotes);

        List<SBQQ__ContractedPrice__c> accCps = contractedPriceAccMap.get(acc.get(0).Id);


        Map<Id,List<SBQQ__ContractedPrice__c>> AccContractedPricesByProdIds = CPQQuoteContractedPricesService.getAccContractedPricesByProdIds(accCps);

        List<SBQQ__ContractedPrice__c> cpsAccProd = AccContractedPricesByProdIds.get(coreProducts.get(0).Id);

        SBQQ__QuoteLine__c qli = [SELECT Id, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__c =: coreProducts.get(0).Id];

        System.assert(CPQQuoteContractedPricesService.hasActiveContractPrice(cpsAccProd, qli));
        
        //DoinaP
        Test.stopTest();

    }

    @IsTest
    static void hasActiveContractPrice2(){
    
        //DoinaP
        Test.startTest();

        //get setup records
        List<Account> acc = [SELECT Id FROM Account];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a contracted price for one product
        List<Product2> coreProducts= [SELECT Id, Family FROM Product2 WHERE Family = 'Core Product'];
        System.assertEquals(1,coreProducts.size());

        SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(
                SBQQ__Product__c = coreProducts.get(0).Id,
                SBQQ__Account__c = acc.get(0).Id,
                SBQQ__Price__c =1000,
                SBQQ__EffectiveDate__c = Date.today(),
                SBQQ__ExpirationDate__c = Date.today().addYears(1)
        );

        insert cp;

        List<Product2> nonCoreProducts= [SELECT Id, Family FROM Product2 WHERE Family != 'Core Product'];
        System.assertEquals(2,nonCoreProducts.size());


        Map<Id,List<SBQQ__ContractedPrice__c>> contractedPriceAccMap = CPQQuoteContractedPricesService.getContractedPrices(quotes);

        List<SBQQ__ContractedPrice__c> accCps = contractedPriceAccMap.get(acc.get(0).Id);


        Map<Id,List<SBQQ__ContractedPrice__c>> AccContractedPricesByProdIds = CPQQuoteContractedPricesService.getAccContractedPricesByProdIds(accCps);


        List<SBQQ__ContractedPrice__c> cpsAccProd = new List<SBQQ__ContractedPrice__c>();
        cpsAccProd = AccContractedPricesByProdIds.get(nonCoreProducts.get(0).Id);

        SBQQ__QuoteLine__c qli = [SELECT Id, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__c =: nonCoreProducts.get(0).Id];

        System.assert(!CPQQuoteContractedPricesService.hasActiveContractPrice(cpsAccProd, qli));
        
        //DoinaP
        Test.stopTest();

    }

    /**
    * Positive - no existing contracted prices > 2 cps created, bundle product ignored
    */
    //@IsTest
    static void testBehavior7() {
        
        Test.startTest();
        
        //get setup records
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        //create a bundle product
        Product2 prod = new Product2();

        prod.Family = 'Core Product';
        prod.Name = 'Test bundle';
        prod.IsActive = true;
        prod.CurrencyIsoCode = 'USD';
        prod.EDITABLE_PRICE__C = TRUE;
        prod.VENDOR__C = 'UiPath';
        prod.LICENSE_MODEL__C = 'Node Locked';
        prod.UNIT_OF_MEASURE__C = 'Each/User per year';
        prod.SBQQ__QUANTITYEDITABLE__C = TRUE;
        prod.SBQQ__SUBSCRIPTIONPRICING__C = 'Fixed Price';
        prod.SBQQ__ConfigurationType__c = 'Allowed';
        prod.SBQQ__ConfigurationEvent__c = 'Always';



        insert prod;
        //

        //create a pbe for the bundle product
        Id stdPb = Test.getStandardPricebookId();


        PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = stdPb,
                UnitPrice = 0,
                CurrencyIsoCode = 'USD',
                Product2Id = prod.Id,
                IsActive = true
        );

        insert pbe;
        //

        //create a QLI for the bundle product
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
                SBQQ__Product__c = pbe.Product2Id,
                SBQQ__PricebookEntryId__c = pbe.Id,
                SBQQ__Quote__c = quotes[0].Id,
                CurrencyIsoCode = 'USD',
                SBQQ__Quantity__c = 1
        );
        insert qli;
        //

        SBQQ__Quote__c q = quotes.get(0);
        Opportunity opp = opps.get(0);
        
        //Test.startTest();
        //cycle Quote stages
        q.SBQQ__Status__c = 'Approved';
        update q;
        q.SBQQ__Status__c = 'Accepted';
        update q;
        //

        //trigger contract generation
        opp.SBQQ__Contracted__c = true;
        //force async
        
        update opp;
        Test.stopTest();
        //

        //assert records created - the additional bundle product should not create a contracted price record
        List<Contract> contract = [SELECT Id FROM Contract];
        System.assertEquals(1, contract.size());
        List<SBQQ__ContractedPrice__c> cps = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(2,cps.size());
        //
        
    }

    /**
 * Negative - Opp.Deal_Type__c == 'Resale' -> 0 cps created
 */
    @IsTest
    static void testBehavior8() {

        Test.startTest();
        
        //get setup records
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c];
        //

        SBQQ__Quote__c q = quotes.get(0);
        Opportunity opp = opps.get(0);

        opp.Deal_Type__c = 'Resale';

        update opp;
        

        //system.debug('SOQLQueries =====> ' + Limits.getQueries());
        
        //cycle Quote stages
        q.SBQQ__Status__c = 'Approved';
        update q;
        q.SBQQ__Status__c = 'Accepted';
        update q;
        //
        
        
        //trigger contract generation
        opp.SBQQ__Contracted__c = true;
        //force async
        //Test.startTest();
        update opp;
        Test.stopTest();
        //
        
        
        //assert records created
        List<Contract> contract = [SELECT Id FROM Contract];
        System.assertEquals(1, contract.size());
        
       
        List<SBQQ__ContractedPrice__c> cps = [SELECT Id FROM SBQQ__ContractedPrice__c];
        System.assertEquals(0,cps.size());
        
        
    }


}