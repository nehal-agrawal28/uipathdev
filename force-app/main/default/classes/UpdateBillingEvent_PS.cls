public class UpdateBillingEvent_PS {
  @AuraEnabled
  public static void updateTheBillingEvent(String recordId) {
    List<pse__Billing_Event__c> scope = [
      SELECT
        Id,
        Actual_Expense_Cost__c,
        Planned_Milestone_Costs__c,
        Planned_Timecard_Costs__c,
        Total_Expenses__c,
        Total_Milestone_Fees__c,
        Total_Timecard_Fees__c,
        (SELECT Id, pse__Rounded_Amount__c, pse__Category__c FROM pse__Billing_Event_Items__r)
      FROM pse__Billing_Event__c
      WHERE Id = :recordId
    ];
    Map<Id, Double> milestoneCostByEvent = new Map<Id, Double>();
    Map<Id, Double> milestoneFeesByEvent = new Map<Id, Double>();
    Map<Id, Double> timecardFeesByEvent = new Map<Id, Double>();
    Map<Id, Double> expenseFeesByEvent = new Map<Id, Double>();
    Map<Id, Double> plannedTimecardCostByEvent = new Map<Id, Double>();

    Id parentEventId;
    for (pse__Billing_Event__c billingEvent : scope) {
      milestoneFeesByEvent.put(billingEvent.Id, 0);
      timecardFeesByEvent.put(billingEvent.Id, 0);
      expenseFeesByEvent.put(billingEvent.Id, 0);
      for (pse__Billing_Event_Item__c billingEventItem : billingEvent.pse__Billing_Event_Items__r) {
        if (billingEventItem.pse__Rounded_Amount__c != null) {
          if (billingEventItem.pse__Category__c == 'Expense') {
            expenseFeesByEvent.put(
              billingEvent.Id,
              expenseFeesByEvent.get(billingEvent.Id) + billingEventItem.pse__Rounded_Amount__c
            );
          } else if (billingEventItem.pse__Category__c == 'Milestone') {
            milestoneFeesByEvent.put(
              billingEvent.Id,
              milestoneFeesByEvent.get(billingEvent.Id) + billingEventItem.pse__Rounded_Amount__c
            );
          } else if (billingEventItem.pse__Category__c == 'Timecard') {
            timecardFeesByEvent.put(
              billingEvent.Id,
              timecardFeesByEvent.get(billingEvent.Id) + billingEventItem.pse__Rounded_Amount__c
            );
          }
        }
      }
    }
    for (pse__Billing_Event_Item__c billingEventItem : [
      SELECT
        Id,
        pse__Billing_Event__c,
        (SELECT Id, pse__Milestone_Cost__c FROM pse__Milestones__r WHERE pse__Milestone_Cost__c != NULL),
        (
          SELECT Id, Planned_Cost__c, pse__Assignment__r.Assignment_Billing_Type__c
          FROM pse__Timecard_Splits__r
          WHERE Planned_Cost__c != NULL AND pse__Assignment__r.Assignment_Billing_Type__c != NULL
        )
      FROM pse__Billing_Event_Item__c
      WHERE pse__Billing_Event__c IN :scope AND pse__Billing_Event__c != NULL
    ]) {
      parentEventId = billingEventItem.pse__Billing_Event__c;
      if (!milestoneCostByEvent.containsKey(parentEventId)) {
        milestoneCostByEvent.put(parentEventId, 0);
      }

      if (!plannedTimecardCostByEvent.containsKey(parentEventId)) {
        plannedTimecardCostByEvent.put(parentEventId, 0);
      }

      System.debug('@@parentEventId' + parentEventId);
      for (pse__Timecard__c timecard : billingEventItem.pse__Timecard_Splits__r) {
        if (timecard.pse__Assignment__r.Assignment_Billing_Type__c == 'T&M') {
          System.debug('@@inside T and M');
          plannedTimecardCostByEvent.put(
            parentEventId,
            plannedTimecardCostByEvent.get(parentEventId) + timecard.Planned_Cost__c
          );
        }
      }
      System.debug('@@billingEventItem.pse__Milestones__r' + billingEventItem.pse__Milestones__r);
      for (pse__Milestone__c milestone : billingEventItem.pse__Milestones__r) {
        milestoneCostByEvent.put(
          parentEventId,
          milestoneCostByEvent.get(parentEventId) + milestone.pse__Milestone_Cost__c
        );
        System.debug('@@milestoneCostByevent' + milestoneCostByevent);
        System.debug('@@milestone.pse__Milestone_Cost__c' + milestone.pse__Milestone_Cost__c);
      }
    }

    System.debug('@@plannedTimecardCostByEvent' + plannedTimecardCostByEvent);
    for (pse__Billing_Event__c billingEvent : scope) {
      System.debug('@@billingEvent' + billingEvent.Id);
      billingEvent.Actual_Expense_Cost__c = expenseFeesByEvent.get(billingEvent.Id);
      billingEvent.Planned_Milestone_Costs__c = milestoneCostByEvent.get(billingEvent.Id);
      billingEvent.Total_Expenses__c = expenseFeesByEvent.get(billingEvent.Id);
      billingEvent.Total_Milestone_Fees__c = milestoneFeesByEvent.get(billingEvent.Id);
      billingEvent.Total_Timecard_Fees__c = timecardFeesByEvent.get(billingEvent.Id);
      billingEvent.Planned_Timecard_Costs__c = plannedTimecardCostByEvent.get(billingEvent.Id);
    }

    List<Database.SaveResult> srList = DataBase.update(scope, false);
    for (Database.SaveResult sr : srList) {
      if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully updated Biling event ID: ' + sr.getId());
      } else {
        // Operation failed, so get all errors
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Billing event fields that affected this error: ' + err.getFields());
        }
      }
    }
  }
}