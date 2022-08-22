/**
 * @DESCRIPTION: Lightning Component controller for quoteAddressContainer, which allows user to select bill to and
 *               ship to addresses on a quote
 * @AUTHOR: SV - Slalom Consulting
 */
public with sharing class QuoteAddressContainerController {
  /**
   * @DESCRIPTION: Retrieve quote based on quote id
   * @RETURN: SBQQ__Quote__c
   * @PARAM: Id
   * @AUTHOR: SV Slalom Consulting
   */
  @AuraEnabled
  public static SBQQ__Quote__c retrieveQuote(Id quoteId) {
    SBQQ__Quote__c quote = [SELECT Id, Bill_To_Address__c, Ship_To_Address__c FROM SBQQ__Quote__c WHERE Id = :quoteId];
    return quote;
  }

  /**
   * @DESCRIPTION: Retrieve current bill to and ship to quote addresses
   * @RETURN: List<Address__c>, list of current addresses
   * @PARAM: bill to and ship to address Id's
   * @AUTHOR: SV Slalom Consulting
   */
  @AuraEnabled
  public static List<Address__c> retrieveCurrentAddresses(Id billToAddressId, Id shipToAddressId) {
    List<Address__c> addressList = [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Street_Line_1__c,
        Street_Line_2__c,
        Zip_Postal_Code__c,
        City__c,
        State__c,
        Country__c,
        Attention__c,
        JP_Attention_2__c
      FROM Address__c
      WHERE Id = :billToAddressId OR Id = :shipToAddressId
    ];
    return addressList;
  }

  /**
   * @DESCRIPTION: Retrieve possible addresses that could be selected as bill to and ship to addresses on quote
   * @RETURN: List<Address__c> address options
   * @PARAM: Id quoteId, String selectorMode (can be BillTo or ShipTo)
   * @AUTHOR: SV Slalom Consulting
   */
  @AuraEnabled
  public static List<Address__c> retrieveAddressOptionList(Id quoteId, String selectorMode) {
    SBQQ__Quote__c quote = [
      SELECT
        Id,
        Bill_To_Account__c,
        SBQQ__Account__c,
        SBQQ__Partner__c,
        SBQQ__Distributor__c,
        Bill_To_Address__c,
        Ship_To_Address__c
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
    ];
    Set<Id> accountIds = new Set<Id>();
    if (selectorMode == 'BillTo') {
      //Only retrieve addresses of bill to account
      accountIds.add(quote.Bill_To_Account__c);
    } else if (selectorMode == 'ShipTo') {
      //Retrieve addresses of bill to account
      accountIds.add(quote.Bill_To_Account__c);
      accountIds.add(quote.SBQQ__Account__c);
      accountIds.add(quote.SBQQ__Partner__c);
      accountIds.add(quote.SBQQ__Distributor__c);
    }
    List<Address__c> addressList = [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Street_Line_1__c,
        Street_Line_2__c,
        Zip_Postal_Code__c,
        City__c,
        State__c,
        Country__c,
        Attention__c,
        JP_Attention_2__c,
        Primary_Billing__c,
        Primary_Shipping__c
      FROM Address__c
      WHERE Account__c IN :accountIds AND Stripe_Customer_ID__c = NULL
    ];
    return addressList;
  }

  /**
   * @DESCRIPTION: Update quote to set the selected address as either bill to or ship to
   * @RETURN: Nothing
   * @PARAM: Id quoteId, Id addressId,, String selectorMode (can be BillTo or ShipTo)
   * @AUTHOR: SV Slalom Consulting
   */
  @AuraEnabled
  public static void setQuoteAddress(Id quoteId, Id addressId, String selectorMode) {
    SBQQ__Quote__c quote = [
      SELECT
        Id,
        Bill_To_Account__c,
        SBQQ__Account__c,
        SBQQ__Partner__c,
        SBQQ__Distributor__c,
        Bill_To_Address__c,
        Ship_To_Address__c
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
    ];

    if (selectorMode == 'BillTo') {
      quote.Bill_To_Address__c = addressId;
    } else if (selectorMode == 'ShipTo') {
      quote.Ship_To_Address__c = addressId;
    }

    update quote;
  }
}