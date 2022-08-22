/**
 * --
 * @date 18/03/2019
 * @description Event listeners for Opty Trigger. This class should ideally delegate work to Domain/Service classes
 */
/**
 * @author Gen Estrada @ Slalom
 * @date 16/07/2020
 * @description Add Standard Pricebook to Japanese CPQ Quotes
 */
public class CPQOptyTriggerHandler extends TriggerHandler {
  //private static final Id CPQ_RECORD_TYPE_ID = CPQOptyTriggerHandler.getCPQRecordTypeId();

  public override void beforeInsert() {
    //this.populateNPSPricebook();
    //this.processNewEntriesOnInsert();
    //this.populateOpportunityFields();
  }

  public override void beforeUpdate() {
    //this.populateNPSPricebook();
    //this.processNewEntriesOnUpdate();
    //this.populateOpportunityFields();
  }

  public override void afterUpdate() {
    //this.setPremiumCare();
    //this.setOppSubType();

    //this.deriveCustomerStage();
    //system.debug('deriveCustomerStage() ran once');
  }

  /*private void deriveCustomerStage() {
    system.debug('Opps after update are : ' + (List<Opportunity>) Trigger.new);

    List<Opportunity> oppToUpdate = new List<Opportunity>();
    for (Opportunity opp : (List<Opportunity>) Trigger.new) {
      if (
        ((Opportunity) Trigger.oldMap.get(opp.Id)).StageName != 'Closed Won Booked' &&
        opp.StageName == 'Closed Won Booked'
      ) {
        oppToUpdate.add(opp);
      }
    }
    if (oppToUpdate.size() > 0) {
      AbstractQueueable.enqueue(new OpportunityAccountCustomerStageQueueable(oppToUpdate));
    }
  }*/

  /*private void processNewEntriesOnUpdate() {
    Set<Id> idsToRetrieve = new Set<Id>();

    for (Opportunity opty : (List<Opportunity>) Trigger.new) {
      //  maintainTypeFieldForOpportunity(opty, CPQ_RECORD_TYPE_ID);

      idsToRetrieve.addAll(getAccountIdsToUpdate(opty));
    }

    if (!idsToRetrieve.isEmpty()) {
      IntegrationHandler.updateAccountValidationStatusToReadyForReview(idsToRetrieve);
    }
  }*/

  /**
   * @Description: Return a set of account ids that need updating. Opportunity that have moved to a Negotiation, their associated account and
   * sold_to_partner account id will be returned.
   */
  /*private Set<Id> getAccountIdsToUpdate(Opportunity opty) {
    Set<Id> idsToRetrieve = new Set<Id>();
    Opportunity oldOpportunity = (Opportunity) Trigger.oldMap.get(opty.id);

    if (
      (oldOpportunity.StageName != opty.StageName) && Constants.INTEGRATION_OPPORTUNITY_STAGES.contains(opty.StageName)
    ) {
      idsToRetrieve.add(opty.AccountId);

      if (opty.Sold_to_Partner__c != null) {
        idsToRetrieve.add(opty.Sold_to_Partner__c);
      }
    }
    return idsToRetrieve;
  }*/

  /**
   * @Description populate opportunity fields
   */
  /*private void populateOpportunityFields() {
    List<Opportunity> newList = (List<Opportunity>) Trigger.new;
    Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) Trigger.oldMap;

    for (Opportunity opp : newList) {
      // Populate amount fields TCV/ACV/ARR with total amount before primary quote creation
      if (
        opp.SBQQ__PrimaryQuote__c == null &&
        opp.Amount != null &&
        (oldMap == null || (opp.Amount != oldMap.get(opp.Id).Amount))
      ) {
        opp.CPQ_OpportunityACV__c = opp.Amount;
        opp.CPQ_OpportunityTCV__c = opp.Amount;
        if (opp.Number_of_Products__c == 0) {
          opp.CPQ_OpportunityARR__c = opp.Amount;
        }
      }

      // Populate Financial Metrics Dirty flag on update
      if (
        oldMap != null &&
        (opp.Amount != oldMap.get(opp.Id).Amount ||
        opp.StageName != oldMap.get(opp.Id).StageName ||
        opp.CloseDate != oldMap.get(opp.Id).CloseDate)
      ) {
        opp.Financial_Metrics_Dirty__c = true;
      }
    }
  }*/

  /**
   *  @Author Alyssa Lefebvre
   *  @Description populate NPS pricebook for New Business and CreatedDate > 4/30/2020
   */
  /*private static Map<String, Id> pbMap {
    get {
      if (pbMap == null) {
        pbMap = new Map<String, Id>();
        for (PriceBook2 pb : [
          SELECT Id, Name
          FROM PriceBook2
          WHERE Name = :Constants.DEFAULT_PRICE_BOOK OR Name = 'Standard Price Book'
        ]) {
          pbMap.put(pb.Name, pb.Id);
        }
      }
      return pbMap;
    }
    set;
  }*/

  /*private void populateNPSPricebook() {
    List<Opportunity> newList = (List<Opportunity>) Trigger.new;
    Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) Trigger.oldMap;

    Id japanPartnerStdRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('UiPath_Japan_Partner_standard')
      .getRecordTypeId();
    Id stdRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('UiPath_Standard')
      .getRecordTypeId();

    for (Opportunity opp : newList) {
      // Skip pricebook change for Closed Won Booked/Closed Won Pending
      if (opp.StageName == 'Closed Won Pending' || opp.StageName == 'Closed Won Booked') {
        continue;
      }
      // Skip pricebook change for Japan
      if (
        opp.RecordTypeId == japanPartnerStdRecTypeId ||
        (opp.RecordTypeId == stdRecTypeId &&
        accountMap.containsKey(opp.AccountId) &&
        accountMap.get(opp.AccountId).Geo__c == 'Japan')
      ) {
        continue;
      } else if (
        Trigger.isInsert &&
        pbMap != null &&
        pbMap.containsKey(Constants.DEFAULT_PRICE_BOOK) &&
        String.isBlank(opp.SBQQ__RenewedContract__c) &&
        String.isBlank(opp.SBQQ__AmendedContract__c)
      ) {
        // For everything else set to default pricebook
        opp.Pricebook2Id = pbMap.get(Constants.DEFAULT_PRICE_BOOK);
      }
    }
  }*/

  /*private static Map<Id, Account> accountMap {
    get {
      if (accountMap == null) {
        List<Opportunity> newList = (List<Opportunity>) Trigger.new;
        accountMap = new Map<Id, Account>();

        for (Opportunity opp : newList) {
          if (opp.AccountId != null) {
            accountMap.put(opp.AccountId, null);
          }
        }
        accountMap = new Map<Id, Account>([SELECT Id, Geo__c FROM Account WHERE Id IN :accountMap.keySet()]);
      }
      return accountMap;
    }
    set;
  }*/

  /**
   * @Description: Returns the record type id for CPQ Record type
   */
  /*private static Id getCPQRecordTypeId() {
    Id cpqRtId = null;
    CPQ_Controls__mdt cpqControls = null;

    cpqControls = [
      SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_OpportunityListController__c
      FROM CPQ_Controls__mdt
      LIMIT 1
    ];

    if (
      Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c)
        .getRecordTypeId() != null
    ) {
      cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c)
        .getRecordTypeId();
    }

    return cpqRtId;
  }*/

  /*private void setPremiumCare() {
        List<Opportunity> triggerOpps = new List<Opportunity>();
        for (Opportunity opp : (List<Opportunity>) Trigger.new) {
            if (opp.SBQQ__Contracted__c && !((Opportunity) Trigger.oldMap.get(opp.Id)).SBQQ__Contracted__c) {
                triggerOpps.add(opp);
            }
        }
        
        if(triggerOpps.size() > 0)
            CPQPremiumCareService.setPremiumCare(triggerOpps);
    }*/

  /*private void setOppSubType() {
    List<Id> triggerOppsId = new List<Id>();

    for (Opportunity opp : (List<Opportunity>) Trigger.new) {
      if (
        !System.isFuture() &&
        opp.SBQQ__Contracted__c &&
        !((Opportunity) Trigger.oldMap.get(opp.Id)).SBQQ__Contracted__c &&
        (opp.Opportunity_Type__c != null &&
        (opp.Opportunity_Type__c == 'Amendment' ||
        opp.Opportunity_Type__c == 'Renewal'))
      ) {
        triggerOppsId.add(opp.Id);
      }
    }

    if (triggerOppsId.size() > 0) {
      CPQOppSubTypeService.processOpps(triggerOppsId);
    }
  }*/
}