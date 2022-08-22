public with sharing class CreditHoldDetailsController {
  public Id oId {
    get;
    set {
      oId = value;
      fetchDetails();
    }
  }

  public Opportunity opp { get; set; }

  private void fetchDetails() {
    if (String.isNotBlank(oId)) {
      // opp details
      opp = [
        SELECT
          Id,
          Name,
          Deal_Type__c,
          Account.Id,
          Account.Name,
          Sold_to_Partner__r.Name,
          Sold_to_Partner__c,
          Account.Credit_Hold__c,
          Owner.Name,
          Sold_to_Partner__r.Credit_Hold__c
        FROM Opportunity
        WHERE Id = :oId
      ];
  } 
 }
}