public class RequestWrapperChina{
	
    public RequestWrapperChina(){
        isAcademyCase = false;
        isfreemailer = false;
    }
	public String name;
	public String email;
	public String accountname;
	public String phone;
	public String subject;
	public String description;
    public String errormessage;
	public String licensecode;
	public String country;
	public String timzone;
	public String productcomponent;
	public String priority;
	public String environment;
    public String deviceId;
	public String studioversion;
	public String orchestratorversion;
	public String numofrobotsimpacted;
	public Boolean webformack;
	public String sourceLink;
	public String accountId;
	public String subscriptiontype;
    public Boolean isacademycase;
	public String productcomponentversion;
    public String joblevel;
    public String reqrelatedto;
    public String reqsubcategory;
    public Boolean isfreemailer;
    
	public List<Attachments> attachments;

	public class Attachments {
		public String bodyInbase64encoded; 
		public String contentType;
		public String name;
		public String pathonclient;
	}

	
	public static RequestWrapperChina parse(String json) {
		return (RequestWrapperChina) System.JSON.deserialize(json, RequestWrapperChina.class);
	}
}