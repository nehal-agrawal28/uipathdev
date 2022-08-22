@IsTest(isParallel=false)
public with sharing class CPQQuotesResourceTest {
  @TestSetup
  static void setup() {
    SBQQ.TriggerControl.disable();

    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c masterQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
    masterQuote.External_Ref__c = 'CPQQuoteClonerService';
    insert masterQuote;
    Product2 testProduct = DataFactory_SL.createProduct(true);

    SBQQ__Quote__c slaveQuote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = masterQuote.SBQQ__Opportunity2__c,
      SBQQ__Primary__c = false,
      SBQQ__Account__c = masterQuote.SBQQ__Account__c,
      Bill_To_Account__c = masterQuote.SBQQ__Account__c,
      SBQQ__PrimaryContact__c = masterQuote.SBQQ__PrimaryContact__c,
      SBQQ__Type__c = 'Quote',
      SBQQ__Status__c = 'Draft',
      // Payment_Terms__c = '30 Days Net',
      SBQQ__StartDate__c = Date.newInstance(System.today().year(), System.today().month(), 28),
      SBQQ__EndDate__c = Date.newInstance(System.today().year() + 3, System.today().month(), 27),
      SBQQ__ExpirationDate__c = System.today().addDays(30),
      RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('CPQ Default').getRecordTypeId(),
      External_Ref__c = 'CPQQuoteClonerService_SlaveQuote'
    );
    insert slaveQuote;

    Id pricebookId = Test.getStandardPricebookId();

    Product2 product1 = new Product2(Name = 'Product XYZ 1', ProductCode = 'PROD12121', isActive = true);
    Product2 product2 = new Product2(Name = 'Product XYZ 2', ProductCode = 'PROD22121', isActive = true);
    insert new List<Product2>{ product1, product2 };

    PricebookEntry pbEntry1 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = product1.Id,
      UnitPrice = 3000.00,
      IsActive = true
    );
    PricebookEntry pbEntry2 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = product2.Id,
      UnitPrice = 8000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbEntry1, pbEntry2 };

    Contract contract1 = new Contract(
      StartDate = Date.today() - 300,
      ContractTerm = 12,
      Status = 'Draft',
      AccountId = masterQuote.SBQQ__Account__c
    );

    Contract contract2 = new Contract(
      StartDate = Date.today() - 300,
      ContractTerm = 12,
      Status = 'Draft',
      AccountId = masterQuote.SBQQ__Account__c
    );
    insert new List<Contract>{ contract1, contract2 };

    SBQQ__Subscription__c prod1Subscription = new SBQQ__Subscription__c(
      SBQQ__Account__c = masterQuote.SBQQ__Account__c,
      SBQQ__Contract__c = contract1.Id,
      SBQQ__Product__c = product1.Id,
      SBQQ__Quantity__c = 30
    );
    SBQQ__Subscription__c prod2Subscription = new SBQQ__Subscription__c(
      SBQQ__Account__c = masterQuote.SBQQ__Account__c,
      SBQQ__Contract__c = contract2.Id,
      SBQQ__Product__c = product1.Id,
      SBQQ__Quantity__c = 2
    );

    insert (new List<SBQQ__Subscription__c>{ prod1Subscription, prod2Subscription });

    SBQQ__QuoteLine__c masterLine1 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = masterQuote.Id,
      SBQQ__Product__c = product1.Id,
      SBQQ__PricebookEntryId__c = pbEntry1.Id,
      SBQQ__Number__c = 1, // Number
      SBQQ__Quantity__c = 30.00, // Quantity
      SBQQ__Renewal__c = false, // Renewal
      Unit_of_measure__c = 'Each/User per year', // Unit of measure
      SBQQ__CostEditable__c = false, // Cost Editable
      SBQQ__PriceEditable__c = false, // Price Editable
      SBQQ__PricingMethod__c = 'List', // Pricing Method
      Business_Type__c = 'Renewal', // Business Type
      SBQQ__PricingMethodEditable__c = false, // Pricing Method Editable
      SBQQ__Hidden__c = false, // Hidden
      Line_Product_Family__c = 'UiPath', // Line Product Family
      Product_Version__c = '2019.10', // Product Version
      License_Model__c = 'Named User', // License Model
      Orchestrator_Disaster_Recovery_Option__c = false, // Orchestrator Disaster Recovery Option
      SBQQ__Description__c = 'With the named user licensing only one named user can access the Studio.UiPath Studio is our Process and Workflow Designer tool. It runs only on Windows like the robot which mimicks the user keystrokes of the target Desktop environment. It enables users to automate with highly intuitive tools (not code): process recorders, drag and drop widgets, re-use best practices templates or refer to other workflow libraries.\n', // Description
      SBQQ__ListPrice__c = 3000.00, // List Unit Price
      SBQQ__CustomerPrice__c = 3820.40, // Customer Unit Price
      SBQQ__NetPrice__c = 3820.40, // Net Unit Price
      SBQQ__SpecialPrice__c = 2292.25, // Special Price                // Contracted Price
      SBQQ__RegularPrice__c = 3820.41, // Regular Unit Price
      SBQQ__ProratedListPrice__c = 5000.01, // Prorated List Price
      SBQQ__SubscriptionPricing__c = 'Fixed Price', // Subscription Pricing
      SBQQ__SubscriptionScope__c = 'Quote', // Percent of Total Scope
      SBQQ__SubscriptionBase__c = 'List', // Percent of Total Base
      SBQQ__DefaultSubscriptionTerm__c = 12, // Default Subscription Term
      SBQQ__RenewedSubscription__c = prod1Subscription.Id, // Renewed Subscription
      SBQQ__NonDiscountable__c = false, // Non Discountable
      SBQQ__NonPartnerDiscountable__c = false
    );

    SBQQ__QuoteLine__c slaveLine1 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = slaveQuote.Id,
      SBQQ__Product__c = product2.Id,
      SBQQ__PricebookEntryId__c = pbEntry2.Id,
      SBQQ__Number__c = 2, // Number
      SBQQ__Quantity__c = 2.00, // Quantity
      SBQQ__Renewal__c = false, // Renewal
      Unit_of_measure__c = 'Each/User per year', // Unit of measure
      SBQQ__CostEditable__c = false, // Cost Editable
      SBQQ__PriceEditable__c = false, // Price Editable
      SBQQ__PricingMethod__c = 'List', // Pricing Method
      Business_Type__c = 'Renewal', // Business Type
      SBQQ__PricingMethodEditable__c = false, // Pricing Method Editable
      License_Codes__c = '6098-3198-8687-0736', // License Codes
      SBQQ__Hidden__c = false, // Hidden
      Line_Product_Family__c = 'UiPath', // Line Product Family
      Product_Version__c = '2019.10', // Product Version
      License_Model__c = 'Concurrent Runtime', // License Model
      Orchestrator_Disaster_Recovery_Option__c = false, // Orchestrator Disaster Recovery Option
      Basic_Helper__c = 'Basic', // Basic Helper
      SBQQ__Description__c = '"Concurrent licenses are available ONLY in the case of Orchestrator scenario. 1 active runtime, unlimited users and workstations defined. Unattended Concurrent Runtime License - the No. of Unattended Concurrent Runtime licenses purchased equals the maximum number of unattended robots that are able to execute back office processes simultaneously, regardless of the number of users and machines defined in Orchestrator."\n', // Description
      SBQQ__ListPrice__c = 8000.00, // List Unit Price
      SBQQ__CustomerPrice__c = 6800.00, // Customer Unit Price
      SBQQ__NetPrice__c = 6800.00, // Net Unit Price
      SBQQ__SpecialPrice__c = 6800.00, // Special Price                // Contracted Price
      SBQQ__RegularPrice__c = 6800.00, // Regular Unit Price
      SBQQ__ProratedListPrice__c = 8000.00, // Prorated List Price
      SBQQ__SubscriptionPricing__c = 'Fixed Price', // Subscription Pricing
      SBQQ__SubscriptionScope__c = 'Quote', // Percent of Total Scope
      SBQQ__SubscriptionBase__c = 'List', // Percent of Total Base
      SBQQ__DefaultSubscriptionTerm__c = 12, // Default Subscription Term
      SBQQ__RenewedSubscription__c = prod2Subscription.Id, // Renewed Subscription
      SBQQ__NonDiscountable__c = false, // Non Discountable
      SBQQ__NonPartnerDiscountable__c = false
    );

    insert (new List<SBQQ__QuoteLine__c>{ masterLine1, slaveLine1 });

    SBQQ.TriggerControl.enable();
  }

  @IsTest
  static void testCloneLinesInboundRest() {
    String masterQuoteId = [SELECT Id FROM SBQQ__Quote__c WHERE External_Ref__c = 'CPQQuoteClonerService'].Id;
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/quotes/' + masterQuoteId + '/clonelinesfromslaves';
    req.params.put(
      'slaves',
      [SELECT Id FROM SBQQ__Quote__c WHERE External_Ref__c = 'CPQQuoteClonerService_SlaveQuote']
      .Id
    );
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');
    RestContext.request = req;
    RestContext.response = res;
    Test.startTest();
    SBQQ.TriggerControl.disable();

    List<SBQQ__QuoteLine__c> lines = CPQQuotesResource.cloneLinesFromSlaves();
    SBQQ.TriggerControl.enable();
    Test.stopTest();
    System.assertEquals(1, lines.size());
  }
}