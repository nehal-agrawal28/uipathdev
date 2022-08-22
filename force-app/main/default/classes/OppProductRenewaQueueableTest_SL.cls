@IsTest
public with sharing class OppProductRenewaQueueableTest_SL {
  // private static final Integer NO_OF_RECORDS = 5;
  // @TestSetup
  // static void makeData() {
  //   SBQQ.TriggerControl.disable();
  //   Account account = DataFactory_CM.createAccount('Customer', true);
  //   Id standardPricebookId = Test.getStandardPricebookId();
  //   Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

  //   List<Product2> products = new List<Product2>();
  //   do {
  //     products.add(
  //       new Product2(
  //         Name = 'Product ' + String.valueOf((Math.random() * 100) + 1),
  //         Ext_Id__c = 'EXT_TEST' + String.valueOf((Math.random() * 100) + 1),
  //         ProductCode = 'PRD_OLI_' + String.valueOf((Math.random() * 100) + 1),
  //         Family = 'Other'
  //       )
  //     );
  //   } while (products.size() < NO_OF_RECORDS);

  //   insert products;

  //   List<PricebookEntry> pbes = new List<PricebookEntry>();
  //   for (Product2 product : products) {
  //     pbes.add(
  //       new PricebookEntry(
  //         Pricebook2Id = standardPricebookId,
  //         Product2Id = product.Id,
  //         UnitPrice = 1000,
  //         CurrencyIsoCode = 'USD',
  //         IsActive = true
  //       )
  //     );
  //   }

  //   insert pbes;

  //   List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

  //   for (Integer k = 0; k < NO_OF_RECORDS; k++) {
  //     olis.add(
  //       new OpportunityLineItem(
  //         OpportunityId = opp.Id,
  //         PricebookEntryId = pbes[k].Id,
  //         Quantity = 1,
  //         TotalPrice = 1000 * (k + 1),
  //         End_Date__c = System.today().addDays(k + 1)
  //       )
  //     );
  //   }
  //   insert olis;
  // }
}