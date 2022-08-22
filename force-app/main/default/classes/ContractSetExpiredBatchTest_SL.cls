@IsTest
public with sharing class ContractSetExpiredBatchTest_SL {
  @TestSetup
  public static void setup() {
    CPQ_Config__c CPQSetting = new CPQ_Config__c();
    CPQSetting.Expiration_Interval__c = 90;
    insert CPQSetting;

    Account testAccount = new Account(
      Name = 'TestAccount2',
      AccountNumber = 'A2',
      AnnualRevenue = 12345.67,
      Country__c = 'United States',
      BillingCountry = 'United States',
      Industry = 'Telecommunications'
    );
    insert testAccount;

    insert new Contract(
      AccountId = testAccount.Id,
      Status = 'Draft',
      StartDate = System.Today().addDays(-365),
      EndDate = System.Today().addDays(-93),
      CurrencyIsoCode = 'USD'
    );
  }

  @IsTest
  public static void executesBatchAsExpected() {
    String CRON_EXP = '0 0 3 * * ?';
    Test.startTest();
    String jobId = System.schedule('Contract Set Expired Batch', CRON_EXP, new ContractSetExpiredBatch_SL());
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    System.assertEquals(0, ct.TimesTriggered);
    Test.stopTest();
  }
}