/*
Author : Deepali from WarpDrive
Purpose : To have all constants used in support cases.  
*/
public class SupportConstants{

	public final String CASE_RECORD_TYPE_INCIDENT = 'Incident';
    public final String CASE_RECORD_TYPE_SERVICE_REQUEST = 'Service_Request';
    public final String CASE_RECORD_TYPE_SERVICE_INCIDENT = 'Service_Incident';
    public final String CASE_RECORD_TYPE_ENGAGEMENT_REQUEST = 'Engagement_Request';
    public final String CASE_RECORD_TYPE_JS_ENGAGEMENT_REQUEST = 'Japan_Engagement_Request';
    public final String CASE_RECORD_TYPE_ACADEMY = 'Academy';
    public final String CASE_RECORD_TYPE_SALESOPS = 'Sales_Operation';
    public final String CASE_RECORD_TYPE_JS_ACADEMY = 'Japan_Academy';
    public final String CASE_RECORD_TYPE_JS_LICENSING = 'Japan_Licensing';
    public final String CASE_RECORD_TYPE_JS_INCIDENT = 'Japan_Incident';
	public final String CASE_RECORD_TYPE_PROACTIVE = 'Proactive_Care';

	public static Id incidentRtId;
	public static Id serviceRequestRtId;
	public static Id serviceIncidentRtId;
	public static Id engagementRequestRtId;
    public static Id jsEngagementRequestRtId;
	public static Id academyRtId;
	public static Id salesOpsRtId;
	public static Id jsAcademyRtId;
	public static Id jsLicensingRtId;
	public static Id jsIncidentRtId;
	public static Id proactiveRtId;

	static{
		SupportConstants sppcnst = new SupportConstants();

		if(incidentRtId==null){
			incidentRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_INCIDENT);
		}
		if(serviceRequestRtId==null){
			serviceRequestRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_SERVICE_REQUEST);
		}
		if(serviceIncidentRtId==null){
			serviceIncidentRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_SERVICE_INCIDENT);
		}
		if(engagementRequestRtId==null){
			engagementRequestRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_ENGAGEMENT_REQUEST);
		}
		if(academyRtId==null){
			academyRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_ACADEMY);
		}
		if(salesOpsRtId==null){
			salesOpsRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_SALESOPS);
		}
		if(jsAcademyRtId==null){
			jsAcademyRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_JS_ACADEMY);
		}
		if(jsLicensingRtId==null){
			jsLicensingRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_JS_LICENSING);
		}
		if(jsIncidentRtId==null){
			jsIncidentRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_JS_INCIDENT);
		}
        if(jsEngagementRequestRtId==null){
			jsEngagementRequestRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_JS_ENGAGEMENT_REQUEST);
		}
		if(proactiveRtId==null){
			proactiveRtId = SupportUtility.getRecordTypeIdByName('Case', sppcnst.CASE_RECORD_TYPE_PROACTIVE);
		}
	}

}