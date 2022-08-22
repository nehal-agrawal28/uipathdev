@isTest
private class OppStageValidationFunctionTest {
  @isTest
  private static void closedMergedValidationTest() {
    Account acc = new Account();
    acc.Name = 'Test setARRToRenewOnOpty';
    acc.Industry = 'Chemicals';
    acc.BillingCountry = 'Kiribati';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test setARRToRenewOnOpty Opp';
    opp.AccountId = acc.Id;
    opp.Type = 'New Business';
    opp.CloseDate = date.newInstance(2160, 2, 17);
    opp.StageName = 'Discovery';
    opp.LeadSource = 'Partner';
    insert opp;

    Contract contract = new Contract(AccountId = acc.Id, SBQQ__RenewalOpportunity__c = opp.Id);
    insert contract;

    Test.startTest();
    Boolean validationCaught = false;

    try {
      opp.StageName = 'Closed Merged';
      opp.Won_Reasons__c = 'Product Roadmap';
      update opp;
    } catch (Exception e) {
      if (e.getMessage().contains(OppStageValidationFunction.CLOSED_MERGED_VAL_ERROR)) {
        validationCaught = true;
      } else {
        throw e;
      }
    }

    System.assertEquals(true, validationCaught, 'Opp ClosedMerged validation not working');

    Test.stopTest();
  }

  @isTest
  private static void itDoesNotAllowClosedLostWithMultipleExpiryQuarters() {
    Account acc = new Account();
    acc.Name = 'Account Test ClosedLost';
    acc.Industry = 'Chemicals';
    acc.BillingCountry = 'Kiribati';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.Name = 'Test ClosedLost Opp';
    opp.AccountId = acc.Id;
    opp.Type = 'Renewal';
    opp.CloseDate = date.newInstance(2161, 2, 10);
    opp.StageName = 'Discovery';
    opp.LeadSource = 'Partner';
    insert opp;

    Contract contract1 = new Contract(
      AccountId = acc.Id,
      SBQQ__RenewalOpportunity__c = opp.Id,
      EndDate = date.newInstance(2161, 2, 17)
    );
    insert contract1;

    Contract contract2 = new Contract(
      AccountId = acc.Id,
      SBQQ__RenewalOpportunity__c = opp.Id,
      EndDate = date.newInstance(2161, 10, 17)
    );
    insert contract2;

    Test.startTest();
    Boolean validationCaught = false;

    try {
      opp.StageName = 'Closed Lost';
      opp.Primary_Lost_Reason__c = 'Weak Product Roadmap';
      update opp;
    } catch (Exception e) {
      if (e.getMessage().contains(OppStageValidationFunction.CLOSED_LOST_EXPIRING_QUARTER_VAL_ERROR)) {
        validationCaught = true;
      } else {
        throw e;
      }
    }

    System.assertEquals(true, validationCaught, 'Opp ClosedLost validation not working');

    Test.stopTest();
  }
}