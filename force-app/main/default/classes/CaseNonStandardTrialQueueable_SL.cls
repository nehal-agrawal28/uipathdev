public with sharing class CaseNonStandardTrialQueueable_SL extends AbstractQueueable {
  private final List<SObject> cases;
  private static final String GEO_JAPAN = 'Japan';
  public static final String TRIAL_REQUEST_TYPE = 'Non-Standard Trial Request';

  public CaseNonStandardTrialQueueable_SL(List<SObject> cases) {
    super('CaseNonStandardTrialQueueable_SL');
    this.cases = cases;
    //to allow for logging against record. only used in non-bulk contexts
    if (cases != null && cases.size() == 1) {
      this.setPrimaryRecordId(cases.get(0).Id);
    }
  }

  public override void work() {
    this.submitForNonStandardTrialApproval(this.cases);
  }

  private void submitForNonStandardTrialApproval(List<Case> cases) {
    List<Approval.ProcessRequest> approvalRequests = new List<Approval.ProcessRequest>();
    for (Case caseRecord : cases) {
      // Submit case for approval
      Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
      request.setComments('Non-Standard Trial Request Approval');
      request.setObjectId(caseRecord.Id);
      approvalRequests.add(request);
    }
    if (!Test.isRunningTest() && approvalRequests.size() > 0) {
      List<Approval.ProcessResult> results = Approval.process(approvalRequests);
    }
  }

  /**
   * SLTECH-25836 : Auto launch Approval Process on Deal Hub Case for NonStandardTrial Request
   * After insert trigger context
   */
  public static void approvalNonStandardTrial(List<Case> cases) {
    List<Case> eligibleCases = (List<Case>) Collection.of(cases)
      .filter(
        Match.field(Case.Account_Region__c)
          .notEquals(GEO_JAPAN)
          .also(Case.Request_Type__c)
          .equals(TRIAL_REQUEST_TYPE)
          .also(Case.IsClosed)
          .notEquals(null)
          .also(Case.IsClosed)
          .equals(false)
      )
      .asList();

    if (!eligibleCases.isEmpty()) {
      // Case approver validation
      for (Case caseRecord : eligibleCases) {
        if (caseRecord.Case_Approver__c == null) {
          caseRecord.Case_Approver__c.addError(
            'Non-Standard Trial Request approval request requires the next approver to be determined by the Case Approver field.' +
            'This value is empty. Please contact your administrator for more information'
          );
        }
      }

      AbstractQueueable.enqueue(new CaseNonStandardTrialQueueable_SL(eligibleCases));
    }
  }
}