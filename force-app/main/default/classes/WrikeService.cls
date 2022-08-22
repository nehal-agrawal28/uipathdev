public class WrikeService {
    @future(callout=true)
    public static void requestAddOpportunityTask(string jsonTask) {
        HttpRequest request = new HttpRequest();
        
        String endpoint = 'callout:Wrike_Service/opportunity'.escapeHtml4();
        
        request.setEndPoint(endpoint);
        request.setMethod('POST');
        
        String jsonBody = jsonTask;
        request.setBody(jsonBody);
        
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = new HTTP().send(request);
    }
    
    @future(callout=true)
    public static void requestAddAccountTask(string jsonTask) {
        HttpRequest request = new HttpRequest();
        
        String endpoint = 'callout:Wrike_Service/account'.escapeHtml4();
        request.setEndPoint(endpoint);
        request.setMethod('POST');
        
        String jsonBody = jsonTask;
        request.setBody(jsonBody);
        
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = new HTTP().send(request);
    }
    
    @future(callout=true)
    public static void requestAddCSMTask(string jsonTask) {
        HttpRequest request = new HttpRequest();
        
        String endpoint = 'callout:Wrike_Service/csm'.escapeHtml4();
        request.setEndPoint(endpoint);
        request.setMethod('POST');
        
        String jsonBody = jsonTask;
        request.setBody(jsonBody);
        
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = new HTTP().send(request);
    }

    @future(callout=true)
    public static void requestAddTeamMember(string json) {
        HttpRequest request = new HttpRequest();

        String endpoint = 'callout:Wrike_Service/teammember'.escapeHtml4();
        request.setEndPoint(endpoint);
        request.setMethod('POST');

        String jsonBody = json;
        request.setBody(jsonBody);

        request.setHeader('Content-Type', 'application/json');

        HttpResponse response = new HTTP().send(request);
    }

    @future(callout=true)
    public static void requestDeleteTeamMember(string json) {
        HttpRequest request = new HttpRequest();

        String endpoint = 'callout:Wrike_Service/teammember'.escapeHtml4();
        request.setEndPoint(endpoint);
        request.setMethod('DELETE');

        String jsonBody = json;
        request.setBody(jsonBody);

        request.setHeader('Content-Type', 'application/json');

        HttpResponse response = new HTTP().send(request);
    }
    
    @future(callout=true)
    public static void requestAddMilestone(string jsonMilestone) {
        HttpRequest request = new HttpRequest();
        
        String endpoint = 'callout:Wrike_Service/milestone'.escapeHtml4();
        request.setEndPoint(endpoint);
        request.setMethod('POST');
        
        String jsonBody = jsonMilestone;
        request.setBody(jsonBody);
        
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = new HTTP().send(request);
    }
}