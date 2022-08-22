public inherited sharing class OppExtendDealRegFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(Opportunity opp) {
    opp.Deal_Reg_Expire_Date_new__c = opp.Deal_Reg_Expire_Date_new__c.addDays(90);
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   *  Set Opportunity Deal_Reg_Expire_Date_new__c on update
   */
  public static void deriveExpireDateOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Opportunity.Extend_Deal_Reg_Expire_Date__c,
        Opportunity.Deal_Reg_Expire_Date_new__c,
        Opportunity.Converted_from_Deal_Reg__c
      },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.Extend_Deal_Reg_Expire_Date__c)
          .hasValue()
          .also(Opportunity.Extend_Deal_Reg_Expire_Date__c)
          .equals(true)
          .also(Opportunity.Deal_Reg_Expire_Date_new__c)
          .notEquals(null)
          .also(Opportunity.Converted_from_Deal_Reg__c)
          .hasValue()
          .also(Opportunity.Converted_from_Deal_Reg__c)
          .equals(true)
      )
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppExtendDealRegFunction_SL());
    }
  }

  /**
   * Set Opportunity Deal_Reg_Expire_Date_new__c on insert
   */
  public static void deriveExpireDateOnInsert(List<Opportunity> opps) {
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(
        Match.field(Opportunity.Extend_Deal_Reg_Expire_Date__c)
          .hasValue()
          .also(Opportunity.Extend_Deal_Reg_Expire_Date__c)
          .equals(true)
          .also(Opportunity.Deal_Reg_Expire_Date_new__c)
          .notEquals(null)
          .also(Opportunity.Converted_from_Deal_Reg__c)
          .hasValue()
          .also(Opportunity.Converted_from_Deal_Reg__c)
          .equals(true)
      )
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppExtendDealRegFunction_SL());
    }
  }
}