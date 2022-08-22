/**
 * Queueable to keep snapshots of territories on billing segments
 */
public without sharing class BillingScheduleTerritoryQueueable_SL extends AbstractQueueable {
  private final List<Opportunity> opportunities;
  private static final Set<Id> processedRecords = new Set<Id>();

  final static IBillingSegmentsService_SL billingSegmentsService = (IBillingSegmentsService_SL) Application_SL.Service.newInstance(
    IBillingSegmentsService_SL.class
  );

  public BillingScheduleTerritoryQueueable_SL(List<Opportunity> opportunities) {
    super('BillingScheduleTerritoryQueueable_SL');
    this.opportunities = opportunities;
    //to allow for logging against record. only used in non-bulk contexts
    if (opportunities.size() == 1) {
      this.setPrimaryRecordId(opportunities.get(0).Id);
    }
  }

  public override void work() {
    billingSegmentsService.updateBillingSegmentTerritory(new Set<Id>(Collection.of(this.opportunities).pluckIds()));
  }

  public static void updateBillingSegmentTerritory(
    List<Opportunity> opportunities,
    Map<Id, SObject> existingOpportunities
  ) {
    SObjectPredicate hasTerritoryChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Territory2Id },
      opportunities,
      existingOpportunities
    );

    List<Opportunity> eligibleOpportunities = (List<Opportunity>) Collection.of(opportunities)
      .filter(new IsRecordNotProcessedYet(processedRecords))
      .filter(hasTerritoryChanged)
      .asList();

    if (!eligibleOpportunities.isEmpty()) {
      AbstractQueueable.enqueue(new BillingScheduleTerritoryQueueable_SL(eligibleOpportunities));
      processedRecords.addAll(Collection.of(eligibleOpportunities).pluckIds());
    }
  }
}