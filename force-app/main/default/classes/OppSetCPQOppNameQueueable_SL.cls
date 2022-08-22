public with sharing class OppSetCPQOppNameQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppSetCPQOppNameQueueable_SL(List<SObject> opps) {
    super('OppSetCPQOppNameQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.setNameOnOpportunities(this.opps);
  }

  private void setNameOnOpportunities(List<SObject> opps) {
    List<Opportunity> oppsToUpdate = [
      SELECT
        Id,
        Account.Name,
        SBQQ__RenewedContract__r.ContractNumber,
        SBQQ__RenewedContract__r.EndDate,
        SBQQ__AmendedContract__r.ContractNumber,
        SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Name,
        SBQQ__Renewal__c
      FROM Opportunity
      WHERE id IN :opps AND (SBQQ__Renewal__c = TRUE OR SBQQ__AmendedContract__c != NULL)
    ];

    for (Opportunity record : oppsToUpdate) {
      if (record.SBQQ__Renewal__c) {
        String tempRenewOppName =
          record.Account.Name +
          ' Renewal  - ' +
          record.SBQQ__RenewedContract__r.ContractNumber +
          ' - ' +
          record.SBQQ__RenewedContract__r.EndDate.year();
        if (tempRenewOppName.length() > 120) {
          record.Name = tempRenewOppName.substring(0, 119).trim();
        } else {
          record.Name = tempRenewOppName.trim();
        }
      } else {
        String tempAmendOppName =
          'Amended ' +
          record.SBQQ__AmendedContract__r.ContractNumber +
          ' ' +
          record.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Name;
        if (tempAmendOppName.length() > 120) {
          record.Name = tempAmendOppName.substring(0, 119).trim();
        } else {
          record.Name = tempAmendOppName.trim();
        }
      }
    }
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update oppsToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  public static AbstractQueueable setCPQOppName(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records).filter(new FilterOpportunities()).asList();

    if (!eligibleRecords.isEmpty()) {
      return new OppSetCPQOppNameQueueable_SL(eligibleRecords);
    }

    return new NoOpSkipToNext();
  }

  private class FilterOpportunities implements SObjectPredicate {
    private Boolean apply(Opportunity opp) {
      return (opp.SBQQ__Renewal__c || opp.SBQQ__AmendedContract__c <> null);
    }

    public Boolean apply(SObject record) {
      return apply((Opportunity) record);
    }
  }
}