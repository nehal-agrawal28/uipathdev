global with sharing class CPQCreateCancellationQuoteSerial_SL extends AbstractQueueable implements Database.AllowsCallouts {
  CPQServiceRouter_SL productManager { get; set; }
  String contractId { get; set; }
  Date startDate { get; set; }
  String quoteId { get; set; }
  List<String> queueContracts { get; set; }
  global List<String> retryJob {
    get {
      if (retryJob == null) {
        retryJob = new List<String>();
      }
      return retryJob;
    }
    set;
  }

  final static IQuoteService_SL quotesService = (IQuoteService_SL) Application_SL.Service.newInstance(
    IQuoteService_SL.class
  );

  public CPQCreateCancellationQuoteSerial_SL(
    String contractId,
    String startDate,
    String quoteId,
    List<String> queueContracts
  ) {
    super('CPQCreateCancellationQuoteSerial_SL');
    this.contractId = contractId;
    this.startDate = Date.valueOf(startDate);
    this.quoteId = quoteId;
    this.queueContracts = queueContracts;
    //to allow for logging against record. only used in non-bulk contexts
    if (contractId != null) {
      this.setPrimaryRecordId(contractId);
    }
    //Override finalizer
    this.baseFinalizer = new CPQCreateCancellationQuoteFinalizer_SL(
      this.contractId,
      this.startDate,
      this.quoteId,
      this.queueContracts,
      this.retryJob
    );
  }

  // Required to be global so Quote Calculator can call back to this class and save the newly amended quote
  global CPQCreateCancellationQuoteSerial_SL() {
    super('CPQCreateCancellationQuoteSerial_SL');
  }

  public override void work() {
    execute(ctx.getJobId());
  }

  public void execute(String jobId) {
    try {
      // Logger.info('Amending Contract ' + contractId, quoteId);
      productManager = new CPQServiceRouter_SL();
      CPQModel_Quote_SL model = productManager.loadContract(contractId);
      CPQQuoteCalculator_SL calculator = new CPQQuoteCalculator_SL();
      model = calculator.read(model.record.Id);
      model.record.Replacement_Quote__c = quoteId;
      model.record.SBQQ__StartDate__c = startDate;

      //TODO Remove this hack when merging into soup because there is pricebook defaulting logic there
      Id defaultPBId;

      //Identify execution context
      Organization org = [SELECT IsSandbox, TrialExpirationDate FROM Organization];
      Boolean isScratchOrg = org.IsSandbox && org.TrialExpirationDate != null;

      //scratch org, non-test context - set default PB
      if (isScratchOrg && !Test.isRunningTest()) {
        defaultPBId = OpportunitiesService_SL.oppDefaultPricebookId;
      }
      //test context - set std PB
      if (Test.isRunningTest()) {
        defaultPBId = Test.getStandardPricebookId();
      }
      //update model if pbId is needed
      if (defaultPBId != null) {
        model.record.SBQQ__PricebookId__c = defaultPBId;
        model.record.SBQQ__PriceBook__c = defaultPBId;
      }
      //

      System.debug(LoggingLevel.INFO, 'CPQCreateCancellationQuoteSerial_SL:execute');

      for (CPQModel_QuoteLine_SL line : model.lineItems) {
        System.debug(
          LoggingLevel.INFO,
          'CPQCreateCancellationQuoteSerial_SL:model.lineItems.line.SBQQ__PricebookEntryId__c: ' +
          line.record.SBQQ__PricebookEntryId__c
        );
        line.record.SBQQ__Quantity__c = 0;
      }

      calculator.calculate(model, 'QuoteService_SL');
    } catch (Exception e) {
      Logger.error('Cancellation quote job failed for contract ' + contractId, quoteId, e);
      Logger.saveLog();
      throw new CPQCreateCancellationException(e.getMessage() + e.getStackTraceString());
    }
  }

  public class TaskInputWrapper {
    public String contractId { get; set; }
    public String startDate { get; set; }
    public String quoteId { get; set; }
    public TaskInputWrapper(String contractId, String startDate, String quoteId) {
      this.contractId = contractId;
      this.startDate = startDate;
      this.quoteId = quoteId;
    }
  }

  public class CPQCreateCancellationException extends Exception {
  }
}