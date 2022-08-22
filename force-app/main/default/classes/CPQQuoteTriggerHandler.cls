/**
 * -- / Pierre Gousse
 * @date 18/03/2019
 * @description Event listeners for Quote Trigger. This class should ideally delegate work to Domain/Service classes
 */
public class CPQQuoteTriggerHandler extends TriggerHandler {
  private static List<CPQ_Controls__mdt> cpqControlsList;

  private String defaultCongaTemplateId;
  private String skuCongaTemplateId;
  private String defaultEmailTemplateId;
  private String jpyCongaTemplateId;
  private String jpyEmailTemplateId;
  private String distiCongaTemplateId;
  private id engRipAndReplaceCongaTemplateId;
  private List<User> userList;

  public override void beforeInsert() {
    this.applyDefaults();
    this.applyQuoteApprovalMatrix(null, Trigger.new);
    this.removeDocumentRefBeforeInsert();
  }

  public override void beforeUpdate() {
    this.applyQuoteApprovalMatrix(Trigger.oldMap, Trigger.new);
    this.setQuoteCongaTemplateIdOnUpdate(Trigger.oldMap, Trigger.new);
  }

  public override void afterInsert() {
    this.setDocumentRefOnQuote();
  }

  private id getJPYCongaTemplateId() {
    return cpqControlsList[0].JA_CPQ_Template__c;
  }

  private id getJPYEmailTemplateID() {
    return cpqControlsList[0].JA_CPQ_Email_Template__c;
  }

  private id getDefaultCongaTemplateId() {
    return cpqControlsList[0].EN_CPQ_Template__c;
  }

  private id getSKUCongaTemplateId() {
    return cpqControlsList[0].EN_CPQ_Template_SKU__c;
  }

  private id getDefaultEmailTemplateID() {
    return cpqControlsList[0].EN_CPQ_Email_Template__c;
  }

  private id getDistiCongaTemplateId() {
    return cpqControlsList[0].EN_Disti_CPQ_Template__c;
  }

  private id getRipAndReplaceEngCongaTemplateId() {
    return cpqControlsList[0].EN_CPQ_Rip_and_Replace_Template__c;
  }

  private List<User> getUserList(Set<String> approverEmailSet) {
    if (this.userList == null) {
      this.userList = [SELECT Id, Email FROM User WHERE Email IN :approverEmailSet];
    }

    return this.userList;
  }

  private void applyDefaults() {
    Map<Id, Opportunity> opportunitiesByIds = getOpportunitiesByIds();
    /* Retrieve CPQ Quote Template name from Custom Metadata CPQ_Controls__mdt */
    cpqControlsList = [
      SELECT
        Id,
        JA_CPQ_Template__c,
        JA_CPQ_Email_Template__c,
        EN_CPQ_Template__c,
        EN_CPQ_Email_Template__c,
        EN_Disti_CPQ_Template__c,
        EN_CPQ_Template_SKU__c,
        EN_CPQ_Rip_and_Replace_Template__c
      FROM CPQ_Controls__mdt
      LIMIT 1
    ];

    if (!cpqControlsList.isEmpty()) {
      defaultCongaTemplateId = getDefaultCongaTemplateId();
      skuCongaTemplateId = getSKUCongaTemplateId();
      defaultEmailTemplateId = getDefaultEmailTemplateID();
      jpyCongaTemplateId = getJPYCongaTemplateId();
      jpyEmailTemplateId = getJPYEmailTemplateID();
      distiCongaTemplateId = getDistiCongaTemplateId();
      engRipAndReplaceCongaTemplateId = getRipAndReplaceEngCongaTemplateId();
    }

    for (SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.new) {
      setQuoteCongaTemplateId(quote, opportunitiesByIds.get(quote.SBQQ__Opportunity2__c));
    }
  }

  private static Map<Id, Account> quoteAccountMap {
    get {
      if (quoteAccountMap == null || quoteAccountMap.isEmpty()) {
        Set<Id> accIds = new Set<Id>();
        for (SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.new) {
          accIds.add(quote.SBQQ__Account__c);
        }

        quoteAccountMap = new Map<Id, Account>(
          [SELECT Id, Region__c, Geo__c, Area__c FROM Account WHERE Id IN :accIds]
        );
      }

      return quoteAccountMap;
    }
    set;
  }

  private static Map<Id, Opportunity> oppMap;
  private Map<Id, Opportunity> getOpportunitiesByIds() {
    if (oppMap != null && !oppMap.isEmpty()) {
      return oppMap;
    }

    Set<Id> opportunityIds = new Set<Id>();
    for (SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.new) {
      opportunityIds.add(quote.SBQQ__Opportunity2__c);
    }
    oppMap = new Map<id, Opportunity>(
      [
        SELECT
          id,
          Account.Geo__c,
          Account.Region__c,
          Account.Area__c,
          Deal_Type__c,
          Sold_to_Partner__c,
          Sold_to_Partner__r.Geo__c,
          Sold_to_Partner__r.Region__c,
          Sold_to_Partner__r.Area__c,
          Sold_to_Partner_Type__c,
          Tier_2_Partner__c,
          AccountId,
          Managing_Director__c,
          CurrencyIsoCode,
          SBQQ__Renewal__c,
          Contract_Start_Date__c,
          Contract_End_Date__c,
          OwnerId,
          Account_Geo__c,
          CPQ_OpportunityACV__c,
          CPQ_OpportunityARR__c,
          CPQ_OpportunityTCV__c,
          Territory2Id,
          Territory2.AVP_Id__c
        FROM Opportunity
        WHERE id IN :opportunityIds
      ]
    );
    return oppMap;
  }

  /**
     * Sets Partner Accounts and derives Who the Bill To is
      @param quote
      @param opportunity
     */
  private void setPartnerAccounts(SBQQ__Quote__c quote, Opportunity opportunity) {
    if (opportunity == null) {
      return;
    }

    if (opportunity.Deal_Type__c == null) {
      return;
    }

    switch on opportunity.Deal_Type__c {
      when 'Resale' {
        if (opportunity.Tier_2_Partner__c <> null && opportunity.Sold_to_Partner__c != null) {
          quote.SBQQ__Partner__c = opportunity.Tier_2_Partner__c;
          quote.SBQQ__Distributor__c = opportunity.Sold_to_Partner__c;
          quote.Bill_To_Account__c = opportunity.Sold_to_Partner__c;
          // quote.Bill_To_Region__c = opportunity.Sold_to_Partner__r.Region__c;
          // quote.Bill_To_Geo_New__c = opportunity.Sold_to_Partner__r.Geo__c;
        } else if (opportunity.Sold_to_Partner__c != null) {
          quote.SBQQ__Partner__c = opportunity.Sold_to_Partner__c;
          quote.Bill_To_Account__c = opportunity.Sold_to_Partner__c;
          // quote.Bill_To_Region__c = opportunity.Sold_to_Partner__r.Region__c;
          // quote.Bill_To_Geo_New__c = opportunity.Sold_to_Partner__r.Geo__c;
        }

        if (quoteAccountMap.containsKey(quote.SBQQ__Account__c)) {
          quote.Bill_To_Region__c = quoteAccountMap.get(quote.SBQQ__Account__c).Region__c;
          quote.Bill_To_Geo_New__c = quoteAccountMap.get(quote.SBQQ__Account__c).Geo__c;
          quote.Bill_To_Area__c = quoteAccountMap.get(quote.SBQQ__Account__c).Area__c;
        }
      }
      when else {
        quote.Bill_To_Account__c = opportunity.AccountId;
        quote.Bill_To_Region__c = opportunity.Account.Region__c;
        quote.Bill_To_Geo_New__c = opportunity.Account.Geo__c;
        quote.Bill_To_Area__c = opportunity.Account.Area__c;
      }
    }
  }

  /**
    * Sets Conga Quote Template Id and Conga Email Template Id on Quote based on Opportunity Currency and Conga Template/Conga Email Template store on CPQ metadata
     @param quote
     @param opportunity
    */
  private void setQuoteCongaTemplateId(SBQQ__Quote__c quote, Opportunity opportunity) {
    if (opportunity != null && opportunity.CurrencyIsoCode != null) {
      switch on opportunity.CurrencyIsoCode {
        when 'JPY' {
          if (string.isNotEmpty(jpyCongaTemplateId)) {
            quote.Conga_Quote_Template_Id__c = jpyCongaTemplateId;
          }

          if (string.isNotEmpty(jpyEmailTemplateId)) {
            quote.Conga_Email_Template_Id__c = jpyEmailTemplateId;
          }
        }
        when else {
          if (string.isNotEmpty(defaultCongaTemplateId)) {
            if (quote.Show_SKU__c == true && String.isNotEmpty(skuCongaTemplateId)) {
              quote.Conga_Quote_Template_Id__c = skuCongaTemplateId;
            } else {
              quote.Conga_Quote_Template_Id__c = defaultCongaTemplateId;
            }
          }
          if (string.isNotEmpty(engRipAndReplaceCongaTemplateId) && quote.Replacement_Transaction__c == true) {
            quote.Conga_Quote_Template_Id__c = engRipAndReplaceCongaTemplateId;
          }
          if (string.isNotEmpty(defaultEmailTemplateId)) {
            quote.Conga_Email_Template_Id__c = defaultEmailTemplateId;
          }
        }
      }
    }
  }

  /**
   * @DESCRIPTION: Updates the quote template Id when "Show_SKU__c is checked"
   * @TODO: Refactor the Conga Template Implementation, as the template contains too many IFs and Word can't support this
   * @AUTHOR: RA - UiPath
   */
  private void setQuoteCongaTemplateIdOnUpdate(Map<Id, SObject> oldQuotesMap, List<SObject> quotesList) {
    cpqControlsList = [
      SELECT Id, EN_CPQ_Template__c, EN_CPQ_Template_SKU__c, EN_CPQ_Rip_and_Replace_Template__c
      FROM CPQ_Controls__mdt
      LIMIT 1
    ];

    if (!cpqControlsList.isEmpty()) {
      defaultCongaTemplateId = getDefaultCongaTemplateId();
      skuCongaTemplateId = getSKUCongaTemplateId();
      engRipAndReplaceCongaTemplateId = getRipAndReplaceEngCongaTemplateId();
    }

    for (SBQQ__Quote__c newQuote : (List<SBQQ__Quote__c>) quotesList) {
      SBQQ__Quote__c oldQuote = null;
      if (oldQuotesMap != null) {
        oldQuote = (SBQQ__Quote__c) oldQuotesMap.get(newQuote.Id);
      }
      if (
        (oldQuote.Show_SKU__c != newQuote.Show_SKU__c) ||
        (oldQuote.Additional_Templates__c != newQuote.Additional_Templates__c)
      ) {
        if (newQuote.Show_SKU__c == true) {
          newQuote.Conga_Quote_Template_Id__c = String.isBlank(newQuote.Additional_Templates__c)
            ? skuCongaTemplateId
            : skuCongaTemplateId + ',' + newQuote.Additional_Templates__c;
        }
        if (newQuote.Show_SKU__c == false) {
          newQuote.Conga_Quote_Template_Id__c = String.isBlank(newQuote.Additional_Templates__c)
            ? defaultCongaTemplateId
            : defaultCongaTemplateId + ',' + newQuote.Additional_Templates__c;
        }
      }
      if (string.isNotEmpty(engRipAndReplaceCongaTemplateId) && newQuote.Replacement_Transaction__c == true) {
        newQuote.Conga_Quote_Template_Id__c = engRipAndReplaceCongaTemplateId;
      }
    }
  }

  /**
   * Populate approval related fields on Quote from Quote Approval Matrix table
   * @param oldSObjectMap hold trigger.oldMap records
   * @param newSObjectList hold tigger.new records
   * Updated logic according to ETM
   */
  private void applyQuoteApprovalMatrix(Map<Id, SObject> oldSObjectMap, List<SObject> newSObjectList) {
    Map<Id, SBQQ__Quote__c> oldMap = (Map<Id, SBQQ__Quote__c>) oldSObjectMap;
    List<SBQQ__Quote__c> newList = (List<SBQQ__Quote__c>) newSObjectList;

    Map<Id, Opportunity> oppMap = getOpportunitiesByIds();
    for (SBQQ__Quote__c quote : newList) {
      if (String.isBlank(quote.Bill_To_Geo_New__c)) {
        setPartnerAccounts(quote, oppMap.get(quote.SBQQ__Opportunity2__c));
      }
    }

    List<SBQQ__Quote__c> eligibleQuotes = new List<SBQQ__Quote__c>();
    List<String> geoList = new List<String>();
    QuoteApprovalMatrixSetting__c setting = QuoteApprovalMatrixSetting__c.getInstance();

    // Eligible quote validation
    for (SBQQ__Quote__c quote : newList) {
      if (
        oldMap == null ||
        quote.X1st_Level_Approver__c == null ||
        quote.Regional_Commercial_Finance_Leader__c == null
      ) {
        geoList.add(quote.Bill_To_Geo_New__c);
        eligibleQuotes.add(quote);
      }
    }

    if (!eligibleQuotes.isEmpty()) {
      // List of QAM table records
      List<Quote_Approval_Matrix__c> matrixList = [
        SELECT Id, Approver__c, Geo__c, Region__c, Area__c, Role__c, Type__c
        FROM Quote_Approval_Matrix__c
        WHERE Geo__c IN :geoList
      ];

      for (SBQQ__Quote__c quote : eligibleQuotes) {
        // Set AVP from Opportunity Territory
        if (quote.SBQQ__Opportunity2__c != null) {
          Opportunity op = oppMap.get(quote.SBQQ__Opportunity2__c);
          quote.X1st_Level_Approver__c = op != null &&
            op.Territory2Id != null
            ? op.Territory2.AVP_Id__c
            : quote.X1st_Level_Approver__c;
        }

        // Iterate each eligible quote record and populate Approver
        for (Quote_Approval_Matrix__c matrix : matrixList) {
          // Populate Regional Commercial Finance Leader from QAM table based on Geo and Type
          if (
            matrix.Geo__c == quote.Bill_To_Geo_New__c &&
            (matrix.Area__c == quote.Bill_To_Area__c || String.IsBlank(matrix.Area__c)) &&
            matrix.Type__c == 'Regional Commercial Finance Leader'
          ) {
            quote.Regional_Commercial_Finance_Leader__c = matrix.Approver__c;
            break;
          }
        }

        // Default geo approver from matrix
        if (String.isBlank(quote.X1st_Level_Approver__c)) {
          for (Quote_Approval_Matrix__c matrix : matrixList) {
            if (
              matrix.Geo__c == quote.Bill_To_Geo_New__c &&
              (matrix.Area__c == quote.Bill_To_Area__c || String.IsBlank(matrix.Area__c)) &&
              matrix.Type__c == 'Default Geo AVP'
            ) {
              quote.X1st_Level_Approver__c = matrix.Approver__c;
              break;
            }
          }
        }

        // System default approver
        if (String.isBlank(quote.X1st_Level_Approver__c)) {
          quote.X1st_Level_Approver__c = setting.Default_Approver_Id__c;
        }
        // System default approver
        if (String.isBlank(quote.Regional_Commercial_Finance_Leader__c)) {
          quote.Regional_Commercial_Finance_Leader__c = setting.Default_Approver_Id__c;
        }
      }
    }
  }

  /**
   * OI-334
   * Remove Document Ref field on quote before insert
   * to prevent duplicate external Id error on cloning
   */
  private void removeDocumentRefBeforeInsert() {
    for (SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.new) {
      quote.Document_Ref__c = null;
    }
  }

  /**
   * OI-334
   * Populate Document Ref field on quote from quote name
   * Quote name is auto-number so running logic in after trigger context
   */
  private void setDocumentRefOnQuote() {
    List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
    for (SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.new) {
      if (String.isBlank(quote.Document_Ref__c)) {
        quoteToUpdate.add(new SBQQ__Quote__c(Id = quote.Id, Document_Ref__c = quote.Name));
      }
    }
    if (!Test.isRunningTest() && quoteToUpdate.size() > 0) {
      update quoteToUpdate;
    }
  }
}