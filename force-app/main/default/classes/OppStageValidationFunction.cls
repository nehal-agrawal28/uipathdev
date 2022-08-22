public with sharing class OppStageValidationFunction implements SObjectToSObjectFunction {
  public static final String CLOSED_MERGED_VAL_ERROR = 'You cannot change stage to Closed Merged as there are contracts renewing via this opportunity.';
  public static final String CLOSED_LOST_EXPIRING_QUARTER_VAL_ERROR = 'You cannot change stage to Closed Lost as this Opportunity renews contracts expiring in different quarters.';

  private Map<Id, Opportunity> oppWithContracts = new Map<Id, Opportunity>();
  private final fflib_SObjectDomain domain;

  public OppStageValidationFunction(List<Opportunity> opps, fflib_SObjectDomain domain) {
    oppWithContracts = new Map<Id, Opportunity>(
      [
        SELECT Id, StageName, (SELECT Id, Expiry_Quarter_Number__c FROM SBQQ__RenewedContracts__r)
        FROM Opportunity
        WHERE Id IN :opps
      ]
    );
    this.domain = domain;
  }

  public SObject apply(Opportunity opp) {
    if (
      oppWithContracts.containsKey(opp.Id) &&
      oppWithContracts.get(opp.Id).SBQQ__RenewedContracts__r != null &&
      oppWithContracts.get(opp.Id).SBQQ__RenewedContracts__r.size() > 0 &&
      oppWithContracts.get(opp.Id).StageName == 'Closed Merged'
    ) {
      opp.addError(domain.error(CLOSED_MERGED_VAL_ERROR, opp));
    }

    if (
      oppWithContracts.containsKey(opp.Id) &&
      oppWithContracts.get(opp.Id).SBQQ__RenewedContracts__r != null &&
      oppWithContracts.get(opp.Id).SBQQ__RenewedContracts__r.size() > 1 &&
      oppWithContracts.get(opp.Id).StageName == 'Closed Lost'
    ) {
      //If one of the contracts expires in a diff quarter, error out
      for (Contract contract : oppWithContracts.get(opp.Id).SBQQ__RenewedContracts__r) {
        if (
          oppWithContracts.get(opp.Id).SBQQ__RenewedContracts__r.get(0).Expiry_Quarter_Number__c !=
          contract.Expiry_Quarter_Number__c
        ) {
          opp.addError(domain.error(CLOSED_LOST_EXPIRING_QUARTER_VAL_ERROR, opp));
          break;
        }
      }
    }

    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   * Only allow closed merged stage when there is no contract renewing via that opportunity
   */
  public static void validateStage(List<Opportunity> opps, Map<Id, SObject> existingOpps, fflib_SObjectDomain domain) {
    SObjectPredicate stageChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(stageChanged)
      .filter(Match.field(Opportunity.StageName).eq('Closed Merged'))
      .asList();

    changedOpps.addAll(
      (List<Opportunity>) Collection.of(opps)
        .filter(stageChanged)
        .filter(Match.field(Opportunity.StageName).eq('Closed Lost'))
        .asList()
    );

    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppStageValidationFunction(changedOpps, domain));
    }
  }
}