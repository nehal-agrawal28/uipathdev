public with sharing class ApexJobSelector_CM {
  public static List<ApexJobStatusMsg_CM> getJobStatusById(List<String> jobIds) {
    return getJobStatusById(new Set<String>(jobIds));
  }

  public static List<ApexJobStatusMsg_CM> getJobStatusById(Set<String> jobIds) {
    List<ApexJobStatusMsg_CM> jobStatuses = new List<ApexJobStatusMsg_CM>();
    // Not enforcing sharing since we want to get these records back to get the status
    List<AsyncApexJob> jobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Id IN :jobIds];
    for (AsyncApexJob job : jobs) {
      jobStatuses.add(new ApexJobStatusMsg_CM(job.Id, job.Status));
    }
    return jobStatuses;
  }
}