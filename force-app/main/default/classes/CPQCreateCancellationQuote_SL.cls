global with sharing class CPQCreateCancellationQuote_SL extends AbstractQueueable implements Database.AllowsCallouts {
  CPQServiceRouter_SL productManager { get; set; }
  String contractId { get; set; }
  Date startDate { get; set; }
  String quoteId { get; set; }
  // Used to kick off another queueable to see if all of the amended contracts are done then creates
  // queue line items based off the amended contracts
  Boolean calculateQuoteLines { get; set; }
  Set<String> jobIds { get; set; }
  final static IQuoteService_SL quotesService = (IQuoteService_SL) Application_SL.Service.newInstance(
    IQuoteService_SL.class
  );

  public CPQCreateCancellationQuote_SL(String contractId, String startDate, String quoteId) {
    this(contractId, startDate, quoteId, false, new Set<String>());
  }
  public CPQCreateCancellationQuote_SL(
    String contractId,
    String startDate,
    String quoteId,
    Boolean calculateQuoteLines,
    Set<String> jobIds
  ) {
    super('CPQCreateCancellationQuote_SL');
    this.contractId = contractId;
    this.startDate = Date.valueOf(startDate);
    this.quoteId = quoteId;
    this.calculateQuoteLines = calculateQuoteLines;
    this.jobIds = jobIds;
    //to allow for logging against record. only used in non-bulk contexts
    if (contractId != null) {
      this.setPrimaryRecordId(contractId);
    }
  }

  // Required to be global so Quote Calculator can call back to this class and save the newly amended quote
  global CPQCreateCancellationQuote_SL() {
    super('CPQCreateCancellationQuote_SL');
  }

  public override void work() {
    // Adding this job id to the jobIds list, this is for when we call the QuoteLineQueueable
    // so we can check the status of all of the jobs before we process quote lines
    jobIds.add(ctx.getJobId());
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

      System.debug(LoggingLevel.INFO, 'CPQCreateCancellationQuote_SL:execute');

      for (CPQModel_QuoteLine_SL line : model.lineItems) {
        System.debug(
          LoggingLevel.INFO,
          'CPQCreateCancellationQuote_SL:model.lineItems.line.SBQQ__PricebookEntryId__c: ' +
          line.record.SBQQ__PricebookEntryId__c
        );
        line.record.SBQQ__Quantity__c = 0;
      }

      calculator.calculate(model, 'QuoteService_SL');

      createEvent(jobId, quoteId, contractId, null);

      if (calculateQuoteLines) {
        CPQConsolidateReplacementLines_SL quoteLineQueueable = new CPQConsolidateReplacementLines_SL(
          jobIds,
          quoteId,
          Logger.getTransactionId()
        );
        // Test classes cannot chain queueables, we are just going to directly execute it
        if (Test.isRunningTest()) {
          quoteLineQueueable.execute();
        } else {
          // Logger.info('Enqueuing Job for Consolidating all Cancelled Quote Lines into the replacement Quote ', quoteId);
          AbstractQueueable.enqueue(quoteLineQueueable);
        }
      }
    } catch (Exception e) {
      createEvent(jobId, quoteId, contractId, e.getMessage());
      Logger.error('Failed Creating Cancellation Quote for Contract ' + contractId, quoteId, e);
      Logger.saveLog();
      throw new CPQCreateCancellationException(e.getMessage());
    }
  }

  // Creates an event with the jobId and the amended quote for the lwc can listen for when the job is done
  private void createEvent(String jobId, String quoteId, String contractId, String error) {
    ContractModEvent__e ripReplaceEvent = new ContractModEvent__e();
    ripReplaceEvent.JobId__c = jobId;
    ripReplaceEvent.QuoteId__c = quoteId;
    ripReplaceEvent.ContractId__c = contractId;
    ripReplaceEvent.Error__c = error;
    // Call method to publish events
    Database.SaveResult sr = EventBus.publish(ripReplaceEvent);
    // Inspect publishing result
    if (sr.isSuccess()) {
      // Logger.debug('Successfully published ContractModEvent for contract ' + contractId, quoteId);
    } else {
      for (Database.Error err : sr.getErrors()) {
        // Logger.error('Failed Publishing ContractModEvent for contract ' + contractId, quoteId);
      }
    }
  }

  public class CPQCreateCancellationException extends Exception {
  }
}