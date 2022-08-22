/**
 * File Name: QuoteLineItems_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public with sharing class QuoteLineItems_PP extends fflib_SObjectDomain implements IQuoteLineItems_PP {
  public QuoteLineItems_PP(List<SBQQ__QuoteLine__c> records) {
    super(records, Schema.SBQQ__QuoteLine__c.SObjectType);
  }

  public static QuoteLineItems_PP newInstance(Set<Id> ids) {
    return (QuoteLineItems_PP) Application_PP.Domain.newInstance(ids);
  }

  public static QuoteLineItems_PP newInstance(List<SBQQ__QuoteLine__c> records) {
    return (QuoteLineItems_PP) Application_PP.Domain.newInstance(records, Schema.SBQQ__QuoteLine__c.SObjectType);
  }

  public Set<Id> getProductIds() {
    Set<Id> result = new Set<Id>();
    for (SBQQ__QuoteLine__c record : getQuoteLineItems()) {
      result.add(record.SBQQ__Product__c);
    }
    return result;
  }

  public List<SBQQ__QuoteLine__c> getQuoteLineItems() {
    return (List<SBQQ__QuoteLine__c>) getRecords();
  }

  public IQuoteLineItems_PP selectByQuoteId(Id id) {
    return selectByQuoteId(new Set<Id>{ id });
  }

  public IQuoteLineItems_PP selectByQuoteId(Set<Id> ids) {
    List<SBQQ__QuoteLine__c> result = new List<SBQQ__QuoteLine__c>();
    for (SBQQ__QuoteLine__c record : getQuoteLineItems()) {
      if (ids.contains(record.SBQQ__Quote__c)) {
        result.add(record);
      }
    }
    return new QuoteLineItems_PP(result);
  }

  public void setDiscountByProductId(Map<Id, Decimal> discountByProductId) {
    setDecimalFieldByProductId(SBQQ__QuoteLine__c.Partner_Tier_Level_Discount__c, discountByProductId);
  }

  public IQuoteLineItems_PP increaseDiscountByProductId(Map<Id, Decimal> discountByProductId) {
    increaseDecimalFieldByProductId(SBQQ__QuoteLine__c.Partner_Tier_Level_Discount__c, discountByProductId);
    return this;
  }

  public IQuoteLineItems_PP increaseUpliftByProductId(Map<Id, Decimal> discountByProductId) {
    increaseDecimalFieldByProductId(SBQQ__QuoteLine__c.Business_Partner_Type_Discount__c, discountByProductId);
    return this;
  }

  public IQuoteLineItems_PP setUpliftByProductId(Map<Id, Decimal> discountByProductId) {
    setDecimalFieldByProductId(SBQQ__QuoteLine__c.Business_Partner_Type_Discount__c, discountByProductId);
    return this;
  }

  private void setDecimalFieldByProductId(Schema.SObjectField sObjectField, Map<Id, Decimal> discountByProductId) {
    for (SBQQ__QuoteLine__c record : getQuoteLineItems()) {
      if (discountByProductId.containsKey(record.SBQQ__Product__c)) {
        record.put(sObjectField, discountByProductId.get(record.SBQQ__Product__c));
      }
    }
  }

  public IQuoteLineItems_PP setPartnerTierLevelDiscount(Integer discount) {
    for (SBQQ__QuoteLine__c record : getQuoteLineItems()) {
      record.Partner_Tier_Level_Discount__c = discount;
    }
    return this;
  }

  public IQuoteLineItems_PP setBusinessPartnerTypeDiscount(Integer discount) {
    for (SBQQ__QuoteLine__c record : getQuoteLineItems()) {
      record.Business_Partner_Type_Discount__c = discount;
    }
    return this;
  }

  private void increaseDecimalFieldByProductId(Schema.SObjectField sObjectField, Map<Id, Decimal> discountByProductId) {
    for (SBQQ__QuoteLine__c record : getQuoteLineItems()) {
      if (discountByProductId.containsKey(record.SBQQ__Product__c)) {
        if (record.get(sObjectField) == null) {
          record.put(sObjectField, discountByProductId.get(record.SBQQ__Product__c));
        } else {
          record.put(
            sObjectField,
            (Decimal) record.get(sObjectField) + discountByProductId.get(record.SBQQ__Product__c)
          );
        }
      }
    }
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new QuoteLineItems_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new QuoteLineItems_PP(sObjectList);
    }
  }
}