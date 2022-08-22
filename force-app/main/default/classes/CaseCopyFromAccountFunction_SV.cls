public with sharing class CaseCopyFromAccountFunction_SV implements SObjectToSObjectFunction {
  private Map<Id, Account> accountMap;
  public CaseCopyFromAccountFunction_SV(List<Case> cases) {
    Set<Id> accountIds = new Set<Id>(Collection.of(cases).pluckIds(Case.AccountId));
    this.accountMap = new Map<Id, Account>([SELECT Id, Maintenance_Flag__c FROM Account WHERE Id IN :accountIds]);
  }

  public SObject apply(Case record) {
    record.Maintenance_Flag__c = this.accountMap.get(record.AccountId).Maintenance_Flag__c;
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveMaintenanceFlag(List<SObject> cases) {
    Collection.of(cases)
      .filter(Match.field(Case.AccountId).hasValue())
      .mapAll(new CaseCopyFromAccountFunction_SV(cases));
  }
}