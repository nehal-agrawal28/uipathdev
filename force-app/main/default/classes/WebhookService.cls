public class WebhookService {
    @future(callout=true)
    public static void requestAddOpportunityTask(string jsonTask) {
        HttpRequest request = new HttpRequest();
        
        String endpoint = 'https://app.hookeepr.com/webhook/qKTZwVNocCIDK68U';
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
        
        String endpoint = 'https://app.hookeepr.com/webhook/qKTZwVNocCIDK68U';
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
        
        String endpoint = 'https://app.hookeepr.com/webhook/qKTZwVNocCIDK68U';
        request.setEndPoint(endpoint);
        request.setMethod('POST');
        
        String jsonBody = jsonTask;
        request.setBody(jsonBody);
        
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = new HTTP().send(request);
    }
}