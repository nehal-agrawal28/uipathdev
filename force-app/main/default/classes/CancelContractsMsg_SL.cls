/**
 * Message class that stores data for amending contracts and creating a new opportunity and quote
 */
public with sharing class CancelContractsMsg_SL {
  @AuraEnabled
  public List<String> contractIds { get; set; }
  @AuraEnabled
  public String startDate { get; set; }
  @AuraEnabled
  public String endDate { get; set; }
  @AuraEnabled
  public String accountId { get; set; }
  // @AuraEnabled
  // public Integer termLength { get; set; }
  @AuraEnabled
  public String opportunityStage { get; set; }
  @AuraEnabled
  public String opportunityDealType { get; set; }
  @AuraEnabled
  public String opportunityCurrency { get; set; }
  @AuraEnabled
  public String soldToPartnerId { get; set; }
  @AuraEnabled
  public String opportunityName { get; set; }
  @AuraEnabled
  public String existingOpportunityId { get; set; }
  @AuraEnabled
  public String existingQuoteId { get; set; }
}