@isTest(isParallel=false)
private class OppUpdateAccountQueueableTest_SL {
  private static final String FIRST_ACCOUNT_NAME = 'First Account';
  private static final String SECOND_ACCOUNT_NAME = 'Second Account';
  private static final Date FIRST_EARLY_DATE = Date.Today().addDays(10);
  private static final Date SECOND_EARLY_DATE = Date.Today().addDays(17);

  @testSetup
  static void setup() {
    Account testAccountOne = DataFactory_CM.createAccount('Customer', false);
    Account testAccountTwo = DataFactory_CM.createAccount('Customer', false);
    testAccountOne.Name = FIRST_ACCOUNT_NAME;
    testAccountTwo.Name = SECOND_ACCOUNT_NAME;
    insert new List<Account>{ testAccountOne, testAccountTwo };

    Opportunity oppAccount_One_1 = DataFactory_SL.createOpportunity(testAccountOne.Id, false);
    Opportunity oppAccount_One_2 = DataFactory_SL.createOpportunity(testAccountOne.Id, false);
    Opportunity oppAccount_One_3 = DataFactory_SL.createOpportunity(testAccountOne.Id, false);
    Opportunity oppAccount_Two_1 = DataFactory_SL.createOpportunity(testAccountTwo.Id, false);
    Opportunity oppAccount_Two_2 = DataFactory_SL.createOpportunity(testAccountTwo.Id, false);
    Opportunity oppAccount_Two_3 = DataFactory_SL.createOpportunity(testAccountTwo.Id, false);

    oppAccount_One_1.Renewal_Expiry_Date__c = FIRST_EARLY_DATE;
    oppAccount_One_2.Renewal_Expiry_Date__c = Date.Today().addDays(40);
    oppAccount_One_3.Renewal_Expiry_Date__c = Date.Today().addDays(30);
    oppAccount_Two_1.Renewal_Expiry_Date__c = Date.Today().addDays(49);
    oppAccount_Two_2.Renewal_Expiry_Date__c = Date.Today().addDays(56);
    oppAccount_Two_3.Renewal_Expiry_Date__c = SECOND_EARLY_DATE;

    List<Opportunity> opps = new List<Opportunity>();
    opps.add(oppAccount_One_1);
    opps.add(oppAccount_One_2);
    opps.add(oppAccount_One_3);
    opps.add(oppAccount_Two_1);
    opps.add(oppAccount_Two_2);
    opps.add(oppAccount_Two_3);

    insert opps;
  }

  @isTest
  private static void onInsert_setRenewalExpiryDate() {
    List<Account> testAccounts = [SELECT Id, Name, Earliest_Renewal_Expiry_Date__c FROM Account];
    List<Id> accountIds = Collection.of(testAccounts).pluckIds();
    Map<String, Date> expectedEarlyDates = new Map<String, Date>{
      FIRST_ACCOUNT_NAME => FIRST_EARLY_DATE,
      SECOND_ACCOUNT_NAME => SECOND_EARLY_DATE
    };

    Test.startTest();
    new OppUpdateAccountQueueable_SL(accountIds).work();
    Test.stopTest();

    for (Account acc : [SELECT Id, Name, Earliest_Renewal_Expiry_Date__c FROM Account]) {
      System.assertEquals(
        expectedEarlyDates.get(acc.Name),
        acc.Earliest_Renewal_Expiry_Date__c,
        'Incorrect Renewal Expiry Date on ' + acc.Name
      );
    }
  }

  @isTest
  private static void onUpdate_setRenewalExpiryDate() {
    List<Account> testAccounts = [SELECT Id, Name, Earliest_Renewal_Expiry_Date__c FROM Account];
    List<Id> accountIds = Collection.of(testAccounts).pluckIds();

    List<Opportunity> allOpps = [SELECT Id, AccountId, Renewal_Expiry_Date__c FROM Opportunity];
    Date firstEarlyDate = Date.Today().addDays(2);
    Date secondEarlyDate = Date.Today().addDays(18);
    for (Opportunity opp : allOpps) {
      if (opp.Renewal_Expiry_Date__c == FIRST_EARLY_DATE) {
        opp.Renewal_Expiry_Date__c = firstEarlyDate;
      }
      if (opp.Renewal_Expiry_Date__c == SECOND_EARLY_DATE) {
        opp.Renewal_Expiry_Date__c = secondEarlyDate;
      }
    }
    update allOpps;

    Map<String, Date> expectedEarlyDates = new Map<String, Date>{
      FIRST_ACCOUNT_NAME => firstEarlyDate,
      SECOND_ACCOUNT_NAME => secondEarlyDate
    };

    Test.startTest();
    new OppUpdateAccountQueueable_SL(accountIds).work();
    Test.stopTest();

    for (Account acc : [SELECT Id, Name, Earliest_Renewal_Expiry_Date__c FROM Account]) {
      System.assertEquals(
        expectedEarlyDates.get(acc.Name),
        acc.Earliest_Renewal_Expiry_Date__c,
        'Incorrect Renewal Expiry Date on ' + acc.Name
      );
    }
  }

  @isTest
  private static void onDelete_setRenewalExpiryDate() {
    List<Account> testAccounts = [SELECT Id, Name, Earliest_Renewal_Expiry_Date__c FROM Account];
    List<Id> accountIds = Collection.of(testAccounts).pluckIds();

    List<Opportunity> oppToDelete = [
      SELECT Id, AccountId, Renewal_Expiry_Date__c
      FROM Opportunity
      WHERE Renewal_Expiry_Date__c IN (:FIRST_EARLY_DATE, :SECOND_EARLY_DATE)
    ];

    delete oppToDelete;

    Test.startTest();
    new OppUpdateAccountQueueable_SL(accountIds).work();
    Test.stopTest();

    for (Account acc : [SELECT Id, Name, Earliest_Renewal_Expiry_Date__c FROM Account]) {
      if (acc.Name == FIRST_ACCOUNT_NAME)
        System.assertEquals(Date.Today().addDays(30), acc.Earliest_Renewal_Expiry_Date__c);
      if (acc.Name == SECOND_ACCOUNT_NAME)
        System.assertEquals(Date.Today().addDays(49), acc.Earliest_Renewal_Expiry_Date__c);
    }
  }
}