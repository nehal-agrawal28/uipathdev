/**
 * Created by paul.bircham on 2019-06-03.
 */

@IsTest
private class CPQOppProdQuoteLineFieldSyncTest {


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
                    SBQQ__Quantity__c = 1,
                    SBQQ__Discount__c = 0.10
            );
            qlis.add(qli);
        }

        insert qlis;


    }

    @IsTest
    static void validateDataSetup(){

        //validate data setup
        List<Account> acc = [SELECT Id FROM Account];
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c];
        List<Product2> prods = [SELECT Id FROM Product2];
        List<PricebookEntry> pbes = [SELECT Id FROM PricebookEntry];
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c];
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem];

        System.assertEquals(1, acc.size());
        System.assertEquals(1, opps.size());
        System.assertEquals(3, prods.size());
        System.assertEquals(3, pbes.size());
        System.assertEquals(1, quotes.size());
        System.assertEquals(3,quoteLines.size());
        System.assertEquals(3, olis.size());
        //

        for(OpportunityLineItem oli : [SELECT Id, SBQQ__QuoteLine__c FROM OpportunityLineItem]){
            System.assertNotEquals(null, oli.SBQQ__QuoteLine__c);
        }

    }

    @IsTest
    static void testBehavior() {

        Test.startTest();
        Test.stopTest();

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        olis = [SELECT Id, ServiceDate, Effective_Start_Date__c, Total_Discount__c, Discount FROM OpportunityLineItem];

/*        for(OpportunityLineItem oli : olis){
            System.assertEquals(Date.today(),oli.Effective_Start_Date__c);
            System.assertEquals(0.1, oli.Total_Discount__c);
            System.assertEquals(Date.today(), oli.ServiceDate);
            System.assertEquals(0.1, oli.Discount);
        }*/

    }
}