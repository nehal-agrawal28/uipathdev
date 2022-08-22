public with sharing class CPQModel_Quote_SL {
  public SBQQ__Quote__c record { get; set; }
  public CPQModel_QuoteLine_SL[] lineItems { get; set; }
  public CPQModel_QuoteLineGroup_SL[] lineItemGroups { get; set; }
  public Integer nextKey;
  public Boolean applyAdditionalDiscountLast;
  public Boolean applyPartnerDiscountFirst;
  public Boolean channelDiscountsOffList;
  public Decimal customerTotal;
  public Decimal netTotal;
  public Decimal netNonSegmentTotal;
}