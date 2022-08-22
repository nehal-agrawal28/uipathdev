public class Ui_PickListController {

    public List<Values> values;
    
    public static List<PickListValueWrapper> picklistValuesByRecordType (String objectName, String fieldName, String recordTypeId) {
        List<PickListValueWrapper> result = new List<PickListValueWrapper> ();
        result.add (new PickListValueWrapper ('--None--', ''));
     /*   for(Web_To_Case_Record_Type__mdt mcs: [select id,label,MasterLabel from Web_To_Case_Record_Type__mdt])
			result.add (new PickListValueWrapper (mcs.label, mcs.label));*/
      
        try {
            Http http = new Http ();
            HttpRequest request = new HttpRequest ();
            //String host = System.Url.getOrgDomainUrl ().toExternalForm ();
          	String url = 'callout:Case_Credential' + '/services/data/v41.0/ui-api/object-info/' + objectName + '/picklist-values/' + recordTypeId + '/' + fieldName;
            request.setEndpoint(url);
            request.setMethod('GET');
            //System.debug('SESSION ID :' + UserInfo.getSessionId());
            //request.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                for (Values values : parse(response.getBody()).values) {
                    result.add (new PickListValueWrapper (values.label, values.value));
                }
            }
            if(response.getStatusCode() == 302){
                request.setEndpoint(response.getHeader('Location'));
                response = new Http().send(request);
                if (response.getStatusCode() == 200) {
                    for (Values values : parse(response.getBody()).values) {
                        result.add (new PickListValueWrapper (values.label, values.value));
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Exception : ' + e);
        }
        System.debug('Result :' + result);
        return result;
    }
    @TestVisible
    private class Values {
        public Object attributes;
        public String label;
        public List<ControllerValues> validFor;
        public String value;
    }
    @TestVisible
    private class ControllerValues {
    }
    public static Ui_PickListController parse(String json) {
        return (Ui_PickListController) System.JSON.deserialize(json, Ui_PickListController.class);
    }
}