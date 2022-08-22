public without sharing class UpdateRenewalOwnerService_SL implements IUpdateRenewalOwnerService {
  public void updateContractFieldsAndRenewalOwners(List<Account> accounts) {
    Map<Id, Account> accMap = new Map<Id, Account>(accounts);
    Map<Id, Contract> contractsToUpdate = new Map<Id, Contract>();
    Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
    Map<Id, Contract> contractMap = new Map<Id, Contract>(
      [
        SELECT
          Id,
          AccountId,
          SBQQ__AmendmentOwner__c,
          SBQQ__RenewalOwner__c,
          SBQQ__RenewalQuoted__c,
          SBQQ__RenewalOpportunity__c,
          SBQQ__RenewalOpportunity__r.OwnerId,
          SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,
          SBQQ__RenewalOpportunity__r.Probability
        FROM Contract
        WHERE AccountId IN :accMap.keyset() AND EndDate >= TODAY
      ]
    );

    for (Contract con : contractMap.values()) {
      Account relatedAcc = accMap.get(con.AccountId);

      if (con.SBQQ__AmendmentOwner__c != relatedAcc.OwnerId || con.SBQQ__RenewalOwner__c != relatedAcc.OwnerId) {
        con.SBQQ__AmendmentOwner__c = relatedAcc.OwnerId;
        con.SBQQ__RenewalOwner__c = relatedAcc.OwnerId;
        contractsToUpdate.put(con.Id, con);
      }

      if (
        con.SBQQ__RenewalOpportunity__c != null &&
        con.SBQQ__RenewalQuoted__c == false && // Not quoted
        con.SBQQ__RenewalOpportunity__r.OwnerId != relatedAcc.OwnerId &&
        con.SBQQ__RenewalOpportunity__r.Probability <= 70 && // Negotiation
        !oppsToUpdate.containsKey(con.SBQQ__RenewalOpportunity__c)
      ) {
        Opportunity oppToUpdate = new Opportunity(Id = con.SBQQ__RenewalOpportunity__c, OwnerId = relatedAcc.OwnerId);
        oppsToUpdate.put(oppToUpdate.Id, oppToUpdate);
      }
    }

    if (contractsToUpdate.size() > 0) {
      Database.update(contractsToUpdate.values(), false);
    }
    if (oppsToUpdate.size() > 0) {
      Database.update(oppsToUpdate.values(), false);
    }
  }
}