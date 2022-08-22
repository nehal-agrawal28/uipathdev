@isTest(isParallel=false)
public with sharing class OppDefaultTypeFunctionTest_SL {
  private static final String ASSERT_MSG_COLL_EMPTY = 'Collection should be empty';
  private static final String ASSERT_MSG_COLL_NULL = 'Collection should not be null';
  private static final String ASSERT_MSG_EXC = 'No exception should have been thrown';
  private static final String ASSERT_MSG_RR = 'Expected \'Upsell\' Type for RR replacement opps';
  private static final String ASSERT_MSG_RENEWAL = 'Expected \'Renewal\' Type';
  private static final String ASSERT_MSG_NEW_BIZ = 'Expected \'New Business\' Type';
  private static final string RR_TYPE = 'RR';
  private static final string NEW_BIZ_TYPE = Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS;
  private static final string UPSELL_TYPE = Constants_SL.OPPORTUNITY_TYPE_UPSELL;
  private static final string RENEWAL_TYPE = Constants_SL.OPPORTUNITY_TYPE_RENEWAL;
  private static final Map<String, Id> OPP_TYPE_TO_OPP_ID = new Map<String, Id>{
    NEW_BIZ_TYPE => fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    UPSELL_TYPE => fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    RENEWAL_TYPE => fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    RR_TYPE => fflib_IDGenerator.generate(Opportunity.getSObjectType())
  };
  private static final Map<String, Id> OPP_TYPE_TO_ACC_ID = new Map<String, Id>{
    NEW_BIZ_TYPE => fflib_IDGenerator.generate(Account.getSObjectType()),
    UPSELL_TYPE => fflib_IDGenerator.generate(Account.getSObjectType()),
    RENEWAL_TYPE => fflib_IDGenerator.generate(Account.getSObjectType()),
    RR_TYPE => fflib_IDGenerator.generate(Account.getSObjectType())
  };
  private static final Map<String, Account> OPP_TYPE_TO_ACCOUNT {
    get {
      if (OPP_TYPE_TO_ACCOUNT == null) {
        OPP_TYPE_TO_ACCOUNT = new Map<String, Account>();
        for (String oppType : OPP_TYPE_TO_ACC_ID.keySet()) {
          OPP_TYPE_TO_ACCOUNT.put(oppType, new Account(Id = OPP_TYPE_TO_ACC_ID.get(oppType)));
        }
      }
      return OPP_TYPE_TO_ACCOUNT;
    }
    set;
  }
  private static final Set<Id> ACCOUNT_IDS = new Set<Id>(OPP_TYPE_TO_ACC_ID.values());
  private static final List<Account> UPSELL_ACCOUNTS = new List<Account>{ OPP_TYPE_TO_ACCOUNT.get(UPSELL_TYPE) };

  //SETUP
  public static void setup() {
    Account acc = DataFactory_SL.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
  }

  //INTEGRATIONS
  @isTest
  public static void itShouldCorrectlySetOppTypeToNewBusiness() {
    //GIVEN
    setup();
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = DataFactory_SL.createOpportunity(acc.Id, false);

    //WHEN
    insert opp;

    //THEN
    opp = [SELECT Id, Type FROM Opportunity LIMIT 1];
    System.assertEquals(NEW_BIZ_TYPE, opp.Type, ASSERT_MSG_NEW_BIZ);
  }

  @isTest
  public static void itShouldCorrectlySetOppTypeToRenewal() {
    //GIVEN
    setup();
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = DataFactory_SL.createOpportunity(acc.Id, false);
    opp.SBQQ__Renewal__c = true;

    //WHEN
    insert opp;

    //THEN
    opp = [SELECT Id, Type FROM Opportunity LIMIT 1];
    System.assertEquals(RENEWAL_TYPE, opp.Type, ASSERT_MSG_RENEWAL);
  }

  @isTest
  public static void itShouldCorrectlySetOppTypeToUpsellRr() {
    //GIVEN
    setup();
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = DataFactory_SL.createOpportunity(acc.Id, false);
    opp.Replacement_Transaction__c = true;

    //WHEN
    insert opp;

    //THEN
    opp = [SELECT Id, Type FROM Opportunity LIMIT 1];
    System.assertEquals(UPSELL_TYPE, opp.Type, ASSERT_MSG_RR);
  }

  //UNITS

  @isTest
  public static void itShouldDeriveTypeNewBiz() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AccountsSelector_SL mockSelector = setAccountSelectorMock(mocks, ACCOUNT_IDS, UPSELL_ACCOUNTS);

    /// RR opp
    Opportunity rrOpp5 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RR_TYPE),
      Replacement_Transaction__c = true,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RR_TYPE)
    );
    ///new business opp
    Opportunity newBizOpp5 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(NEW_BIZ_TYPE)
    );
    ///renewal opp
    Opportunity renewalOpp5 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RENEWAL_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = true,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RENEWAL_TYPE)
    );
    ///upsell opp
    Opportunity upsellOpp5 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(Constants_SL.OPPORTUNITY_TYPE_UPSELL),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(UPSELL_TYPE)
    );

    ///collections
    List<Opportunity> opps = new List<Opportunity>{ newBizOpp5, rrOpp5, renewalOpp5, upsellOpp5 };
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);

    //WHEN
    OppDefaultTypeFunction_SL.deriveType(opps);

    //THEN
    ((AccountsSelector_SL) mocks.verify(mockSelector, 1)).getAccountsWithWonOppsById(ACCOUNT_IDS, false);
    System.assertEquals(
      NEW_BIZ_TYPE,
      oppMap.get(OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE)).Type,
      'Expected \'New Business\' Type'
    );
  }

  @isTest
  public static void itShouldDeriveTypeRenewal() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AccountsSelector_SL mockSelector = setAccountSelectorMock(mocks, ACCOUNT_IDS, UPSELL_ACCOUNTS);

    /// RR opp
    Opportunity rrOpp4 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RR_TYPE),
      Replacement_Transaction__c = true,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RR_TYPE)
    );
    ///new business opp
    Opportunity newBizOpp4 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(NEW_BIZ_TYPE)
    );
    ///renewal opp
    Opportunity renewalOpp4 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RENEWAL_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = true,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RENEWAL_TYPE)
    );
    ///upsell opp
    Opportunity upsellOpp4 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(Constants_SL.OPPORTUNITY_TYPE_UPSELL),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(UPSELL_TYPE)
    );

    ///collections
    List<Opportunity> opps = new List<Opportunity>{ newBizOpp4, rrOpp4, renewalOpp4, upsellOpp4 };
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);

    //WHEN
    OppDefaultTypeFunction_SL.deriveType(opps);

    //THEN
    ((AccountsSelector_SL) mocks.verify(mockSelector, 1)).getAccountsWithWonOppsById(ACCOUNT_IDS, false);
    System.assertEquals(RENEWAL_TYPE, oppMap.get(OPP_TYPE_TO_OPP_ID.get(RENEWAL_TYPE)).Type, ASSERT_MSG_RENEWAL);
  }
  @isTest
  public static void itShouldDeriveTypeRipReplace() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AccountsSelector_SL mockSelector = setAccountSelectorMock(mocks, ACCOUNT_IDS, UPSELL_ACCOUNTS);

    /// RR opp
    Opportunity rrOpp3 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RR_TYPE),
      Replacement_Transaction__c = true,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RR_TYPE)
    );
    ///new business opp
    Opportunity newBizOpp3 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(NEW_BIZ_TYPE)
    );
    ///renewal opp
    Opportunity renewalOpp3 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RENEWAL_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = true,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RENEWAL_TYPE)
    );
    ///upsell opp
    Opportunity upsellOpp3 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(Constants_SL.OPPORTUNITY_TYPE_UPSELL),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(UPSELL_TYPE)
    );

    ///collections
    List<Opportunity> opps = new List<Opportunity>{ newBizOpp3, rrOpp3, renewalOpp3, upsellOpp3 };
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);

    //WHEN
    OppDefaultTypeFunction_SL.deriveType(opps);

    //THEN
    ((AccountsSelector_SL) mocks.verify(mockSelector, 1)).getAccountsWithWonOppsById(ACCOUNT_IDS, false);
    System.assertEquals(UPSELL_TYPE, oppMap.get(OPP_TYPE_TO_OPP_ID.get(RR_TYPE)).Type, ASSERT_MSG_RR);
  }

  @isTest
  public static void itShouldDeriveTypeUpsell() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AccountsSelector_SL mockSelector = setAccountSelectorMock(mocks, ACCOUNT_IDS, UPSELL_ACCOUNTS);

    /// RR opp
    Opportunity rrOpp2 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RR_TYPE),
      Replacement_Transaction__c = true,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RR_TYPE)
    );
    ///new business opp
    Opportunity newBizOpp2 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(NEW_BIZ_TYPE)
    );
    ///renewal opp
    Opportunity renewalOpp2 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RENEWAL_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = true,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RENEWAL_TYPE)
    );
    ///upsell opp
    Opportunity upsellOpp2 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(Constants_SL.OPPORTUNITY_TYPE_UPSELL),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(UPSELL_TYPE)
    );

    ///collections
    List<Opportunity> opps = new List<Opportunity>{ newBizOpp2, rrOpp2, renewalOpp2, upsellOpp2 };
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);

    //WHEN
    OppDefaultTypeFunction_SL.deriveType(opps);

    //THEN
    ((AccountsSelector_SL) mocks.verify(mockSelector, 1)).getAccountsWithWonOppsById(ACCOUNT_IDS, false);
    System.assertEquals(UPSELL_TYPE, oppMap.get(OPP_TYPE_TO_OPP_ID.get(UPSELL_TYPE)).Type, 'Expected \'Upsell\' Type');
  }

  @isTest
  public static void itShouldDeriveTypeNullRenewal() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AccountsSelector_SL mockSelector = setAccountSelectorMock(mocks, ACCOUNT_IDS, UPSELL_ACCOUNTS);

    /// RR opp
    Opportunity rrOpp1 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RR_TYPE),
      Replacement_Transaction__c = true,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RR_TYPE)
    );
    ///new business opp
    Opportunity newBizOpp1 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE),
      Replacement_Transaction__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(NEW_BIZ_TYPE)
    );
    ///renewal opp
    Opportunity renewalOpp1 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RENEWAL_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = true,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RENEWAL_TYPE)
    );
    ///upsell opp
    Opportunity upsellOpp1 = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(Constants_SL.OPPORTUNITY_TYPE_UPSELL),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(UPSELL_TYPE)
    );

    ///collections
    List<Opportunity> opps = new List<Opportunity>{ newBizOpp1, rrOpp1, renewalOpp1, upsellOpp1 };
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);
    String excMsg;

    //WHEN
    try {
      OppDefaultTypeFunction_SL.deriveType(opps);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_EXC);
    ((AccountsSelector_SL) mocks.verify(mockSelector, 1)).getAccountsWithWonOppsById(ACCOUNT_IDS, false);
    System.assertEquals(NEW_BIZ_TYPE, oppMap.get(OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE)).Type, ASSERT_MSG_NEW_BIZ);
  }

  @isTest
  public static void itShouldDeriveTypeNullReplacementTransaction() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    AccountsSelector_SL mockSelector = setAccountSelectorMock(mocks, ACCOUNT_IDS, UPSELL_ACCOUNTS);

    /// RR opp
    Opportunity rrOpp = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RR_TYPE),
      Replacement_Transaction__c = true,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RR_TYPE)
    );
    ///new business opp
    Opportunity newBizOpp = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE),
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(NEW_BIZ_TYPE)
    );
    ///renewal opp
    Opportunity renewalOpp = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(RENEWAL_TYPE),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = true,
      AccountId = OPP_TYPE_TO_ACC_ID.get(RENEWAL_TYPE)
    );
    ///upsell opp
    Opportunity upsellOpp = new Opportunity(
      Id = OPP_TYPE_TO_OPP_ID.get(Constants_SL.OPPORTUNITY_TYPE_UPSELL),
      Replacement_Transaction__c = false,
      SBQQ__Renewal__c = false,
      AccountId = OPP_TYPE_TO_ACC_ID.get(UPSELL_TYPE)
    );

    ///collections
    List<Opportunity> opps = new List<Opportunity>{ newBizOpp, rrOpp, renewalOpp, upsellOpp };
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);
    String excMsg;

    //WHEN
    try {
      OppDefaultTypeFunction_SL.deriveType(opps);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_EXC);
    ((AccountsSelector_SL) mocks.verify(mockSelector, 1)).getAccountsWithWonOppsById(ACCOUNT_IDS, false);
    System.assertEquals(NEW_BIZ_TYPE, oppMap.get(OPP_TYPE_TO_OPP_ID.get(NEW_BIZ_TYPE)).Type, ASSERT_MSG_NEW_BIZ);
  }

  @isTest
  public static void itShouldReturnAnEmptyAccountSetNull() {
    //GIVEN
    AccountsSelector_SL accountSelector = (AccountsSelector_SL) Application_SL.Selector.newInstance(
      Account.getSObjectType()
    );
    List<Account> accounts;
    String excMsg;
    Set<Id> accIds;

    //WHEN
    try {
      accounts = accountSelector.getAccountsWithWonOppsById(accIds, false);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_EXC);
    System.assertNotEquals(null, accounts, ASSERT_MSG_COLL_NULL);
    System.assertEquals(0, accounts.size(), ASSERT_MSG_COLL_EMPTY);
  }

  @isTest
  public static void itShouldReturnAnEmptyAccountSetEmpty() {
    //GIVEN
    AccountsSelector_SL accountSelector = (AccountsSelector_SL) Application_SL.Selector.newInstance(
      Account.getSObjectType()
    );
    List<Account> accounts;
    String excMsg;
    Set<Id> accIds = new Set<Id>();

    //WHEN
    try {
      accounts = accountSelector.getAccountsWithWonOppsById(accIds, false);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_EXC);
    System.assertNotEquals(null, accounts, ASSERT_MSG_COLL_NULL);
    System.assertEquals(0, accounts.size(), ASSERT_MSG_COLL_EMPTY);
  }

  @isTest
  public static void itShouldHandleEmptyArg() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    String excMsg;

    //WHEN
    try {
      OppDefaultTypeFunction_SL.deriveType(opps);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_EXC);
  }

  @isTest
  public static void itShouldHandleNullArg() {
    //GIVEN
    List<Opportunity> opps;
    String excMsg;

    //WHEN
    try {
      OppDefaultTypeFunction_SL.deriveType(opps);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_EXC);
  }

  //UTILS
  private static AccountsSelector_SL setAccountSelectorMock(
    fflib_ApexMocks mocks,
    Set<Id> accountIds,
    List<Account> accountsToReturn
  ) {
    AccountsSelector_SL mockSelector = (AccountsSelector_SL) mocks.mock(AccountsSelector_SL.class);

    mocks.startStubbing();
    mocks.when(mockSelector.getSObjectType()).thenReturn(Account.SObjectType);
    mocks.when(mockSelector.sObjectType()).thenReturn(Account.SObjectType);
    mocks.when(mockSelector.getAccountsWithWonOppsById(accountIds, false)).thenReturn(accountsToReturn);
    mocks.stopStubbing();
    Application_SL.Selector.setMock(mockSelector);

    return mockSelector;
  }
}