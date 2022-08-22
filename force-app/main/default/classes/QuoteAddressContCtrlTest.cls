/**
    * @DESCRIPTION: This is Test Class for QuoteAddressContainerController class
    * @AUTHOR: Slalom Consulting
*/

@IsTest
public with sharing class QuoteAddressContCtrlTest {

    @isTest
    static void canCreateCPQQuote() {


        Account ukAccount = new Account(
                Name = 'TestAccountUK',
                BillingCountry = 'United Kingdom',
                Country__c = 'United Kingdom',
                BillingStreet = 'Test',
                BillingCity = 'London',
                BillingPostalCode = 'W12 345',
                Industry = 'Others');

        insert ukAccount;

        ukAccount.DnB_Country__c = 'United Kingdom';
        ukAccount.DnB_Street__c = 'Test';
        ukAccount.DnB_City__c = 'London';
        ukAccount.DnB_Zip_Postal_Code__c = 'W44 444';


        update ukAccount;

        List<Address__c> addressList = [SELECT Id, Zip_Postal_Code__c
                                        FROM Address__c
                                        WHERE Account__c = :ukAccount.Id];

        for(Address__c address : addressList){
            if(address.Zip_Postal_Code__c == 'W12 345'){
                address.Primary_Shipping__c = true;
            }
        }
        update addressList;

        Opportunity opportunity = new Opportunity(Name = 'CPQ Opportunity',
                                                    Type = 'New Business',
                                                    StageName = 'Discovery',
                                                    CloseDate = System.today().addMonths(1),
                                                    LeadSource = 'Call Inbound',
                                                    AccountId = ukAccount.Id,
                                                 	Deal_Type__c = 'Direct');


        insert opportunity;



        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opportunity.Id,
                                                    SBQQ__Account__c = ukAccount.Id,
                                                    Bill_To_Account__c = ukAccount.Id,
                                                    SBQQ__StartDate__c = System.today(),
                                                    SBQQ__EndDate__c = System.today().addMonths(1));

        insert quote;

        Test.startTest();


        quote = QuoteAddressContainerController.retrieveQuote(quote.Id);

        List<Address__c> quoteAddressList = QuoteAddressContainerController.retrieveCurrentAddresses(quote.Bill_To_Address__c,quote.Ship_To_Address__c);

        List<Address__c> addressOptionList = QuoteAddressContainerController.retrieveAddressOptionList(quote.Id,'BillTo' );

        QuoteAddressContainerController.setQuoteAddress( quote.Id, quote.Bill_To_Address__c,'ShipTo');

        Test.stopTest();
    }


}