public with sharing class OpportunitiesService_SL implements IOpportunitiesService_SL {
  public static final String OPP_DEFAULT_PRICEBOOK = 'Pricebook May 2020';
  public static Id oppDefaultPricebookId {
    get {
      if (oppDefaultPricebookId == null) {
        oppDefaultPricebookId = getPricebookId();
      }
      return oppDefaultPricebookId;
    }
    set {
    }
  }
  private OpportunitiesSelector_SL oppsSelectorSL {
    get {
      return (OpportunitiesSelector_SL) Application_SL.Selector.newInstance(Opportunity.SObjectType);
    }
    set;
  }

  public Opportunity createOpportunity(
    String accountId,
    String opportunityName,
    String stageName,
    String dealType,
    Date startDate,
    String currencyCode,
    String soldToPartnerId
  ) {
    return createOpportunity(
      accountId,
      opportunityName,
      stageName,
      dealType,
      startDate,
      currencyCode,
      soldToPartnerId,
      false,
      ''
    );
  }

  public Opportunity createOpportunity(
    String accountId,
    String opportunityName,
    String stageName,
    String dealType,
    Date startDate,
    String currencyCode,
    String soldToPartnerId,
    Boolean replacementTransaction
  ) {
    return createOpportunity(
      accountId,
      opportunityName,
      stageName,
      dealType,
      startDate,
      currencyCode,
      soldToPartnerId,
      replacementTransaction,
      ''
    );
  }

  public Opportunity createOpportunity(
    String accountId,
    String opportunityName,
    String stageName,
    String dealType,
    Date startDate,
    String currencyCode,
    String soldToPartnerId,
    Boolean replacementTransaction,
    String opportunityOwnerId
  ) {
    Opportunity opp = new Opportunity();
    opp.AccountId = accountId;
    opp.Name = replacementTransaction
      ? Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX + opportunityName
      : opportunityName;
    opp.StageName = stageName;
    opp.CloseDate = startDate;
    //TODO Remove this hack when merging into soup because there is pricebook defaulting logic there
    opp.Pricebook2Id = oppDefaultPricebookId;
    opp.SBQQ__QuotePricebookId__c = oppDefaultPricebookId;
    //
    opp.Replacement_Transaction__c = replacementTransaction;

    if (String.isNotBlank(opportunityOwnerId)) {
      opp.OwnerId = opportunityOwnerId;
    }

    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('CPQ_Default')
      .getRecordTypeId();

    if (String.isNotBlank(dealType)) {
      opp.Deal_Type__c = dealType;
    }
    if (String.isNotBlank(currencyCode)) {
      opp.CurrencyIsoCode = currencyCode;
    }
    if (String.isNotBlank(soldToPartnerId)) {
      opp.Sold_to_Partner__c = soldToPartnerId;
    }

    fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
    unitOfWork.registerNew(opp);
    unitOfWork.commitWork();

    return opp;
  }

  public List<PicklistMsg_CM> getStageNamePicklistValues() {
    List<PicklistMsg_CM> picklistValues = new List<PicklistMsg_CM>();
    Schema.DescribeFieldResult dfr = Opportunity.StageName.getDescribe();

    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
      picklistValues.add(new PicklistMsg_CM(pe.getValue(), pe.getLabel()));
    }
    return picklistValues;
  }

  public List<PicklistMsg_CM> getDealTypePicklistValues() {
    List<PicklistMsg_CM> picklistValues = new List<PicklistMsg_CM>();
    Schema.DescribeFieldResult dfr = Opportunity.Deal_Type__c.getDescribe();

    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
      picklistValues.add(new PicklistMsg_CM(pe.getValue(), pe.getLabel()));
    }
    return picklistValues;
  }

  public List<PicklistMsg_CM> getCurrencyPicklistValues() {
    List<PicklistMsg_CM> picklistValues = new List<PicklistMsg_CM>();
    Schema.DescribeFieldResult dfr = Opportunity.CurrencyIsoCode.getDescribe();

    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
      picklistValues.add(new PicklistMsg_CM(pe.getValue(), pe.getLabel()));
    }
    return picklistValues;
  }

  public List<Opportunity> syncFieldOnCancelledOpps(Set<Id> replacementOppIds, SObjectField field) {
    List<Opportunity> chilOppsToUpdate = new List<Opportunity>();

    Map<Id, Opportunity> replacementOpps = new Map<Id, Opportunity>(
      oppsSelectorSL.selectById(replacementOppIds, false)
    );

    //get a set of parent quote Ids from the replacement opps.SBQQ__PrimaryQuote__c
    Set<Id> replacementOppQuoteIds = new Set<Id>(
      Collection.of(replacementOpps.values()).pluckIds(Opportunity.SBQQ__PrimaryQuote__c)
    );
    //

    List<Opportunity> childOpps = oppsSelectorSL.getCancelledOppsByReplacedOppsQuotes(replacementOppQuoteIds);

    Map<Id, Map<Id, Opportunity>> parentOppIdToChildOpps = new Map<Id, Map<Id, Opportunity>>();

    for (Opportunity opp : childOpps) {
      Map<Id, Opportunity> childOppsMap;
      //navigate relationship to get the parent opp for given child opp
      Opportunity parentOpp = replacementOpps.get(opp.SBQQ__PrimaryQuote__r.Replacement_Quote__r.SBQQ__Opportunity2__c);
      if (opp.get(field) != parentOpp.get(field)) {
        if (parentOppIdToChildOpps.containsKey(parentOpp.Id)) {
          childOppsMap = parentOppIdToChildOpps.get(parentOpp.Id);
        } else {
          childOppsMap = new Map<Id, Opportunity>();
        }
        opp.put(field, parentOpp.get(field));
        childOppsMap.put(opp.Id, opp);
        parentOppIdToChildOpps.put(parentOpp.Id, childOppsMap);
      }
    }

    DescribeFieldResult descrResult = field.getDescribe();
    String fieldName = descrResult.name;
    String fieldType = descrResult.getSoapType().name();

    Map<Id, List<Opportunity>> parentIdToOppsToUpdate = new Map<Id, List<Opportunity>>();

    for (Id parentId : parentOppIdToChildOpps.keySet()) {
      List<Opportunity> oppsToUpdate = Collection.of(parentOppIdToChildOpps.get(parentId).values())
        .mapAll(new SetSobjectFieldFunction_SL(field, descrResult, fieldName, fieldType))
        .asList();
      chilOppsToUpdate.addAll(oppsToUpdate);
    }

    return chilOppsToUpdate;
  }

  //TODO Remove this hack when merging into soup because there is pricebook defaulting logic there
  private static Id getPricebookId() {
    Collection activePbCollection = Collection.of(
      [SELECT Id, Name FROM Pricebook2 WHERE IsActive = TRUE ORDER BY IsStandard DESC]
    );

    Id pricebook2Id;
    if (!Test.isRunningTest()) {
      Pricebook2 pbProto = new Pricebook2(Name = OPP_DEFAULT_PRICEBOOK);
      pricebook2Id = activePbCollection.filter(Match.record(pbProto)).asList().size() > 0
        ? activePbCollection.filter(Match.record(pbProto)).asList().get(0).Id
        : activePbCollection.asList().get(0).Id;
    } else {
      pricebook2Id = Test.getStandardPricebookId();
    }
    return pricebook2Id;
  }
}