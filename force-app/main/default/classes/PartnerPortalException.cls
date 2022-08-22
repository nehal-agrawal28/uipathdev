public class PartnerPortalException extends Exception
{
	public static void logException(Exception e)
	{
		logException(e, '', '');
	}

	public static void logException(Exception e, String processName)
	{
		logException(e, processName, '');
	}

	public static void logException(Exception e, String processName, String additionalInformation)
	{
		ErrorLogsService_PP logService = ((ErrorLogsService_PP) Application_PP.Service.newInstance(ErrorLogsService_PP.class));
		logService.createErrorLog(e, processName, additionalInformation);
	}
}