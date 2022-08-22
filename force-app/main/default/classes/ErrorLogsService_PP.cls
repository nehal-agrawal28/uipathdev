public class ErrorLogsService_PP {
  public void createErrorLog(Exception e, String processName, String additionalInformation) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    final String stackTrace = e.getStackTraceString().substringBefore('\n');
    final String className = stackTrace.substringAfter('.').substringBefore('.');
    final String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');

    final ErrorLog__c errorLog = new ErrorLog__c(
      AdditionalInformation__c = additionalInformation,
      ClassName__c = className,
      ExceptionMessage__c = e.getMessage(),
      ExceptionType__c = e.getTypeName(),
      LineNumber__c = e.getLineNumber(),
      MethodName__c = methodName,
      Process__c = processName,
      StackTrace__c = stackTrace
    );

    unitOfWork.registerNew(errorLog);
    unitOfWork.commitWork();
  }
}