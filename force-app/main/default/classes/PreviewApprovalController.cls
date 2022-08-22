public with sharing class PreviewApprovalController {
  private static final String APPROVER_EXCEPTION_MESSAGE = 'Unable to find necessary Approvers for this Quote based on Region and/or other criteria. Please contact your administrator.';

  public Pagereference populateDynamicApprover() {
    String quoteId = ApexPages.currentPage().getParameters().get('Id');

    if (String.isNotBlank(quoteId)) {
      try {
        //populate dynamic approvers
        List<SBQQ__Quote__c> approverQuoteList = DynamicApproverFactory.populateDynamicApprovers(
          new List<Id>{ quoteId }
        );
        System.debug('** approverQuoteList: ' + approverQuoteList);
        update approverQuoteList;

        SBQQ__Quote__c quoteToUpdate = [
          SELECT Id, SBQQ__Opportunity2__r.Owner.ManagerId, SBQQ__Status__c
          FROM SBQQ__Quote__c
          WHERE Id = :quoteId
        ];
        if (quoteToUpdate.SBQQ__Status__c == 'Draft') {
          // Reset approval key fields
          quoteToUpdate.X1st_Level_Approver__c = null; // quote trigger will populate latest value
          quoteToUpdate.Regional_Commercial_Finance_Leader__c = null; // quote trigger will populate latest value
          quoteToUpdate.Sales_Rep_s_Manager__c = quoteToUpdate.SBQQ__Opportunity2__r.Owner.ManagerId;
          update quoteToUpdate;
        }
      } catch (Exception e) {
        System.debug('** Exception:' + e.getMessage() + ' StackTrace:' + e.getStackTraceString());
        ApexPages.Message msg = new ApexPages.Message(
          ApexPages.Severity.Error,
          APPROVER_EXCEPTION_MESSAGE +
          ' ' +
          e.getMessage()
        );
        ApexPages.addMessage(msg);

        return null;
      }
    }

    return new Pagereference('/apex/sbaa__PreviewApprovals?Id=' + quoteId + '&hideSubmit=1');
  }

  public PageReference onCancel() {
    String quoteId = ApexPages.currentPage().getParameters().get('Id');
    return new PageReference('/' + quoteId);
  }

  //custom exception class
  public class SBQQQuoteException extends Exception {
  }
}