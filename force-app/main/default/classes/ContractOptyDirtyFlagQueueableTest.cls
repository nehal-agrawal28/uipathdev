@IsTest
private with sharing class ContractOptyDirtyFlagQueueableTest {
  @IsTest
  private static void contractOptyDirtyFlagQueueableTest() {
    Account acc = new Account(
      Name = 'TestAccountUK',
      Country__c = 'United Kingdom',
      BillingCountry = 'United Kingdom',
      Industry = 'Others'
    );
    insert acc;

    Contact cnt = new Contact(
      LastName = 'Test545734',
      AccountId = acc.Id,
      Email = 'test@test.com',
      Title = 'titlename',
      Department__c = 'IT'
    );
    insert cnt;

    Opportunity newOpportunity1 = new Opportunity(
      Name = 'testOppName',
      LeadSource = 'Webinar',
      Type = 'Renewal',
      AccountId = acc.Id,
      StageName = 'Discovery',
      CloseDate = Date.today(),
      Discount_Approval_Status__c = 'In Approval',
      Managing_Director__c = UserInfo.getUserId(),
      CurrencyIsoCode = 'USD',
      Customer_Primary_Contact__c = cnt.Id,
      Onboard_customer_by_CS_Ops__c = 'No',
      Deal_Type__c = 'Resale'
    );
    insert newOpportunity1;

    Opportunity newOpportunity2 = new Opportunity(
      Name = 'testOppName',
      LeadSource = 'Webinar',
      Type = 'Renewal',
      AccountId = acc.Id,
      StageName = 'Discovery',
      CloseDate = Date.today(),
      Discount_Approval_Status__c = 'In Approval',
      Managing_Director__c = UserInfo.getUserId(),
      CurrencyIsoCode = 'USD',
      Customer_Primary_Contact__c = cnt.Id,
      Onboard_customer_by_CS_Ops__c = 'No',
      Deal_Type__c = 'Resale'
    );
    insert newOpportunity2;

    Contract contract = new Contract(
      Name = 'test',
      StartDate = Date.Today(),
      Status = 'Draft',
      AccountId = acc.Id,
      ContractTerm = 4,
      SBQQ__RenewalOpportunity__c = newOpportunity1.Id
    );
    insert contract;

    Contract updatedContract = contract.clone();
    updatedContract.Id = contract.Id;
    updatedContract.SBQQ__RenewalOpportunity__c = newOpportunity2.Id;
    update updatedContract;

    ContractOptyDirtyFlagQueueable queueable = new ContractOptyDirtyFlagQueueable(
      new List<Contract>{ updatedContract },
      new Map<Id, SObject>{ contract.Id => contract }
    );
    queueable.execute(null);

    for (Opportunity opp : [
      SELECT Id, Financial_Metrics_Dirty__c
      FROM Opportunity
      WHERE Id = :newOpportunity1.Id OR Id = :newOpportunity2.Id
    ]) {
      System.assertEquals(true, opp.Financial_Metrics_Dirty__c, 'Dirty flag was not set correctly');
    }
  }
}