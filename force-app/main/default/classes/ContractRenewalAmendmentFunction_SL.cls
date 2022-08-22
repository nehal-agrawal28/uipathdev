/**
 * Process contracts to set default values in Renewal/Amendment fields
 */
public with sharing class ContractRenewalAmendmentFunction_SL implements SObjectToSObjectFunction {
  private static final String AMENDMENT_OPP_STAGE = 'Prospect';
  private static final String RENEWAL_OPP_STAGE = 'Negotiation';
  private String defaultOppRT;
  private Map<Id, Opportunity> oppMap;

  public ContractRenewalAmendmentFunction_SL(List<SObject> records) {
    List<Id> oppIds = Collection.of(records).pluckIds(Contract.SBQQ__Opportunity__c);
    oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId FROM Opportunity WHERE Id IN :oppIds]);

    String defaultOppRTDeveloperName = CPQ_Controls__mdt.getInstance('Default')?.Opp_CPQ_Record_Type_Developer_Name__c;
    defaultOppRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get(defaultOppRTDeveloperName)
      ?.getRecordTypeId();
  }

  public SObject apply(Contract con) {
    con.SBQQ__AmendmentOpportunityStage__c = AMENDMENT_OPP_STAGE;
    con.SBQQ__AmendmentOwner__c = oppMap.get(con.SBQQ__Opportunity__c)?.OwnerId;
    con.SBQQ__AmendmentOpportunityRecordTypeId__c = defaultOppRT;
    con.SBQQ__RenewalOpportunityStage__c = RENEWAL_OPP_STAGE;
    con.SBQQ__RenewalOwner__c = oppMap.get(con.SBQQ__Opportunity__c)?.OwnerId;
    con.SBQQ__RenewalOpportunityRecordTypeId__c = defaultOppRT;
    con.SBQQ__RenewalUpliftRate__c = null;
    // OTO-1142 : this will be set to true in forecast queueable
    if (!Test.isRunningTest()) {
      con.SBQQ__PreserveBundleStructureUponRenewals__c = false;
    }
    return con;
  }

  public SObject apply(SObject record) {
    return apply((Contract) record);
  }

  /**
   * @description   Set contract status to Activated
   * @param records list of new contracts
   */
  public static void setDefaultsForRenewalAmendments(List<SObject> records) {
    Collection.of(records)
      .mapSome(Match.field(Contract.SBQQ__Opportunity__c).hasValue(), new ContractRenewalAmendmentFunction_SL(records));
  }
}