@isTest
public with sharing class CasesSelectorTest_SL {
  private static final Id CASE_FINANCE_REQUEST_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
    .get(Constants.CASE_RECORD_TYPE_2)
    .getRecordTypeId();
  private static final Id CASE_LEGAL_REQUEST_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
    .get(Constants.CASE_RECORD_TYPE_1)
    .getRecordTypeId();

  private static void setup() {
    Account acc = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    Case case1 = DataFactory_SL.createCase(CASE_LEGAL_REQUEST_RT_ID, false);
    case1.AccountId = acc.Id;
    Case case2 = DataFactory_SL.createCase(CASE_FINANCE_REQUEST_RT_ID, false);
    case2.AccountId = acc.Id;
    insert new List<Case>{ case1, case2 };
  }

  @isTest
  public static void itShouldSelectByIds() {
    //GIVEN
    setup();
    CasesSelector_SL selector = (CasesSelector_SL) Application_SL.Selector.newInstance(Case.SObjectType);
    Case case2 = [SELECT Id FROM Case WHERE RecordType.DeveloperName = :Constants.CASE_RECORD_TYPE_2 LIMIT 1];

    //WHEN
    List<Case> cases = selector.selectById(new Set<Id>{ case2.Id }, false);

    //THEN
    System.assertEquals(1, cases.size(), 'Returned records collection is the incorrect size');
    System.assertEquals(case2.Id, cases[0].Id, 'Returned records collection is missing the expected record');
  }

  @isTest
  public static void itShouldSelectByIds_withSecurity() {
    //GIVEN
    setup();
    CasesSelector_SL selector = (CasesSelector_SL) Application_SL.Selector.newInstance(Case.SObjectType);
    Case case2 = [SELECT Id FROM Case WHERE RecordType.DeveloperName = :Constants.CASE_RECORD_TYPE_2 LIMIT 1];

    //WHEN
    List<Case> cases = selector.selectById(new Set<Id>{ case2.Id }, true);

    //THEN
    System.assertEquals(1, cases.size(), 'Returned records collection is the incorrect size');
    System.assertEquals(case2.Id, cases[0].Id, 'Returned records collection is missing the expected record');
  }

  @isTest
  public static void itShouldSelectReplacementTransactionQuoteIdsByCaseId_emptyArg() {
    //GIVEN
    setup();
    CasesSelector_SL selector = (CasesSelector_SL) Application_SL.Selector.newInstance(Case.SObjectType);

    //WHEN
    List<Case> cases = selector.selectReplacementTransactionQuoteIdsByCaseId(new Set<Id>(), false);

    //THEN
    System.assertEquals(0, cases.size(), 'Returned records collection is the incorrect size');
  }

  @isTest
  public static void itShouldSelectReplacementTransactionQuoteIdsByCaseId_withSecurity() {
    //GIVEN
    setup();
    CasesSelector_SL selector = (CasesSelector_SL) Application_SL.Selector.newInstance(Case.SObjectType);
    Case case2 = [SELECT Id FROM Case WHERE RecordType.DeveloperName = :Constants.CASE_RECORD_TYPE_2 LIMIT 1];

    //WHEN
    List<Case> cases = selector.selectReplacementTransactionQuoteIdsByCaseId(new Set<Id>{ case2.Id }, true);

    //THEN
    System.assertEquals(0, cases.size(), 'Returned records collection is the incorrect size');
  }

  @isTest
  public static void itShouldSelectCancellationTransactionCasesByReplacementQuoteIds_emptyArg() {
    //GIVEN
    setup();
    CasesSelector_SL selector = (CasesSelector_SL) Application_SL.Selector.newInstance(Case.SObjectType);

    //WHEN
    List<Case> cases = selector.selectCancellationTransactionCasesByReplacementQuoteIds(new Set<Id>(), false);

    //THEN
    System.assertEquals(0, cases.size(), 'Returned records collection is the incorrect size');
  }

  @isTest
  public static void itShouldSelectCancellationTransactionCasesByReplacementQuoteIds_withSecurity() {
    //GIVEN
    setup();
    CasesSelector_SL selector = (CasesSelector_SL) Application_SL.Selector.newInstance(Case.SObjectType);
    Id quoteId = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType());

    //WHEN
    List<Case> cases = selector.selectCancellationTransactionCasesByReplacementQuoteIds(new Set<Id>{ quoteId }, true);

    //THEN
    System.assertEquals(0, cases.size(), 'Returned records collection is the incorrect size');
  }
}