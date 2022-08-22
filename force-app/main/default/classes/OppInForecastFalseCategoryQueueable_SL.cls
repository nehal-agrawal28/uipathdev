public with sharing class OppInForecastFalseCategoryQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppInForecastFalseCategoryQueueable_SL(List<Opportunity> opps) {
    super('OppInForecastFalseCategoryQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.updateInForecastOnOpties(this.opps);
  }

  private void updateInForecastOnOpties(List<Opportunity> opps) {
    Profile currentUserProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
    List<Opportunity> oppToUpdate = new List<Opportunity>();

    if (
      (currentUserProfile.Name != 'UiPath Japan Partner Community' &&
      currentUserProfile.Name != 'UiPath Japan Partner Community Login User') || Test.isRunningTest()
    ) {
      for (Opportunity opp : [SELECT Id, In_Forecast__c FROM Opportunity WHERE Id IN :opps AND In_Forecast__c = TRUE]) {
        opp.In_Forecast__c = false;
        oppToUpdate.add(opp);
      }
    }

    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update oppToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  /**
   */
  public static void deriveOmittedForecastOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName, Opportunity.ForecastCategoryName },
      opps,
      existingOpps
    );

    List<Opportunity> changedOpps = (List<Opportunity>) Collection.of(opps)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.ForecastCategoryName).isIn(new Set<String>{ 'Pipeline', 'Omitted' }))
      .asList();

    if (!changedOpps.isEmpty()) {
      AbstractQueueable.enqueue(new OppInForecastFalseCategoryQueueable_SL(changedOpps));
    }
  }
}