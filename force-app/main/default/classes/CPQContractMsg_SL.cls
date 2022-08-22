public with sharing class CPQContractMsg_SL {
  @AuraEnabled
  public String id { get; set; }
  @AuraEnabled
  public String accountName { get; set; }
  @AuraEnabled
  public String contractNumber { get; set; }
  @AuraEnabled
  public Date startDate { get; set; }
  @AuraEnabled
  public Date endDate { get; set; }
  @AuraEnabled
  public Boolean terminate { get; set; }
  @AuraEnabled
  public Date terminationDate { get; set; }
  @AuraEnabled
  public Integer contractTerm { get; set; }
}