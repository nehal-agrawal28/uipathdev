@IsTest
private class UpdateRenewalOwnerServiceTest_SL {
  @TestSetup
  private static void makeData() {
    User u1 = DataFactory_CM.createUser('', 'Test1', 'System Administrator', true);

    Account acc = DataFactory_CM.createAccount('Customer', false);
    acc.OwnerId = u1.Id;
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
      Deal_Type__c = 'Resale',
      OwnerId = u1.Id
    );
    insert newOpportunity1;

    Contract contract = new Contract(
      Name = 'test',
      StartDate = Date.Today(),
      EndDate = Date.Today().addDays(30),
      Status = 'Draft',
      AccountId = acc.Id,
      ContractTerm = 4,
      SBQQ__RenewalOpportunity__c = newOpportunity1.Id
    );
    insert contract;
  }

  @IsTest
  private static void setRenewalAmendmentOwnersTest() {
    List<Account> accounts = [SELECT Id, OwnerId FROM Account];
    accounts[0].OwnerId = UserInfo.getUserId();

    AccountUpdateRenewalOwnerQueueable queueable = new AccountUpdateRenewalOwnerQueueable(accounts);
    queueable.execute(null);

    List<Opportunity> opp = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId = :accounts[0].Id];
    System.assertEquals(accounts[0].OwnerId, opp[0].OwnerId, 'Renewal owner update failed');
  }
}