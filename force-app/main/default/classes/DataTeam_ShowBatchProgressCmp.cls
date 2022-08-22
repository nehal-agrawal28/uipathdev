global class DataTeam_ShowBatchProgressCmp {
  private List<BatchJob> batchJobs;

  /*******************************************************************************************************
   * @description number of batch jobs the control will monitor
   */
  global Integer numberOfJobs { get; set; }

  /*******************************************************************************************************
   * @description label to display at the top of the progress meter
   */
  global String batchComponentLabel { get; set; }

  public Map<String, String> apexClassMap {
    get {
      return new Map<String, String>{
        'DataTeam_UpdateOwnerAccountQueueable' => 'Account Owner Update Batch',
        'DataTeam_UpdateOwnerOppQueueable' => 'Opportunity Owner Update Batch',
        'DataTeam_UpdateOwnerLeadQueueable' => 'Lead Owner Update Batch',
        'DataTeam_DeleteTMOSQueueable' => 'Delete Team Members & Splits',
        'DataTeam_AddOppOwnerTeamMemberQueueable' => 'Create Opp Owners - Team Member & Splits',
        'DataTeam_ReturnResultsQueueable' => 'Send Results Email',
        'DataTeam_SYNCOppTeamQueueable' => 'Sync Opp Team Members',
        'DataTeam_SYNCOppSplitsQueueable' => 'Sync Opp Splits',
        'DataTeam_SYNCAddTeamMembersQueueable' => 'Add New Team Members',
        'DataTeam_UpsertDeleteTeamAndSplitsBatch' => 'DML actions on provided records'
      };
    }
    set;
  }
  /*******************************************************************************************************
   * @description query for the current batch job progress
   */
  global List<BatchJob> getBatchJobs() {
    //Create new list of BatchJobs, a wrapper class that includes the job and percent complete.
    batchJobs = new List<BatchJob>();

    //If number of jobs was not defined, default to 20
    if (numberOfJobs == null || numberofJobs <= 0) {
      numberofJobs = 20;
    }

    if (batchComponentLabel == null) {
      batchComponentLabel = 'Apex Jobs';
    }
    /*'DataTeam_UpdateOwnerLeadBatch',
      'DataTeam_UpdateOwnerOppBatch',
      'DataTeam_DeleteTMOSBatch',*/
    Set<String> classNames = new Set<String>{
      'DataTeam_AddOppOwnerTeamMemberQueueable',
      'DataTeam_UpdateOwnerAccountQueueable',
      'DataTeam_UpdateOwnerLeadQueueable',
      'DataTeam_UpdateOwnerOppQueueable',
      'DataTeam_DeleteTMOSQueueable',
      'DataTeam_ReturnResultsQueueable',
      'DataTeam_SYNCOppTeamQueueable',
      'DataTeam_SYNCOppSplitsQueueable',
      'DataTeam_SYNCAddTeamMembersQueueable',
      'DataTeam_UpsertDeleteTeamAndSplitsBatch'
    };

    //Query the Batch apex jobs
    for (AsyncApexJob a : [
      SELECT
        TotalJobItems,
        Status,
        NumberOfErrors,
        MethodName,
        JobType,
        JobItemsProcessed,
        Id,
        CreatedDate,
        CreatedById,
        CreatedBy.Name,
        CompletedDate,
        ApexClassId,
        ApexClass.Name
      FROM AsyncApexJob
      WHERE ApexClass.Name IN :classNames
      ORDER BY CreatedDate DESC
      LIMIT 1
    ]) {
      Double itemsProcessed = a.JobItemsProcessed;
      Double totalItems = a.TotalJobItems;

      BatchJob j = new BatchJob();
      j.job = a;
      //Determine the pecent complete based on the number of batches complete
      if (a.status == 'Completed') {
        j.percentComplete = 100;
        //Determine the pecent complete based on the number of batches complete
      } else if (totalItems == 0) {
        //A little check here as we don't want to divide by 0.
        j.percentComplete = 0;
      } else {
        j.percentComplete = ((itemsProcessed / totalItems) * 100.0).intValue();
      }

      batchJobs.add(j);
    }
    return batchJobs;
  }

  /*******************************************************************************************************
   * @description wrapper class includes the job itself and a value for the percent complete
   */
  global class BatchJob {
    global AsyncApexJob job { get; set; }
    global Integer percentComplete { get; set; }
  }
}