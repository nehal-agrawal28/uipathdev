@IsTest(isParallel=false)
private class DealBuilderContractsControllerTest_DB {
  private static void makeData() {
    User testUser = DataFactory_CM.createUser('Test', 'User', 'System Administrator', true);
    Account testAccount = DataFactory_CM.createAccount('Customer', false);
    testAccount.OwnerId = testUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).disableAll();
    insert testAccount;
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).enableAll();

    //create product1
    Product2 product1 = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert product1;
    //

    Id stdPbId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = stdPbId,
      Product2Id = product1.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    //create contract
    Contract contract = new Contract(
      AccountId = testAccount.Id,
      SBQQ__PreserveBundleStructureUponRenewals__c = true,
      StartDate = Date.today().addYears(-2),
      EndDate = Date.today().addYears(1).addDays(-1),
      SBQQ__AmendmentOwner__c = testUser.Id
    );
    insert contract;
    //

    //add subscription
    Integer qty = 4;
    Date endDate = Date.today().addYears(1);
    Integer netPri = 1000;
    SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
      SBQQ__Contract__c = contract.Id,
      SBQQ__Product__c = product1.Id,
      SBQQ__Quantity__c = qty,
      SBQQ__SubscriptionEndDate__c = Date.today().addYears(1).addDays(-1)
    );
    insert sub;
    //
  }

  // This method will be updated to remove data. We need to build out a test setup that is going to create all of the basic records for us
  @IsTest
  static void getContracts_noContracts_emptyList() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;
    Test.startTest();
    List<CPQContractMsg_SL> contracts = DealBuilderContractsController_DB.getContracts(
      new List<String>{ account.Id },
      'All'
    );
    test.stopTest();

    System.assertEquals(0, contracts.size(), 'We should not have any contracts for an account');
  }

  @IsTest
  static void getContracts_OneContract_ListOfOne() {
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Id standardPricebookId = Test.getStandardPricebookId();

    Product2 pro = new Product2(
      Name = 'Product Uipath 1' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ pro };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = pro.Id,
      UnitPrice = 3000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, false);
    insert opp;

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp.id,
      PriceBookEntryID = pbe.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;

    opp.SBQQ__Contracted__c = true;
    update opp;
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today().addDays(1),
      ContractTerm = 12,
      EndDate = System.today().addDays(365)
    );
    insert contract;
    contract.Status = 'Activated';
    update contract;

    // Act
    Test.startTest();
    List<CPQContractMsg_SL> contracts = DealBuilderContractsController_DB.getContracts(
      new List<String>{ account.Id },
      '5'
    );
    Test.stopTest();

    System.assertEquals(1, contracts.size());
  }

  @IsTest
  static void amendContracts_OneContract_newQuote() {
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    //create product
    Product2 prod = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert prod;
    //

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1020.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp.id,
      PriceBookEntryID = pbe.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;
    opp.SBQQ__Contracted__c = true;
    update opp;
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today()
    );
    insert contract;
    contract.Status = 'Activated';
    update contract;

    // Act
    Test.startTest();
    CancelContractsMsg_SL amendContractMsg = new CancelContractsMsg_SL();
    amendContractMsg.contractIds = new List<String>{ contract.Id };
    amendContractMsg.startDate = String.valueOf(System.today());
    amendContractMsg.endDate = String.valueOf(System.today().addMonths(24));
    amendContractMsg.opportunityStage = 'Prospecting';
    amendContractMsg.opportunityDealType = 'Direct';
    amendContractMsg.opportunityName = 'Test Name';
    amendContractMsg.accountId = account.Id;
    // amendContractMsg.termLength = 24;

    CancelContractJobMsg_SL jobmsg = DealBuilderContractsController_DB.amendContracts(amendContractMsg);
    List<String> jobIds = new List<String>();
    for (CancelContractJobMsg_SL.JobStatus job : jobmsg.jobs) {
      jobIds.add(job.jobId);
    }
    List<ApexJobStatusMsg_CM> jobStatuses = DealBuilderContractsController_DB.getJobStatus(jobIds);
    System.assertEquals(1, jobStatuses.size());

    Test.stopTest();

    // Assert
    Opportunity opportunity = [SELECT Id, Name, StageName FROM Opportunity WHERE Name LIKE '%Test Name%'];
    SBQQ__Quote__c newQuote = [
      SELECT Id, SBQQ__Primary__c, SBQQ__SubscriptionTerm__c, SBQQ__StartDate__c, (SELECT Id FROM CancellationQuotes__r)
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__c = :opportunity.Id
    ];
    System.assertEquals(3, [SELECT Id FROM SBQQ__Quote__c].size());
    System.assertEquals(
      amendContractMsg.opportunityStage,
      opportunity.StageName,
      'A new Opportunity should have been created'
    );
    System.assertEquals(
      Date.valueOf(amendContractMsg.startDate),
      newQuote.SBQQ__StartDate__c,
      'Start Date should have been set to the value we passed in'
    );
    System.assertEquals(1, newQuote.CancellationQuotes__r.size());
  }

  @IsTest
  static void amendContractsSerialise_OneContract_newQuote() {
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    //create product
    Product2 prod = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert prod;
    //

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1020.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp.id,
      PriceBookEntryID = pbe.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;
    opp.SBQQ__Contracted__c = true;
    update opp;
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today()
    );
    insert contract;
    contract.Status = 'Activated';
    update contract;

    // Act
    Test.startTest();
    CancelContractsMsg_SL amendContractMsg = new CancelContractsMsg_SL();
    amendContractMsg.contractIds = new List<String>{ contract.Id };
    amendContractMsg.startDate = String.valueOf(System.today());
    amendContractMsg.endDate = String.valueOf(System.today().addMonths(24));
    amendContractMsg.opportunityStage = 'Prospecting';
    amendContractMsg.opportunityDealType = 'Direct';
    amendContractMsg.opportunityName = 'Test Name';
    amendContractMsg.accountId = account.Id;
    // amendContractMsg.termLength = 24;

    CancelContractJobMsg_SL jobmsg = DealBuilderContractsController_DB.amendContractsSerialise(amendContractMsg);

    Test.stopTest();
    // Assert
    Opportunity opportunity = [SELECT Id, Name, StageName FROM Opportunity WHERE Name LIKE '%Test Name%'];
    SBQQ__Quote__c newQuote = [
      SELECT Id, SBQQ__Primary__c, SBQQ__SubscriptionTerm__c, SBQQ__StartDate__c, (SELECT Id FROM CancellationQuotes__r)
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__c = :opportunity.Id
    ];
    System.assertEquals(3, [SELECT Id FROM SBQQ__Quote__c].size());
    System.assertEquals(
      amendContractMsg.opportunityStage,
      opportunity.StageName,
      'A new Opportunity should have been created'
    );
    System.assertEquals(
      Date.valueOf(amendContractMsg.startDate),
      newQuote.SBQQ__StartDate__c,
      'Start Date should have been set to the value we passed in'
    );
    System.assertEquals(1, newQuote.CancellationQuotes__r.size());

    AsyncTask__c task = [SELECT Id FROM AsyncTask__c LIMIT 1];
    task.Status__c = 'Submitted';
    update task;
    DealBuilderContractsController_DB.retryJob(task.Id);
  }

  @IsTest
  private static void searchSoldToPartnerTest() {
    Test.startTest();
    DealBuilderContractsController_DB.searchSoldToPartner('Test', new List<String>());
    DealBuilderContractsController_DB.searchOpportunity('Test', new List<String>(), null);
    DealBuilderContractsController_DB.searchOpportunity(null, new List<String>(), null);
    DealBuilderContractsController_DB.searchQuote('Test', new List<String>(), null);
    DealBuilderContractsController_DB.searchQuote(null, new List<String>(), null);
    Test.stopTest();
  }

  @IsTest
  static void amendContracts_TwoContract_newQuote() {
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Opportunity opp1 = DataFactory_SL.createOpportunity(account.Id, true);
    Opportunity opp2 = DataFactory_SL.createOpportunity(account.Id, true);

    //setup products/pbes/olis
    //Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
    // update standardPricebook;

    Id standardPricebookId = Test.getStandardPricebookId();

    Product2 pro1 = new Product2(
      Name = 'Product Uipath 1' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    Product2 pro2 = new Product2(
      Name = 'Product Uipath 1' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ pro1, pro2 };

    PricebookEntry pbe1 = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = pro1.Id,
      UnitPrice = 1020.00,
      IsActive = true
    );
    PricebookEntry pbe2 = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = pro2.Id,
      UnitPrice = 2040.00,
      IsActive = true
    );
    SBQQ.TriggerControl.disable();
    insert new List<PricebookEntry>{ pbe1, pbe2 };
    SBQQ.TriggerControl.enable();

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp1.id,
      PriceBookEntryID = pbe1.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    OpportunityLineItem lineItem2 = new OpportunityLineItem(
      OpportunityID = opp2.id,
      PriceBookEntryID = pbe2.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem2;
    //

    Test.startTest();
    //Quotes
    SBQQ__Quote__c quote1 = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp1.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote1;
    opp1.SBQQ__Contracted__c = true;
    update opp1;

    SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp2.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today().addDays(-10),
      SBQQ__SubscriptionTerm__c = 24
    );
    insert quote2;
    opp2.SBQQ__Contracted__c = true;
    update opp2;
    //

    //contracts
    Contract contract1 = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp1.Id,
      SBQQ__Quote__c = quote1.Id,
      StartDate = System.today()
    );
    insert contract1;
    contract1.Status = 'Activated';
    update contract1;

    Contract contract2 = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp2.Id,
      SBQQ__Quote__c = quote2.Id,
      StartDate = System.today().addDays(-10)
    );
    insert contract2;
    contract2.Status = 'Activated';
    update contract2;
    //

    // Act
    CancelContractsMsg_SL amendContractMsg = new CancelContractsMsg_SL();
    amendContractMsg.contractIds = new List<String>{ contract1.Id, contract2.Id };
    amendContractMsg.startDate = String.valueOf(System.today());
    amendContractMsg.endDate = String.valueOf(System.today().addMonths(24));
    amendContractMsg.opportunityStage = 'Prospecting';
    amendContractMsg.opportunityDealType = 'Direct';
    amendContractMsg.opportunityName = 'Test Name';
    amendContractMsg.accountId = account.Id;

    /*CancelContractJobMsg_SL jobmsg = DealBuilderContractsController_DB.amendContracts(amendContractMsg);
    List<String> jobIds = new List<String>();
    for (CancelContractJobMsg_SL.JobStatus job : jobmsg.jobs) {
      jobIds.add(job.jobId);
    }
    List<ApexJobStatusMsg_CM> jobStatuses = DealBuilderContractsController_DB.getJobStatus(jobIds);
    System.assertEquals(2, jobStatuses.size());
    Test.stopTest();
    // Assert
    Opportunity opportunity = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Name'];
    SBQQ__Quote__c newQuote = [
      SELECT Id, SBQQ__Primary__c, SBQQ__SubscriptionTerm__c, SBQQ__StartDate__c, (SELECT Id FROM CancellationQuotes__r)
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__r.Name = 'Test Name'
    ];
    System.assertEquals(5, [SELECT Id FROM SBQQ__Quote__c].size());
    System.assertEquals(
      amendContractMsg.opportunityStage,
      opportunity.StageName,
      'A new Opportunity should have been created'
    );
    System.assertEquals(
      Date.valueOf(amendContractMsg.startDate),
      newQuote.SBQQ__StartDate__c,
      'Start Date should have been set to the value we passed in'
    );
    System.assertEquals(2, newQuote.CancellationQuotes__r.size());*/
  }

  @IsTest
  private static void getRipReplaceDataTest() {
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, false);
    insert opp;

    Product2 product1 = new Product2(
      Name = 'PremiumSupport',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable',
      Family = 'Support'
    );
    insert product1;
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;

    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today().addDays(1),
      ContractTerm = 12,
      EndDate = System.today().addDays(365)
    );
    insert contract;

    SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
      SBQQ__Contract__c = contract.Id,
      SBQQ__Product__c = product1.Id,
      SBQQ__Quantity__c = 4,
      SBQQ__SubscriptionEndDate__c = Date.today().addYears(1).addDays(-1)
    );
    insert sub;

    Test.startTest();
    DealBuilderContractsController_DB.RipReplaceDataWrapper data = DealBuilderContractsController_DB.getRipReplaceData(
      new List<String>{ contract.Id }
    );
    System.assertEquals(data.currencyPicklist.size() > 0, true);
    Test.stopTest();
  }

  @IsTest
  private static void getOpportunityStageValues_valuesReturned() {
    // Act
    Test.startTest();
    List<PicklistMsg_CM> picklistValues = DealBuilderContractsController_DB.getOpportunityStageValues();
    Test.stopTest();

    // Assert
    System.assert(picklistValues.size() > 1, 'We should have had picklist Values Returned');
  }

  @IsTest
  private static void getAccounts_231Records_231Returned() {
    Account parentAccount = DataFactory_CM.createAccount('Customer', false);
    insert parentAccount;
    List<Account> level2Accounts = DataFactory_SL.inflateChildAccountsWithNamePrefix(
      new List<Account>{ parentAccount },
      'level2 ',
      5
    );
    insert level2Accounts;

    List<Account> level3Accounts = DataFactory_SL.inflateChildAccountsWithNamePrefix(level2Accounts, 'level3 ', 3);
    insert level3Accounts;

    List<Account> level4Accounts = DataFactory_SL.inflateChildAccountsWithNamePrefix(level3Accounts, 'level4 ', 2);
    insert level4Accounts;

    List<Account> level5Accounts = DataFactory_SL.inflateChildAccountsWithNamePrefix(level4Accounts, 'level5 ', 2);
    insert level5Accounts;

    List<Account> level6Accounts = DataFactory_SL.inflateChildAccountsWithNamePrefix(level5Accounts, 'level6 ', 2);
    insert level6Accounts;

    // Act
    Test.startTest();
    List<String> accountIds = DealBuilderContractsController_DB.getAccounts(level4Accounts[3].Id);
    Test.stopTest();

    // Assert
    System.assertEquals(231, accountIds.size(), 'We should returned all 231 accounts');
  }

  @IsTest
  static void itShouldSetTheExistingOppSelectedForRipReplaceAsReplacementTransactionAndNamePrefix() {
    //GIVEN
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Product2 prod = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert prod;

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1020.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp.id,
      PriceBookEntryID = pbe.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;
    opp.SBQQ__Contracted__c = true;
    update opp;
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today()
    );
    insert contract;
    contract.Status = 'Activated';
    update contract;

    String replacementOppName = 'Test Replacement Opp';
    Opportunity replacementOpp = DataFactory_SL.createOpportunity(account.Id, true);
    CancelContractsMsg_SL amendContractMsg = new CancelContractsMsg_SL();
    amendContractMsg.contractIds = new List<String>{ contract.Id };
    amendContractMsg.startDate = String.valueOf(System.today());
    amendContractMsg.endDate = String.valueOf(System.today().addMonths(24));
    amendContractMsg.opportunityStage = 'Prospecting';
    amendContractMsg.opportunityDealType = 'Direct';
    amendContractMsg.opportunityName = replacementOppName;
    amendContractMsg.accountId = account.Id;
    amendContractMsg.existingOpportunityId = replacementOpp.Id;

    //WHEN
    Test.startTest();
    CancelContractJobMsg_SL jobmsg = DealBuilderContractsController_DB.amendContractsSerialise(amendContractMsg);
    Test.stopTest();

    //THEN
    Opportunity reQueryReplacementOpportunity = [
      SELECT Id, Name, Replacement_Transaction__c
      FROM Opportunity
      WHERE Id = :replacementOpp.Id
    ];

    System.assertEquals(
      true,
      reQueryReplacementOpportunity.Replacement_Transaction__c,
      'The existing opportunity selected for Rip & Replace should be flagged as a \'Replacement Transaction\''
    );

    System.assertEquals(
      Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX,
      reQueryReplacementOpportunity.Name.left(6),
      'The opportunity name does not have the expected RR prefix'
    );
  }

  @IsTest
  static void itShouldNotSetTheExistingQuoteSelectedForRipReplaceAsReplacementTransaction() {
    //GIVEN
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Product2 prod = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert prod;

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1020.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp.id,
      PriceBookEntryID = pbe.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;
    opp.SBQQ__Contracted__c = true;
    update opp;
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today()
    );
    insert contract;
    contract.Status = 'Activated';
    update contract;

    Opportunity replacementOpp = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c replacementQuote = DataFactory_SL.createCPQQuote(account.Id, replacementOpp.Id, true);
    CancelContractsMsg_SL amendContractMsg = new CancelContractsMsg_SL();
    amendContractMsg.contractIds = new List<String>{ contract.Id };
    amendContractMsg.startDate = String.valueOf(System.today());
    amendContractMsg.endDate = String.valueOf(System.today().addMonths(24));
    amendContractMsg.opportunityStage = 'Prospecting';
    amendContractMsg.opportunityDealType = 'Direct';
    amendContractMsg.opportunityName = 'Test Name';
    amendContractMsg.accountId = account.Id;
    amendContractMsg.existingOpportunityId = replacementOpp.Id;
    amendContractMsg.existingQuoteId = replacementQuote.Id;

    //WHEN
    Test.startTest();
    CancelContractJobMsg_SL jobmsg = DealBuilderContractsController_DB.amendContractsSerialise(amendContractMsg);
    Test.stopTest();

    //THEN
    SBQQ__Quote__c reQueryReplacementQuote = [
      SELECT Id, Replacement_Transaction__c
      FROM SBQQ__Quote__c
      WHERE Id = :replacementQuote.Id
    ];

    System.assertEquals(
      false,
      reQueryReplacementQuote.Replacement_Transaction__c,
      'The existing quote selected for Rip & Replace should be NOT be flagged as a \'Replacement Transaction\' at this point'
    );
  }

  @IsTest
  static void itShouldSetOppRipReplaceAsReplacementTransactionAndNamePrefix() {
    //GIVEN
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Product2 prod = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert prod;

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1020.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp.id,
      PriceBookEntryID = pbe.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;
    opp.SBQQ__Contracted__c = true;
    update opp;
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today()
    );
    insert contract;
    contract.Status = 'Activated';
    update contract;

    String replacementOppName = 'Test Replacement Opp';
    CancelContractsMsg_SL amendContractMsg = new CancelContractsMsg_SL();
    amendContractMsg.contractIds = new List<String>{ contract.Id };
    amendContractMsg.startDate = String.valueOf(System.today());
    amendContractMsg.endDate = String.valueOf(System.today().addMonths(24));
    amendContractMsg.opportunityStage = 'Prospecting';
    amendContractMsg.opportunityDealType = 'Direct';
    amendContractMsg.opportunityName = replacementOppName;
    amendContractMsg.accountId = account.Id;

    //WHEN
    Test.startTest();
    CancelContractJobMsg_SL jobmsg = DealBuilderContractsController_DB.amendContractsSerialise(amendContractMsg);
    Test.stopTest();

    //THEN
    Opportunity reQueryReplacementOpportunity = [
      SELECT Id, Name, Replacement_Transaction__c
      FROM Opportunity
      WHERE Name LIKE '%Test Replacement Opp%'
      LIMIT 1
    ];

    System.assertEquals(
      true,
      reQueryReplacementOpportunity.Replacement_Transaction__c,
      'The Rip & Replace opportunity should be flagged as a \'Replacement Transaction\''
    );

    System.assertEquals(
      Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX,
      reQueryReplacementOpportunity.Name.left(6),
      'The opportunity name does not have the expected RR prefix'
    );
  }
}