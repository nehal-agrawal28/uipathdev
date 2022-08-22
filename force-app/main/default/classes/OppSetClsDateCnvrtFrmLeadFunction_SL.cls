public with sharing class OppSetClsDateCnvrtFrmLeadFunction_SL implements SObjectToSObjectFunction {
  public OppSetClsDateCnvrtFrmLeadFunction_SL() {
  }

  public SObject apply(Opportunity opp) {
    opp.CloseDate = Date.today().addDays(180);
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void setCloseDateTo6MonthsWhenConvertedFrmLead(List<Opportunity> opps) {
    List<Opportunity> elegibleOpps = Collection.of(opps)
      .filter(
        Match.field(Opportunity.Converted_from_Lead__c).hasValue().also(Opportunity.Converted_from_Lead__c).equals(true)
      )
      .asList();

    if (!elegibleOpps.isEmpty()) {
      Collection.of(elegibleOpps).mapAll(new OppSetClsDateCnvrtFrmLeadFunction_SL());
    }
  }
}