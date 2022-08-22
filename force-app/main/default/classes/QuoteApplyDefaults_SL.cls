public with sharing class QuoteApplyDefaults_SL implements SObjectToSObjectFunction {
  private static Map<Id, Opportunity> oppMap;
  private static Map<Id, Account> quoteAccountMap;

  public QuoteApplyDefaults_SL(List<SBQQ__Quote__c> records) {
    Set<Id> opportunityIds = new Set<Id>(Collection.of(records).pluckIds(SBQQ__Quote__c.SBQQ__Opportunity2__c));

    Set<Id> accountIds = new Set<Id>(Collection.of(records).pluckIds(SBQQ__Quote__c.SBQQ__Account__c));

    oppMap = new Map<Id, Opportunity>(
      [
        SELECT
          Id,
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
          CPQ_OpportunityTCV__c
        FROM Opportunity
        WHERE id IN :opportunityIds
      ]
    );

    for (Opportunity opp : oppMap.values()) {
      if (opp.Sold_to_Partner__c != null && !accountIds.contains(opp.Sold_to_Partner__c)) {
        accountIds.add(opp.Sold_to_Partner__c);
      }
    }

    quoteAccountMap = new Map<Id, Account>(
      [SELECT Id, Region__c, Geo__c, Area__c, Default_Payment_Terms__c FROM Account WHERE Id IN :accountIds]
    );
  }

  public SObject apply(SBQQ__Quote__c quote) {
    if (oppMap != null && oppMap.containsKey(quote.SBQQ__Opportunity2__c)) {
      Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c);

      setSalesRepDefault(quote, opp);
      setStartDateToToday(quote);
      defaultToStandardPriceBook(quote);
      setPartnerAccounts(quote, opp);
      setPaymentTerms(quote, opp);
      //setManagingDirector(quote, opp);
      setQuoteTypeToRenewal(quote, opp);
    }

    return quote;
  }

  public static void setSalesRepDefault(SBQQ__Quote__c quote, Opportunity opp) {
    if (quote.SBQQ__SalesRep__c == null && quote.SBQQ__Opportunity2__c != null && opp != null) {
      quote.SBQQ__SalesRep__c = opp.OwnerId;
    }
  }

  private void setStartDateToToday(SBQQ__Quote__c quote) {
    if (quote.SBQQ__StartDate__c == null) {
      quote.SBQQ__StartDate__c = Date.today();
    }
  }

  public static void defaultToStandardPriceBook(SBQQ__Quote__c quote) {
    if (quote.SBQQ__PricebookId__c == null) {
      quote.SBQQ__PricebookId__c = Test.isRunningTest()
        ? Test.getStandardPricebookId()
        : SingletonFactory.getStandardPriceBookInstance().Id;
    }
  }

  public static void setPartnerAccounts(SBQQ__Quote__c quote, Opportunity opportunity) {
    if (opportunity == null) {
      return;
    }

    if (opportunity.Deal_Type__c == null) {
      return;
    }

    switch on opportunity.Deal_Type__c {
      when 'Resale' {
        if (opportunity.Tier_2_Partner__c != null && opportunity.Sold_to_Partner__c != null) {
          quote.SBQQ__Partner__c = opportunity.Tier_2_Partner__c;
          quote.SBQQ__Distributor__c = opportunity.Sold_to_Partner__c;
          quote.Bill_To_Account__c = opportunity.Sold_to_Partner__c;
        } else if (opportunity.Sold_to_Partner__c != null) {
          quote.SBQQ__Partner__c = opportunity.Sold_to_Partner__c;
          quote.Bill_To_Account__c = opportunity.Sold_to_Partner__c;
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

  public static void setPaymentTerms(SBQQ__Quote__c quote, Opportunity opportunity) {
    if (opportunity == null) {
      return;
    }

    if (opportunity.Deal_Type__c == null) {
      return;
    }

    switch on opportunity.Deal_Type__c {
      when 'Resale' {
        if (
          quoteAccountMap != null &&
          opportunity.Sold_to_Partner__c != null &&
          quoteAccountMap.containsKey(opportunity.Sold_to_Partner__c)
        ) {
          if (String.isNotEmpty(quoteAccountMap.get(opportunity.Sold_to_Partner__c).Default_Payment_Terms__c)) {
            quote.Payment_Terms__c = quoteAccountMap.get(opportunity.Sold_to_Partner__c).Default_Payment_Terms__c;
          } else {
            quote.Payment_Terms__c = Constants_SL.PAYMENT_TERMS_NET30;
          }
        } else {
          quote.Payment_Terms__c = Constants_SL.PAYMENT_TERMS_NET30;
        }
      }
      when else {
        if (quoteAccountMap != null && quoteAccountMap.containsKey(opportunity.AccountId)) {
          if (String.isNotEmpty(quoteAccountMap.get(opportunity.AccountId).Default_Payment_Terms__c)) {
            quote.Payment_Terms__c = quoteAccountMap.get(opportunity.AccountId).Default_Payment_Terms__c;
          } else {
            quote.Payment_Terms__c = Constants_SL.PAYMENT_TERMS_NET30;
          }
        }
      }
    }
  }

  /*public static void setManagingDirector(SBQQ__Quote__c quote, Opportunity opportunity) {
    if (opportunity == null || quote == null) {
      return;
    }

    if (opportunity.Managing_Director__c <> null) {
      quote.Managing_Director__c = opportunity.Managing_Director__c;
    }
  }*/

  public static void setQuoteTypeToRenewal(SBQQ__Quote__c quote, Opportunity opportunity) {
    if (opportunity != null && opportunity.SBQQ__Renewal__c) {
      quote.SBQQ__Type__c = Constants.QUOTE_RENEWAL_TYPE;
    }
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  public static void setQuoteDefaults(List<SBQQ__Quote__c> quotes) {
    Collection.of(quotes)
      .filter(Match.field(SBQQ__Quote__c.SBQQ__Opportunity2__c).hasValue())
      .mapAll(new QuoteApplyDefaults_SL(quotes));
  }
}