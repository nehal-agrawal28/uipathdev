@IsTest
public class CPQOpportunityMaintenanceBatchTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    List<Account> customerAccount1 = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 1, false);
    List<Account> customerAccount2 = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 1, false);
    customerAccount2.get(0).Name = 'Testing';
    insert new List<Account>{ customerAccount1.get(0), customerAccount2.get(0) };

    Id pricebookId = Test.getStandardPricebookId();

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    Product2 newProduct = new Product2();
    newProduct.Name = 'testProductName';
    newProduct.Is_Add_On__c = false;
    newProduct.IsActive = true;
    newProduct.Add_On_Percent__c = 10;
    newProduct.License_Model__c = 'N/A';
    newProduct.Unit_of_measure__c = 'N/A';
    newProduct.Ext_Id__c = 'testProductName100';
    newProduct.ProductCode = 'testProductName100';
    newProduct.Family = 'Other';

    insert newProduct;

    PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
    stdPriceBookEntry.Product2Id = newProduct.Id;
    stdPriceBookEntry.Pricebook2Id = Test.getStandardPricebookId();
    stdPriceBookEntry.UnitPrice = 100;
    stdPriceBookEntry.IsActive = true;
    insert stdPriceBookEntry;

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = prod.Id,
      UnitPrice = 100.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp1 = DataFactory_SL.createOpportunity(customerAccount1.get(0).Id, false);
    opp1.Pricebook2Id = Test.getStandardPricebookId();
    insert new List<Opportunity>{ opp1 };

    OpportunityLineItem oli = new OpportunityLineItem();
    oli.OpportunityId = opp1.Id;
    oli.UnitPrice = 10000;
    oli.Quantity = 1;
    oli.PricebookEntryId = stdPriceBookEntry.Id;
    oli.Discount = 0;
    oli.Add_On_For__c = null;
    insert oli;

    List<Address__c> address = DataFactory_CM.createAddress(1, customerAccount1.get(0).Id, false);
    address.get(0).Primary_Billing__c = true;
    address.get(0).Primary_Shipping__c = true;
    address.get(0).NS_Address_Internal_ID__c = '677612';
    insert address;

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(customerAccount1[0].Id, opp1.Id, false);
    quote.SBQQ__Primary__c = true;
    insert quote;

    //QLIs
    List<SBQQ__QuoteLine__c> qlToInsert = new List<SBQQ__QuoteLine__c>();
    SBQQ__QuoteLine__c qle1 = DataFactory_SL.createCPQQuoteLine(prod.Id, quote.Id, false);
    qle1.SBQQ__Quantity__c = 2;
    qle1.SBQQ__PricebookEntryId__c = pbe.Id;
    qlToInsert.add(qle1);

    insert qlToInsert;
  }

  @IsTest
  static void testCPQOpportunityMaintenanceBatch_SL() {
    Test.startTest();
    Database.executeBatch(new CPQOpportunityMaintenanceBatch_SL());
    Test.stopTest();
  }

  @IsTest
  static void testCPQOpportunityMaintenanceBatchWithSegments_SL() {
    Test.startTest();
    //Billing Segments
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    List<Billing_Segment__c> billingSegmentsList = new List<Billing_Segment__c>();
    Billing_Segment__c bs1 = DataFactory_SL.createBillingSegment(quote.Id, 1, 10000, false);
    billingSegmentsList.add(bs1);

    insert billingSegmentsList;

    Database.executeBatch(new CPQOpportunityMaintenanceBatch_SL());
    Test.stopTest();
  }

  @IsTest
  static void testSchdule() {
    Test.startTest();
    System.schedule('CPQOpportunityMaintenanceBatch_SL', '0 0 23 * * ?', new CPQOpportunityMaintenanceBatch_SL());
    Test.stopTest();
  }
}