public with sharing class ApexJobStatusMsg_CM {
  @AuraEnabled
  public String jobId { get; set; }
  @AuraEnabled
  public String jobStatus { get; set; }

  public ApexJobStatusMsg_CM(String jobId, String jobStatus) {
    this.jobId = jobId;
    this.jobStatus = jobStatus;
  }
}