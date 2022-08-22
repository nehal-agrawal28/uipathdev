@isTest(isParallel=false)
private class OppDealRegistrationOwnerQueueableTest_SL {
  private static final String SALES_PARTNER_EMAIL = 'randomemail@testdomain.com';
  private static final String ERROR_MESSAGE = 'Opp Owner is set incorrectly';

  @testSetup
  static void setup() {
    User testUser = DataFactory_CM.createUser('Test', 'User', 'System Administrator', true);
    List<Account> testAccounts = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 2, false);
    testAccounts.get(0).Name = 'Non BPO Account';
    testAccounts.get(0).OwnerId = testUser.Id;
    testAccounts.get(1).OwnerId = testUser.Id;
    testAccounts.get(1).Name = 'BPO Account';
    insert testAccounts;
    Opportunity opp = DataFactory_SL.createOpportunity(testAccounts.get(0).Id, false);
    opp.RecordTypeId = OpportunityMetadata_SL.DealRegistrationRecordType;
    opp.Deal_Reg_Status__c = 'Submitted';
    opp.Deal_Type__c = 'BPO';
    opp.BPO_MS_End_Customer__c = testAccounts.get(1).Id;
    opp.Partner_Sales_Email__c = SALES_PARTNER_EMAIL;
    insert opp;
  }

  @isTest
  private static void setBPOOwnerOnInsert() {
    Account testAccount = [SELECT Id FROM Account WHERE Name = 'BPO Account' LIMIT 1];
    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, false);
    opp.RecordTypeId = OpportunityMetadata_SL.DealRegistrationRecordType;
    opp.Deal_Reg_Status__c = 'Submitted';
    opp.Do_We_Know_End_Customer__c = 'Yes';
    opp.Deal_Type__c = 'BPO';
    opp.Name = 'BPO';
    opp.BPO_MS_End_Customer__c = testAccount.Id;
    opp.Partner_Sales_Email__c = SALES_PARTNER_EMAIL;
    insert opp;

    OppDealRegistrationOwnerQueueable_SL queueable = new OppDealRegistrationOwnerQueueable_SL(
      new List<Opportunity>{ opp }
    );
    queueable.execute(null);

    Test.startTest();
    Opportunity updatedOpp = [SELECT Id, OwnerId, Account.OwnerId FROM Opportunity WHERE Name = 'BPO' LIMIT 1];
    System.assertEquals(updatedOpp.OwnerId, updatedOpp.Account.OwnerId, ERROR_MESSAGE);
    Test.stopTest();
  }

  @isTest
  private static void setNoBPOOwnerOnInsert() {
    Account testAccount = [SELECT Id FROM Account WHERE Name = 'BPO Account' LIMIT 1];
    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, false);
    opp.RecordTypeId = OpportunityMetadata_SL.DealRegistrationRecordType;
    opp.Deal_Reg_Status__c = 'Submitted';
    opp.Do_We_Know_End_Customer__c = 'No';
    opp.Deal_Type__c = 'BPO';
    opp.Name = 'No BPO';
    opp.Partner_Sales_Email__c = SALES_PARTNER_EMAIL;
    insert opp;

    OppDealRegistrationOwnerQueueable_SL queueable = new OppDealRegistrationOwnerQueueable_SL(
      new List<Opportunity>{ opp }
    );
    queueable.execute(null);

    Test.startTest();
    Opportunity updatedOpp = [SELECT Id, OwnerId, Account.OwnerId FROM Opportunity WHERE Name = 'No BPO' LIMIT 1];
    System.assertEquals(updatedOpp.OwnerId, updatedOpp.Account.OwnerId, ERROR_MESSAGE);
    Test.stopTest();
  }

  @isTest
  private static void setBPOOwnerOnUpdate() {
    Opportunity opp = [SELECT Id, OwnerId, Account.OwnerId FROM Opportunity LIMIT 1];
    opp.Do_We_Know_End_Customer__c = 'Yes';
    update opp;

    OppDealRegistrationOwnerQueueable_SL queueable = new OppDealRegistrationOwnerQueueable_SL(
      new List<Opportunity>{ opp }
    );
    queueable.execute(null);

    Test.startTest();
    Opportunity updatedOpp = [SELECT Id, OwnerId, BPO_MS_End_Customer__r.OwnerId FROM Opportunity LIMIT 1];
    System.assertEquals(updatedOpp.OwnerId, updatedOpp.BPO_MS_End_Customer__r.OwnerId, ERROR_MESSAGE);
    Test.stopTest();
  }

  @isTest
  private static void setNoBPOOwnerOnUpdate() {
    Opportunity opp = [SELECT Id, OwnerId, Account.OwnerId FROM Opportunity LIMIT 1];
    opp.Do_We_Know_End_Customer__c = 'No';
    update opp;

    OppDealRegistrationOwnerQueueable_SL queueable = new OppDealRegistrationOwnerQueueable_SL(
      new List<Opportunity>{ opp }
    );
    queueable.execute(null);

    Test.startTest();
    Opportunity updatedOpp = [SELECT Id, OwnerId, BPO_MS_End_Customer__r.OwnerId FROM Opportunity LIMIT 1];
    System.assertEquals(updatedOpp.OwnerId, updatedOpp.BPO_MS_End_Customer__r.OwnerId, ERROR_MESSAGE);
    Test.stopTest();
  }
}