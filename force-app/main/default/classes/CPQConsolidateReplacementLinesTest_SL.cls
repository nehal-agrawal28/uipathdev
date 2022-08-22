@isTest(isParallel=false)
public class CPQConsolidateReplacementLinesTest_SL {
  @isTest
  public static void testGetClonedLines() {
    List<SBQQ__QuoteLine__c> qlis = new List<SBQQ__QuoteLine__c>();
    SBQQ__Quote__c replacementQuote = new SBQQ__Quote__c(Id = fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType));

    //QLI 1
    Id originalQuoteId1 = fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType);
    Id upgradedSubId1 = fflib_IdGenerator.generate(SBQQ__Subscription__c.SObjectType);
    Id requiredById1 = fflib_IdGenerator.generate(SBQQ__QuoteLine__c.SObjectType);
    Id quoteLineGroupId1 = fflib_IdGenerator.generate(SBQQ__QuoteLineGroup__c.SObjectType);
    Id upgradedAssetId1 = fflib_IdGenerator.generate(Asset.SObjectType);

    SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
      Id = fflib_IdGenerator.generate(SBQQ__QuoteLine__c.SObjectType),
      SBQQ__Quantity__c = 0,
      SBQQ__PriorQuantity__c = 4,
      SBQQ__UpgradedSubscription__c = upgradedSubId1,
      SBQQ__Existing__c = true,
      SBQQ__RequiredBy__c = requiredById1,
      SBQQ__Group__c = quoteLineGroupId1,
      SBQQ__StartDate__c = System.today(),
      SBQQ__EndDate__c = System.today().addMonths(24),
      SBQQ__SubscriptionTerm__c = 24,
      SBQQ__UpgradedAsset__c = upgradedAssetId1,
      SBQQ__Quote__c = originalQuoteId1,
      SBQQ__Number__c = 999
    );
    //

    //QLI2
    Id originalQuoteId2 = fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType);
    Id upgradedSubId2 = fflib_IdGenerator.generate(SBQQ__Subscription__c.SObjectType);
    Id requiredById2 = fflib_IdGenerator.generate(SBQQ__QuoteLine__c.SObjectType);
    Id quoteLineGroupId2 = fflib_IdGenerator.generate(SBQQ__QuoteLineGroup__c.SObjectType);
    Id upgradedAssetId2 = fflib_IdGenerator.generate(Asset.SObjectType);
    SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
      Id = fflib_IdGenerator.generate(SBQQ__QuoteLine__c.SObjectType),
      SBQQ__Quantity__c = 16,
      SBQQ__PriorQuantity__c = 18,
      SBQQ__UpgradedSubscription__c = upgradedSubId2,
      SBQQ__Existing__c = true,
      SBQQ__RequiredBy__c = requiredById2,
      SBQQ__Group__c = quoteLineGroupId2,
      SBQQ__StartDate__c = System.today(),
      SBQQ__EndDate__c = System.today().addMonths(12),
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__UpgradedAsset__c = upgradedAssetId2,
      SBQQ__Quote__c = originalQuoteId2,
      SBQQ__Number__c = 500
    );
    //

    qlis.add(qli1);
    qlis.add(qli2);

    //Act
    CPQConsolidateReplacementLines_SL cpqCrl = new CPQConsolidateReplacementLines_SL(
      new Set<String>{ '123' },
      fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType),
      Logger.getTransactionId()
    );
    List<SBQQ__QuoteLine__c> clonedQlis = cpqCrl.cloneQuoteLinesIntoReplacementQuote(qlis, replacementQuote);
    //

    //Assert
    System.assertEquals(2, clonedQlis.size());
    System.assertEquals(1, clonedQlis.get(0).SBQQ__Number__c);
    System.assertEquals(2, clonedQlis.get(1).SBQQ__Number__c);
    System.assertEquals(4, clonedQlis.get(0).SBQQ__Quantity__c);
    System.assertEquals(18, clonedQlis.get(1).SBQQ__Quantity__c);
    for (SBQQ__QuoteLine__c ql : clonedQlis) {
      System.assert(ql.SBQQ__PriorQuantity__c == null);
      System.assert(ql.SBQQ__UpgradedSubscription__c == null);
      System.assert(ql.SBQQ__UpgradedSubscription__r == null);
      System.assert(!ql.SBQQ__Existing__c);
      System.assert(ql.SBQQ__Group__c == null);
      System.assert(ql.SBQQ__StartDate__c == null);
      System.assert(ql.SBQQ__EndDate__c == null);
      System.assert(ql.SBQQ__SubscriptionTerm__c == null);
      System.assert(ql.SBQQ__UpgradedAsset__c == null);
      System.assertEquals(replacementQuote.Id, ql.SBQQ__Quote__c);
    }
    //
  }

  @isTest
  public static void testGetPriceBookEntryIdByProductCodeByCurrency() {
    Integer iterations = 100;
    Map<Id, PricebookEntry> pbeById = new Map<Id, PricebookEntry>();
    List<String> currencies = new List<String>{ 'USD', 'GBP', 'CAD', 'INR', 'JPY', 'EUR' };

    for (Integer i = 0; i < iterations; i++) {
      for (String cur : currencies) {
        Id dummyId = fflib_IDGenerator.generate(PricebookEntry.SObjectType);
        PricebookEntry pbe = new PricebookEntry(Id = dummyId, CurrencyIsoCode = cur);
        pbe = (PricebookEntry) setFieldJson(pbe, 'ProductCode', 'TestProd-' + i);
        pbeById.put(dummyId, pbe);
      }
    }
    System.assertEquals(iterations * currencies.size(), pbeById.size());

    Map<String, Map<String, Id>> priceBookEntryIdByProductCodeByCurrency = CPQConsolidateReplacementLines_SL.getPriceBookEntryIdByProductCodeByCurrency(
      pbeById
    );

    for (Integer i = 0; i < iterations; i++) {
      System.assertEquals(
        true,
        priceBookEntryIdByProductCodeByCurrency.containsKey('TestProd-' + i),
        'ProductCode \'TestProd-' +
        i +
        '\' was not found'
      );
      for (String cur : currencies) {
        System.assertEquals(
          true,
          priceBookEntryIdByProductCodeByCurrency.get('TestProd-' + i).containsKey(cur),
          'CurrencyIsoCode ' +
          cur +
          '\' for ProductCode \'TestProd-' +
          i +
          '\' was not found'
        );
      }
    }
  }

  @isTest
  public static void testSetQLIpricebookentry_success() {
    //SETUP

    //PriceBook2
    Pricebook2 pb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //original pbe
    PricebookEntry pbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe = (PricebookEntry) setFieldJson(pbe, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe
    PricebookEntry pbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'GBP'
    );
    pbe2 = (PricebookEntry) setFieldJson(pbe2, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe 2
    PricebookEntry pbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe3 = (PricebookEntry) setFieldJson(pbe3, 'ProductCode', 'UiPath02');
    //

    //original PBE map
    Map<Id, PricebookEntry> currentQliPbes = new Map<Id, PricebookEntry>();
    currentQliPbes.put(pbe.Id, pbe);
    currentQliPbes.put(pbe2.Id, pbe2);
    currentQliPbes.put(pbe3.Id, pbe3);
    //

    //create original qli
    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
      Id = fflib_IDGenerator.generate(SBQQ__QuoteLine__c.SObjectType),
      SBQQ__PricebookEntryId__c = pbe.Id,
      CurrencyIsoCode = 'USD'
    );

    //create target Pricebook2
    Pricebook2 targetPb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //target pbes
    //scope
    PricebookEntry targetPbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'USD'
    );
    targetPbe = (PricebookEntry) setFieldJson(targetPbe, 'ProductCode', 'UiPath01');
    //

    //non-scope target pbe - currency
    PricebookEntry targetPbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe2 = (PricebookEntry) setFieldJson(targetPbe2, 'ProductCode', 'UiPath01');
    //

    //target pbe - productCode
    PricebookEntry targetPbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'USD'
    );
    targetPbe3 = (PricebookEntry) setFieldJson(targetPbe3, 'ProductCode', 'UiPath09');
    //

    //non-scope target pbe - productcode and currency
    PricebookEntry targetPbe4 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe4 = (PricebookEntry) setFieldJson(targetPbe4, 'ProductCode', 'UiPath09');
    //

    //target PBE map
    Map<Id, PricebookEntry> tagetQliPbes = new Map<Id, PricebookEntry>();
    tagetQliPbes.put(targetPbe.Id, targetPbe);
    tagetQliPbes.put(targetPbe2.Id, targetPbe2);
    tagetQliPbes.put(targetPbe3.Id, targetPbe3);
    tagetQliPbes.put(targetPbe4.Id, targetPbe4);
    //

    Map<String, Map<String, Id>> priceBookEntryByProductCodeByCurrency = new Map<String, Map<String, Id>>();
    Map<String, Id> priceBookEntryIdByCurrency = new Map<String, Id>();
    priceBookEntryIdByCurrency.put(targetPbe.CurrencyIsoCode, targetPbe.Id);
    priceBookEntryIdByCurrency.put(targetPbe2.CurrencyIsoCode, targetPbe2.Id);
    Map<String, Id> nonScopePriceBookEntryIdByCurrency = new Map<String, Id>();
    nonScopePriceBookEntryIdByCurrency.put(targetPbe3.CurrencyIsoCode, targetPbe3.Id);
    nonScopePriceBookEntryIdByCurrency.put(targetPbe4.CurrencyIsoCode, targetPbe4.Id);
    priceBookEntryByProductCodeByCurrency.put(targetPbe.ProductCode, priceBookEntryIdByCurrency);
    priceBookEntryByProductCodeByCurrency.put(targetPbe4.ProductCode, nonScopePriceBookEntryIdByCurrency);
    //
    Id quotId = fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType);
    CPQConsolidateReplacementLines_SL CPQCrl = new CPQConsolidateReplacementLines_SL(
      new Set<String>{ '123' },
      quotId,
      'originalTransactionId'
    );
    System.assertEquals(
      pbe.Id,
      qli.SBQQ__PricebookEntryId__c,
      'Qli PricebookEntry should be set to the original value'
    );

    //ACT
    CPQCrl.setQLIpricebookentry(qli, currentQliPbes, priceBookEntryByProductCodeByCurrency);

    //ASSERT
    System.assertEquals(
      targetPbe.Id,
      qli.SBQQ__PricebookEntryId__c,
      'Qli PricebookEntry should be set to the new value'
    );
  }

  @isTest
  public static void testSetQLIpricebookentry_failure_originalPbeNotRetrieved() {
    //SETUP

    //PriceBook2
    Pricebook2 pb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //original pbe
    PricebookEntry pbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe = (PricebookEntry) setFieldJson(pbe, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe
    PricebookEntry pbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'GBP'
    );
    pbe2 = (PricebookEntry) setFieldJson(pbe2, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe 2
    PricebookEntry pbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe3 = (PricebookEntry) setFieldJson(pbe3, 'ProductCode', 'UiPath02');
    //

    //original PBE map
    Map<Id, PricebookEntry> currentQliPbes = new Map<Id, PricebookEntry>();
    //currentQliPbes.put(pbe.Id, pbe); - simulate the original PBE not being returned by query
    currentQliPbes.put(pbe2.Id, pbe2);
    currentQliPbes.put(pbe3.Id, pbe3);
    //

    //create original qli
    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
      Id = fflib_IDGenerator.generate(SBQQ__QuoteLine__c.SObjectType),
      SBQQ__PricebookEntryId__c = pbe.Id,
      CurrencyIsoCode = 'USD'
    );

    //create target Pricebook2
    Pricebook2 targetPb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //target pbes
    //scope
    PricebookEntry targetPbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'USD'
    );
    targetPbe = (PricebookEntry) setFieldJson(targetPbe, 'ProductCode', 'UiPath01');
    //

    //non-scope target pbe - currency
    PricebookEntry targetPbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe2 = (PricebookEntry) setFieldJson(targetPbe2, 'ProductCode', 'UiPath01');
    //

    //target pbe - productCode
    PricebookEntry targetPbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'USD'
    );
    targetPbe3 = (PricebookEntry) setFieldJson(targetPbe3, 'ProductCode', 'UiPath09');
    //

    //non-scope target pbe - productcode and currency
    PricebookEntry targetPbe4 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe4 = (PricebookEntry) setFieldJson(targetPbe4, 'ProductCode', 'UiPath09');
    //

    //target PBE map
    Map<Id, PricebookEntry> tagetQliPbes = new Map<Id, PricebookEntry>();
    tagetQliPbes.put(targetPbe.Id, targetPbe);
    tagetQliPbes.put(targetPbe2.Id, targetPbe2);
    tagetQliPbes.put(targetPbe3.Id, targetPbe3);
    tagetQliPbes.put(targetPbe4.Id, targetPbe4);
    //

    Map<String, Map<String, Id>> priceBookEntryByProductCodeByCurrency = new Map<String, Map<String, Id>>();
    Map<String, Id> priceBookEntryIdByCurrency = new Map<String, Id>();
    priceBookEntryIdByCurrency.put(targetPbe.CurrencyIsoCode, targetPbe.Id);
    priceBookEntryIdByCurrency.put(targetPbe2.CurrencyIsoCode, targetPbe2.Id);
    Map<String, Id> nonScopePriceBookEntryIdByCurrency = new Map<String, Id>();
    nonScopePriceBookEntryIdByCurrency.put(targetPbe3.CurrencyIsoCode, targetPbe3.Id);
    nonScopePriceBookEntryIdByCurrency.put(targetPbe4.CurrencyIsoCode, targetPbe4.Id);
    priceBookEntryByProductCodeByCurrency.put(targetPbe.ProductCode, priceBookEntryIdByCurrency);
    priceBookEntryByProductCodeByCurrency.put(targetPbe4.ProductCode, nonScopePriceBookEntryIdByCurrency);
    //
    Id quotId4 = fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType);
    CPQConsolidateReplacementLines_SL CPQCrl = new CPQConsolidateReplacementLines_SL(
      new Set<String>{ '123' },
      quotId4,
      'originalTransactionId'
    );
    System.assertEquals(
      pbe.Id,
      qli.SBQQ__PricebookEntryId__c,
      'Qli PricebookEntry should be set to the original value'
    );

    //ACT
    CPQCrl.setQLIpricebookentry(qli, currentQliPbes, priceBookEntryByProductCodeByCurrency);

    //ASSERT
    System.assertEquals(pbe.Id, qli.SBQQ__PricebookEntryId__c, 'Qli PricebookEntry should still be the original value');
  }

  @isTest
  public static void testSetQLIpricebookentry_failure_targetPricebookNoProductCode() {
    //SETUP

    //PriceBook2
    Pricebook2 pb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //original pbe
    PricebookEntry pbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe = (PricebookEntry) setFieldJson(pbe, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe
    PricebookEntry pbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'GBP'
    );
    pbe2 = (PricebookEntry) setFieldJson(pbe2, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe 2
    PricebookEntry pbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe3 = (PricebookEntry) setFieldJson(pbe3, 'ProductCode', 'UiPath02');
    //

    //original PBE map
    Map<Id, PricebookEntry> currentQliPbes = new Map<Id, PricebookEntry>();
    currentQliPbes.put(pbe.Id, pbe);
    currentQliPbes.put(pbe2.Id, pbe2);
    currentQliPbes.put(pbe3.Id, pbe3);
    //

    //create original qli
    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
      Id = fflib_IDGenerator.generate(SBQQ__QuoteLine__c.SObjectType),
      SBQQ__PricebookEntryId__c = pbe.Id,
      CurrencyIsoCode = 'USD'
    );

    //create target Pricebook2
    Pricebook2 targetPb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //target pbes
    //scope
    PricebookEntry targetPbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'USD'
    );
    targetPbe = (PricebookEntry) setFieldJson(targetPbe, 'ProductCode', 'UiPath099'); // simulate no 'UiPath01' Product code in target PB
    //

    //non-scope target pbe - currency
    PricebookEntry targetPbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe2 = (PricebookEntry) setFieldJson(targetPbe2, 'ProductCode', 'UiPath099'); // simulate no 'UiPath01' Product code in target PB
    //

    //target pbe - productCode
    PricebookEntry targetPbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'USD'
    );
    targetPbe3 = (PricebookEntry) setFieldJson(targetPbe3, 'ProductCode', 'UiPath09');
    //

    //non-scope target pbe - productcode and currency
    PricebookEntry targetPbe4 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe4 = (PricebookEntry) setFieldJson(targetPbe4, 'ProductCode', 'UiPath09');
    //

    //target PBE map
    Map<Id, PricebookEntry> tagetQliPbes = new Map<Id, PricebookEntry>();
    tagetQliPbes.put(targetPbe.Id, targetPbe);
    tagetQliPbes.put(targetPbe2.Id, targetPbe2);
    tagetQliPbes.put(targetPbe3.Id, targetPbe3);
    tagetQliPbes.put(targetPbe4.Id, targetPbe4);
    //

    Map<String, Map<String, Id>> priceBookEntryByProductCodeByCurrency = new Map<String, Map<String, Id>>();
    Map<String, Id> priceBookEntryIdByCurrency = new Map<String, Id>();
    priceBookEntryIdByCurrency.put(targetPbe.CurrencyIsoCode, targetPbe.Id);
    priceBookEntryIdByCurrency.put(targetPbe2.CurrencyIsoCode, targetPbe2.Id);
    Map<String, Id> nonScopePriceBookEntryIdByCurrency = new Map<String, Id>();
    nonScopePriceBookEntryIdByCurrency.put(targetPbe3.CurrencyIsoCode, targetPbe3.Id);
    nonScopePriceBookEntryIdByCurrency.put(targetPbe4.CurrencyIsoCode, targetPbe4.Id);
    priceBookEntryByProductCodeByCurrency.put(targetPbe.ProductCode, priceBookEntryIdByCurrency);
    priceBookEntryByProductCodeByCurrency.put(targetPbe4.ProductCode, nonScopePriceBookEntryIdByCurrency);
    //
    Id quotId3 = fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType);
    CPQConsolidateReplacementLines_SL CPQCrl = new CPQConsolidateReplacementLines_SL(
      new Set<String>{ '123' },
      quotId3,
      'originalTransactionId'
    );
    System.assertEquals(
      pbe.Id,
      qli.SBQQ__PricebookEntryId__c,
      'Qli PricebookEntry should be set to the original value'
    );

    //ACT
    CPQCrl.setQLIpricebookentry(qli, currentQliPbes, priceBookEntryByProductCodeByCurrency);

    //ASSERT
    System.assertEquals(pbe.Id, qli.SBQQ__PricebookEntryId__c, 'Qli PricebookEntry should still be the original value');
  }

  @isTest
  public static void testSetQLIpricebookentry_failure_targetPricebookNoProductCodeCurrency() {
    //SETUP

    //PriceBook2
    Pricebook2 pb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //original pbe
    PricebookEntry pbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe = (PricebookEntry) setFieldJson(pbe, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe
    PricebookEntry pbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'GBP'
    );
    pbe2 = (PricebookEntry) setFieldJson(pbe2, 'ProductCode', 'UiPath01');
    //

    //non-scope pbe 2
    PricebookEntry pbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = pb.Id,
      CurrencyIsoCode = 'USD'
    );
    pbe3 = (PricebookEntry) setFieldJson(pbe3, 'ProductCode', 'UiPath02');
    //

    //original PBE map
    Map<Id, PricebookEntry> currentQliPbes = new Map<Id, PricebookEntry>();
    currentQliPbes.put(pbe.Id, pbe);
    currentQliPbes.put(pbe2.Id, pbe2);
    currentQliPbes.put(pbe3.Id, pbe3);
    //

    //create original qli
    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
      Id = fflib_IDGenerator.generate(SBQQ__QuoteLine__c.SObjectType),
      SBQQ__PricebookEntryId__c = pbe.Id,
      CurrencyIsoCode = 'USD'
    );

    //create target Pricebook2
    Pricebook2 targetPb = new Pricebook2(Id = fflib_IDGenerator.generate(Pricebook2.SObjectType));
    //

    //target pbes
    //scope
    PricebookEntry targetPbe = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'INR' //simulates no USD PBE for this ProductCode in the target PB
    );
    targetPbe = (PricebookEntry) setFieldJson(targetPbe, 'ProductCode', 'UiPath01');
    //

    //non-scope target pbe - currency
    PricebookEntry targetPbe2 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe2 = (PricebookEntry) setFieldJson(targetPbe2, 'ProductCode', 'UiPath01');
    //

    //target pbe - productCode
    PricebookEntry targetPbe3 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'USD'
    );
    targetPbe3 = (PricebookEntry) setFieldJson(targetPbe3, 'ProductCode', 'UiPath09');
    //

    //non-scope target pbe - productcode and currency
    PricebookEntry targetPbe4 = new PricebookEntry(
      Id = fflib_IDGenerator.generate(PricebookEntry.SObjectType),
      Pricebook2Id = targetPb.Id,
      CurrencyIsoCode = 'GBP'
    );
    targetPbe4 = (PricebookEntry) setFieldJson(targetPbe4, 'ProductCode', 'UiPath09');
    //

    //target PBE map
    Map<Id, PricebookEntry> tagetQliPbes = new Map<Id, PricebookEntry>();
    tagetQliPbes.put(targetPbe.Id, targetPbe);
    tagetQliPbes.put(targetPbe2.Id, targetPbe2);
    tagetQliPbes.put(targetPbe3.Id, targetPbe3);
    tagetQliPbes.put(targetPbe4.Id, targetPbe4);
    //

    Map<String, Map<String, Id>> priceBookEntryByProductCodeByCurrency = new Map<String, Map<String, Id>>();
    Map<String, Id> priceBookEntryIdByCurrency = new Map<String, Id>();
    priceBookEntryIdByCurrency.put(targetPbe.CurrencyIsoCode, targetPbe.Id);
    priceBookEntryIdByCurrency.put(targetPbe2.CurrencyIsoCode, targetPbe2.Id);
    Map<String, Id> nonScopePriceBookEntryIdByCurrency = new Map<String, Id>();
    nonScopePriceBookEntryIdByCurrency.put(targetPbe3.CurrencyIsoCode, targetPbe3.Id);
    nonScopePriceBookEntryIdByCurrency.put(targetPbe4.CurrencyIsoCode, targetPbe4.Id);
    priceBookEntryByProductCodeByCurrency.put(targetPbe.ProductCode, priceBookEntryIdByCurrency);
    priceBookEntryByProductCodeByCurrency.put(targetPbe4.ProductCode, nonScopePriceBookEntryIdByCurrency);
    //
    Id quotId2 = fflib_IdGenerator.generate(SBQQ__Quote__c.SObjectType);
    CPQConsolidateReplacementLines_SL CPQCrl = new CPQConsolidateReplacementLines_SL(
      new Set<String>{ '123' },
      quotId2,
      'originalTransactionId'
    );
    System.assertEquals(
      pbe.Id,
      qli.SBQQ__PricebookEntryId__c,
      'Qli PricebookEntry should be set to the original value'
    );

    //ACT
    CPQCrl.setQLIpricebookentry(qli, currentQliPbes, priceBookEntryByProductCodeByCurrency);

    //ASSERT
    System.assertEquals(pbe.Id, qli.SBQQ__PricebookEntryId__c, 'Qli PricebookEntry should still be the original value');
  }

  private static SObject setFieldJson(SObject sObj, String fieldName, Object value) {
    String jsonString = JSON.serialize(sObj);
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    dataMap.put(fieldName, value);
    jsonString = JSON.serialize(dataMap);
    return (SObject) JSON.deserialize(jsonString, SObject.class);
  }
}