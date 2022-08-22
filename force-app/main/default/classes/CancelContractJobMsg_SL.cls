public with sharing class CancelContractJobMsg_SL {
  @AuraEnabled
  public String opportunityId { get; set; }
  @AuraEnabled
  public String quoteId { get; set; }
  @AuraEnabled
  public String quoteName { get; set; }
  @AuraEnabled
  public List<JobStatus> jobs { get; set; }

  public CancelContractJobMsg_SL() {
    jobs = new List<JobStatus>();
  }

  public class JobStatus {
    @AuraEnabled
    public String contractId { get; set; }
    @AuraEnabled
    public String jobId { get; set; }

    public JobStatus(String contractId, String jobId) {
      this.contractId = contractId;
      this.jobId = jobId;
    }
  }
}