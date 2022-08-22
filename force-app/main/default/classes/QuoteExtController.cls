public with sharing class QuoteExtController {
  private Id quoteId;
  public SBQQ__Quote__c quote {
    get {
      if (quote == null) {
        quote = [
          SELECT
            Id,
            Discount_Reasons__c,
            SBQQ__Opportunity2__r.Owner.ManagerId,
            Credit_Hold_Status__c,
            Payment_Terms__c,
            Forecast_Quote__c,
            PS_Investment_Deal__c,
            Service_Investment_Type__c,
            SBQQ__Status__c
          FROM SBQQ__Quote__c
          WHERE Id = :quoteId
        ];
      }
      return quote;
    }
    set;
  }

  public QuoteExtController(ApexPages.StandardController stdController) {
    quoteId = stdController.getId();
  }

  public PageReference onSubmit() {
    if (quoteId != null) {
      //populate dynamic approvers
      List<SBQQ__Quote__c> approverQuoteList = DynamicApproverFactory.populateDynamicApprovers(new List<Id>{ quoteId });
      System.debug('** approverQuoteList: ' + approverQuoteList);
      try {
        update approverQuoteList;
      } catch (Exception e) {
        if (!e.getMessage().contains('SCOPE attached')) {
          // bypass errors for SCOPE attached quote
          throw e;
        }
      }

      SBQQ__Quote__c quoteToUpdate = new SBQQ__Quote__c();
      quoteToUpdate.Id = quote.Id;
      quoteToUpdate.Discount_Reasons__c = quote.Discount_Reasons__c;
      quoteToUpdate.Service_Investment_Type__c = quote.Service_Investment_Type__c;

      // Reset approval key fields
      quoteToUpdate.X1st_Level_Approver__c = null; // quote trigger will populate latest value
      quoteToUpdate.Regional_Commercial_Finance_Leader__c = null; // quote trigger will populate latest value
      quoteToUpdate.Sales_Rep_s_Manager__c = quote.SBQQ__Opportunity2__r.Owner.ManagerId;

      try {
        update quoteToUpdate;
      } catch (Exception e) {
        System.debug('Exception onSubmit ' + e.getMessage() + e.getStackTraceString());
      }

      if (quote.Forecast_Quote__c) {
        ApexPages.addmessage(
          new ApexPages.message(
            ApexPages.severity.FATAL,
            'Forecast Quotes cannot be submitted for approval or presented to the customer.'
          )
        );
        return null;
      }

      if (quote != null && (quote.Credit_Hold_Status__c != 'On' || quote.Payment_Terms__c == 'Prepayment')) {
        SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
        return new PageReference('/' + quoteId);
      } else {
        ApexPages.addmessage(
          new ApexPages.message(ApexPages.severity.FATAL, system.label.Account_Credit_Hold_Quote_Approval_Warning)
        );
        return null;
      }
    }
    return new PageReference('/' + quoteId);
  }

  public PageReference onRecall() {
    if (quoteId != null) {
      if (quote.SBQQ__Status__c == 'Accepted' || quote.SBQQ__Status__c == 'Booked') {
        ApexPages.addmessage(
          new ApexPages.message(ApexPages.severity.FATAL, 'Accepted/Booked quotes can not be recalled')
        );
      } else {
        SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
      }
    }
    return new PageReference('/' + quoteId);
  }

  public PageReference onCancel() {
    return new PageReference('/' + quoteId);
  }
}