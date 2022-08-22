/**
 * Test class of PS_OpportunityCWBEmailTemplate 
 **/
@IsTest
public class PS_OpportunityCWBEmailTemplateTest {
    
    public static TestMethod void testQueryQuoteLines(){
         Account testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
        testAccount.NS_Customer_Internal_ID__c = '75586';
        testAccount.Country__c='United Kingdom';
        testAccount.Legal__c = 'Legal Name';
        testAccount.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
        testAccount.VAT_Number__c = '12345';
        insert testAccount;
        
        List<Address__c>  addressList = DataFactory_CM.createAddress(1, testAccount.Id, false);
        addressList[0].Primary_Billing__c = true;
        addressList[0].Primary_Shipping__c = true;
        addressList[0].NS_Address_Internal_ID__c = '6776';
        insert addressList;
        
        Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);
        
        Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, false);
        insert testOpportunity;

        SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id,testOpportunity.Id,false);
        quote.SBQQ__Primary__c = true;
        insert quote;
        
        Product2 product = DataFactory_SL.createProduct(true);
        
        PricebookEntry pbe = DataFactory_SL.createStdPricebookEntry(product.Id, 100, false);
        insert pbe;
        
        SBQQ__QuoteLine__c quoteline = DataFactory_SL.createCPQQuoteLine(product.Id, quote.Id, true);

        Test.startTest();
        PS_OpportunityCWBEmailTemplate controller = new PS_OpportunityCWBEmailTemplate();
        testOpportunity.RPA_Primary_Contact__c = testContact.Id;
        testOpportunity.StageName='Closed Won Pending';
        testOpportunity.Won_Reasons__c = 'Product Roadmap';
        update testOpportunity;
        controller.OppId = testOpportunity.Id;
        Test.stopTest();
        system.assertNotEquals(0, controller.quoteLines.size());
    }
}