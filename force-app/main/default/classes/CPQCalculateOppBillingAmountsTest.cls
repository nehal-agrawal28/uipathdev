/**
 * Test Class for CPQCalculateOppBilllingAmounts
 * 1.0 Salestech Initial Version
 *
 * @author Salestech
 * @date  11/12/2020
 *
 */
@IsTest
private class CPQCalculateOppBillingAmountsTest {
  @TestSetup
  private static void setup() {
    Account testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    DataFactory_CM.createContact(testAccount.Id, true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, false);
    testOpportunity.Deal_Type__c = 'Direct';
    testOpportunity.Amount = 20000;
    insert testOpportunity;
    Product2 prod = DataFactory_SL.createProduct(true);
    DataFactory_SL.createStdPricebookEntry(prod.Id, 20000, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);
    testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
    update testOpportunity;
    SBQQ__QuoteLine__c line = DataFactory_SL.createCPQQuoteLine(prod.Id, quote.Id, true);
  }

  @IsTest
  private static void canProcessBatchForOppsWithoutSegments() {
    CPQCalculateOppBillingAmounts batch = new CPQCalculateOppBillingAmounts(
      CPQCalculateOppBillingAmounts.CalculationType.NO_SEGMENT
    );
    batch.execute(
      null,
      [
        SELECT Id, Amount, CloseDate, SBQQ__PrimaryQuote__c, Period1_Billing_Amount__c
        FROM Opportunity
        WHERE
          Amount > 0
          AND (LastModifiedDate = LAST_N_DAYS:1
          OR SBQQ__PrimaryQuote__r.LastModifiedDate = LAST_N_DAYS:1)
          AND SBQQ__PrimaryQuote__c NOT IN (SELECT Quote__c FROM Billing_Segment__c)
      ]
    );

    System.assertEquals(
      20000,
      [SELECT Period1_Billing_Amount__c FROM Opportunity]
      .Period1_Billing_Amount__c,
      'Amount copied to Period1 billing amount'
    );
  }

  @IsTest
  private static void canProcessBatchForOppsWithSegments() {
    DataFactory_SL.createBillingSegment([SELECT Id FROM SBQQ__Quote__c].Id, 1.0, 20000, true);
    CPQCalculateOppBillingAmounts batch = new CPQCalculateOppBillingAmounts(
      CPQCalculateOppBillingAmounts.CalculationType.HAS_SEGMENT
    );
    batch.execute(
      null,
      [
        SELECT Id, Amount, SBQQ__PrimaryQuote__c, CloseDate, Period1_Billing_Amount__c
        FROM Opportunity
        WHERE
          Amount > 0
          AND (LastModifiedDate = LAST_N_DAYS:1
          OR SBQQ__PrimaryQuote__r.LastModifiedDate = LAST_N_DAYS:1)
          AND SBQQ__PrimaryQuote__c IN (SELECT Quote__c FROM Billing_Segment__c)
      ]
    );

    System.assertEquals(
      20000,
      [SELECT Period1_Billing_Amount__c FROM Opportunity]
      .Period1_Billing_Amount__c,
      'Amount copied to Period1 billing amount'
    );
  }

  @IsTest
  private static void canSendEmailDuringFailures() {
    CPQCalculateOppBillingAmounts recalculationJob = new CPQCalculateOppBillingAmounts(
      CPQCalculateOppBillingAmounts.CalculationType.NO_SEGMENT
    );
    recalculationJob.processErrors(
      new List<CPQCalculateOppBillingAmounts.JobError>{
        new CPQCalculateOppBillingAmounts.JobError('An error occured', [SELECT Id, Name FROM Opportunity])
      }
    );
    System.assertEquals(true, recalculationJob.errorEmailSent, 'error email should be sent');
  }

  @IsTest
  private static void catchBlockTest() {
    DataFactory_SL.createBillingSegment([SELECT Id FROM SBQQ__Quote__c].Id, 1.0, 20000, true);
    CPQCalculateOppBillingAmounts batch = new CPQCalculateOppBillingAmounts(
      CPQCalculateOppBillingAmounts.CalculationType.HAS_SEGMENT
    );
    batch.execute(
      null,
      [
        SELECT Id, Amount, SBQQ__PrimaryQuote__c, Period1_Billing_Amount__c
        FROM Opportunity
        WHERE
          Amount > 0
          AND (LastModifiedDate = LAST_N_DAYS:1
          OR SBQQ__PrimaryQuote__r.LastModifiedDate = LAST_N_DAYS:1)
          AND SBQQ__PrimaryQuote__c IN (SELECT Quote__c FROM Billing_Segment__c)
      ]
    );

    System.assert(20000 != [SELECT Period1_Billing_Amount__c FROM Opportunity].Period1_Billing_Amount__c);
  }
}