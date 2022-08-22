/**
 * Test Class for CPQTriggerQuoteRecalculationJob
 * 1.0 -- 23/03/2020 Initial Version
 *
 * --
 * @date  23/03/2020
 *
 */

@IsTest
private class CPQTriggerQuoteRecalculationJobTest {
  @TestSetup
  private static void setup() {
    String testIdentifier = 'BlueMountain';

    String accountRef = String.valueOf(Math.random() * 100000);
    Account account1 = new Account(
      Name = testIdentifier,
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get(Constants.ACCOUNT_RECORD_TYPE_1)
        .getRecordTypeId(),
      Legal__c = testIdentifier,
      Overwrite_Legal_Entity_Name__c = true,
      Country__c = 'Australia',
      State__c = 'Victoria',
      Meets_CSM_Criteria__c = 'No',
      Website = 'http://www.' + testIdentifier + '.com',
      Phone = '+61 3 9905 5054',
      Classification__c = 'Enterprise',
      Industry = 'Education',
      Maintenance_Flag__c = 'Premium',
      Premium_End_Date__c = Date.newInstance(System.today().year() + 1, System.today().month(), 27),
      Geo__c = 'APJ',
      Region__c = 'ANZ',
      Ignore_Territory_Assignment__c = false,
      Academic_Alliance_Agreement__c = false,
      AnnualRevenue = 1828768130.00,
      Overwrite_Annual_Revenue__c = false,
      Revenue_Source__c = 'Dun & Bradstreet',
      SBQQ__IgnoreParentContractedPrices__c = true,
      NumberOfEmployees = 14318,
      Active_Account__c = false,
      Domain__c = testIdentifier + '.edu',
      Matched_with_D_B__c = 'Matched',
      Verified_by_Data_Steward__c = 'Verified',
      Overwrite_Billing_Address__c = false,
      Default_Payment_Terms__c = '30 Days Net',
      Sync_Status__c = 'Synced',
      Primary_Subsidiary__c = 'UiPath SRL',
      Channel_Tier__c = 'End User',
      NS_Customer_Internal_ID__c = accountRef,
      Validation_Status__c = 'Validated',
      NetSuite_Customer__c = accountRef,
      Receivables__c = 251381.02,
      PO_Mandatory__c = 'No',
      Courier__c = 'No',
      Platform__c = 'No',
      KomikoId__c = testIdentifier
    );
    Database.upsert(account1, Account.KomikoId__c);

    Contact primaryContact = new Contact(
      AccountId = account1.Id,
      LastName = testIdentifier,
      FirstName = 'John',
      LeadSource = 'Website - Direct',
      Email = 'test.' + testIdentifier + '@test.edu',
      KomikoId__c = testIdentifier,
      Department__c = 'IT'
    );
    Database.upsert(primaryContact, Contact.KomikoId__c);

    Opportunity opportunity = new Opportunity(
      Name = testIdentifier + ' Multi Year Deal',
      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CPQ Default').getRecordTypeId(),
      AccountId = [SELECT Id FROM Account WHERE KomikoId__c = :testIdentifier]
      .Id,
      Deal_Type__c = 'Direct',
      Led_by__c = 'Partner Led',
      Must_Win__c = false,
      Managing_Director__c = UserInfo.getUserId(),
      LeadSource = 'Website - Direct',
      SBQQ__Contracted__c = false,
      SBQQ__Renewal__c = false,
      Deal_Reg_Status__c = 'Approved',
      Deal_Reg_Notes_Comments__c = '14Oct19RP: Deal Registration through the partner RPA Solutions ',
      Influence__c = 'RPA Solutions Australia Pty Ltd',
      StageName = 'Proposal',
      CloseDate = Date.newInstance(2020, 3, 11),
      Opportunity_Next_Steps__c = 'Marking as Closed Won Pending.',
      Positive_Business_Outcomes__c = 'Student Experience, Staff Engagement, Research',
      Value_Drivers__c = 'Accelerate Benefits from Digital Transformation; Improve Customer Experience; ' +
        'Improve Employee Experience; Improve Compliance',
      Competition__c = 'Automation Anywhere; Blue Prism',
      Paper_Process__c = 'Paperwork to come today as per last comms from client.',
      Decision_Process_Actual__c = 'Decision has already been made to go UiPath',
      Won_Reasons__c = 'Product Roadmap',
      Closeout_Reason__c = 'As above As above As above',
      Features_the_customer_liked_didn_t_like__c = 'Not applicable Not applicable',
      Send_invoice_to__c = 'mel.Vanroyen@test.com',
      Customer_Primary_Contact__c = [SELECT Id FROM Contact WHERE KomikoId__c = :testIdentifier]
      .Id,
      Send_licenses_to__c = 'mel.vanroyen@test.com',
      Payment_Cycle__c = 'Annual',
      Termination_Clause__c = 'No',
      Contract_Start_Date__c = Date.newInstance(System.today().year(), System.today().month(), 28),
      Contract_End_Date__c = Date.newInstance(System.today().year() + 3, System.today().month(), 27)
    );
    insert opportunity;

    OpportunityContactRole opportunityContactRoleTechBuyer = new OpportunityContactRole(
      ContactId = [SELECT Id FROM Contact WHERE KomikoId__c = :testIdentifier]
      .Id,
      IsPrimary = true,
      OpportunityId = opportunity.Id,
      Role = 'Technical Buyer'
    );

    insert opportunityContactRoleTechBuyer;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = opportunity.Id,
      SBQQ__Primary__c = true,
      SBQQ__Account__c = [SELECT Id FROM Account WHERE KomikoId__c = :testIdentifier]
      .Id,
      Bill_To_Account__c = [SELECT Id FROM Account WHERE KomikoId__c = :testIdentifier]
      .Id,
      SBQQ__PrimaryContact__c = [SELECT Id FROM Contact WHERE KomikoId__c = :testIdentifier]
      .Id,
      SBQQ__Type__c = 'Quote',
      SBQQ__Status__c = 'Draft',
      Payment_Terms__c = '30 Days Net',
      SBQQ__StartDate__c = Date.newInstance(System.today().year(), System.today().month(), 28),
      SBQQ__EndDate__c = Date.newInstance(System.today().year() + 3, System.today().month(), 27),
      SBQQ__ExpirationDate__c = System.today().addDays(30),
      RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('CPQ Default').getRecordTypeId()
    );
    insert quote;

    opportunity.SBQQ__PrimaryQuote__c = quote.Id;
    opportunity.FinanceReviewReached__c = true;
    //Creates Finance Case
    opportunity.StageName = 'Closed Won Pending';

    //update opportunity;

    opportunity.StageName = 'Closed Won Booked';
    update opportunity;
  }

  @IsTest
  private static void canProcessBatch() {
    Test.startTest();

    Id batchJobId = Database.executeBatch(
      new CPQTriggerQuoteRecalculationJob(
        new List<String>{ 'Closed Won Booked' },
        Date.newInstance(2020, 3, 1),
        Date.newInstance(2020, 3, 13)
      ),
      1
    );
    System.debug('>>>> batch id' + batchJobId);
    Test.stopTest();

    // System.debug('Last calc:,,,,,,,'+[Select SBQQ__LastCalculatedOn__c from SBQQ__Quote__c].SBQQ__LastCalculatedOn__c);
    System.assertEquals(true, !([SELECT Id FROM AsyncApexJob].isEmpty()), 'Batch job not created');
  }

  @IsTest
  private static void canSendEmailDuringFailures() {
    Test.startTest();

    CPQTriggerQuoteRecalculationJob recalculationJob = new CPQTriggerQuoteRecalculationJob(
      new List<String>{ 'Closed Won Booked' },
      Date.newInstance(2020, 3, 1),
      Date.newInstance(2020, 3, 13)
    );
    recalculationJob.setBatchErrors(
      new List<CPQTriggerQuoteRecalculationJob.JobError>{
        new CPQTriggerQuoteRecalculationJob.JobError(
          'An error occured',
          new List<SBQQ__Quote__c>{ new SBQQ__Quote__c() }
        )
      }
    );
    Id batchJobId = Database.executeBatch(recalculationJob, 1);
    System.debug('>>>> batch id' + batchJobId);
    Test.stopTest();

    System.assertEquals(true, !([SELECT Id FROM AsyncApexJob].isEmpty()), 'Batch job not created');
  }
}