public with sharing class DataTeam_UpdateOwnerController {
  public List<accountwrapper> allAccounts { get; set; }
  public List<opportunitywrapper> allOpportunities { get; set; }
  public List<leadwrapper> allLeads { get; set; }
  private Map<Id, Id> accountAndNewOwner;
  private Map<Id, Id> opportunityAndNewOwner;
  private Map<Id, Id> leadAndNewOwner;
  public Boolean showData { get; set; }

  public String activeTab { get; set; }
  public Boolean showbatchcomponent { get; set; }

  public List<SelectOption> objectOption { set; }
  public String selectedOption { get; set; }

  public List<SelectOption> getObjectOption() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('', ' -- SELECT CSV FORMAT -- '));
    options.add(new SelectOption('AccountUserAll', 'ACCOUNT ID LONG, USER ID LONG (UPDATE ALL)'));
    options.add(new SelectOption('AccountUser', 'ACCOUNT ID LONG - USER ID LONG (UPDATE ONLY ACCOUNTS)'));
    options.add(new SelectOption('OpportunityUser', 'OPPORTUNITY ID LONG - USER ID LONG (UPDATE ONLY OPPORTUNITIES)'));
    options.add(new SelectOption('LeadUser', 'LEAD ID LONG - USER ID LONG (UPDATE ONLY LEADS)'));

    return options;
  }

  public void showData() {
    showData = true;
  }
  public DataTeam_UpdateOwnerController() {
    selectedOption = '';
  }

  public Blob csvFileBody { get; set; }
  public string csvAsString { get; set; }
  public Map<String, String> dataMap;

  public void readCSVData() {
    allAccounts = new List<accountwrapper>();
    allOpportunities = new List<opportunitywrapper>();
    allLeads = new List<leadwrapper>();
    showbatchcomponent = false;
    try {
      csvAsString = csvFileBody.toString();

      String[] csvFileLines = csvAsString.split('\r\n');
      dataMap = new Map<String, String>();
      for (Integer i = 1; i < csvFileLines.size(); i++) {
        string[] csvOppData = csvFileLines[i].split(',');
        String mainObjectNameOrID = '';
        String userObjectNameOrID = '';
        if (!String.isEmpty(csvOppData[0]) && !String.isEmpty(csvOppData[1])) {
          if (!dataMap.containsKey(csvOppData[0].trim()))
            dataMap.put(csvOppData[0].trim(), csvOppData[1].trim());
        }
      }
      Map<String, User> allNewOwners = getUsers(dataMap.values());
      if (selectedOption == 'AccountUserAll') {
        allAccounts = populateAccountWrappers(dataMap, allNewOwners);
        allOpportunities = populateOpportunityWrappers(dataMap, allNewOwners, selectedOption);
        allLeads = populateLeadWrappers(dataMap, allNewOwners, selectedOption);
        if (allOpportunities.size() > 0 || allLeads.size() > 0)
          showbatchcomponent = true;
        activeTab = '0';
      }
      if (selectedOption == 'AccountUser') {
        allAccounts = populateAccountWrappers(dataMap, allNewOwners);
        if (allAccounts.size() > 0)
          showbatchcomponent = true;
        activeTab = '0';
      }
      if (selectedOption == 'OpportunityUser') {
        allOpportunities = populateOpportunityWrappers(dataMap, allNewOwners, selectedOption);
        if (allOpportunities.size() > 0)
          showbatchcomponent = true;
        activeTab = '1';
      }
      if (selectedOption == 'LeadUser') {
        allLeads = populateLeadWrappers(dataMap, allNewOwners, selectedOption);
        if (allLeads.size() > 0)
          showbatchcomponent = true;
        activeTab = '2';
      }
    } catch (Exception e) {
      ApexPages.Message errorMessage = new ApexPages.Message(
        ApexPages.severity.ERROR,
        e.getMessage() + ' Please make sure input csv file is correct'
      );
      ApexPages.addMessage(errorMessage);
    }
  }

  private List<accountwrapper> populateAccountWrappers(Map<String, String> recordMap, Map<String, User> newOwners) {
    List<accountwrapper> awrapper = new List<accountwrapper>();
    List<Account> accts = getAccounts(recordMap.keySet());
    accountAndNewOwner = new Map<Id, Id>();
    for (Account a : accts) {
      List<User> u = getUserByID(recordMap, newOwners, a.Id);
      awrapper.add(new accountwrapper(a, u[0]));
      accountAndNewOwner.put(a.Id, u[0].Id);
    }

    return awrapper;
  }

  private List<opportunitywrapper> populateOpportunityWrappers(
    Map<String, String> recordMap,
    Map<String, User> newOwners,
    String selOption
  ) {
    List<opportunitywrapper> owrapper = new List<opportunitywrapper>();
    List<Opportunity> opps = new List<Opportunity>();
    if (selOption == 'AccountUserAll')
      opps = getOpportunitiesByAccountID(recordMap.keySet());
    else
      opps = getOpportunitiesByID(recordMap.keySet());
    opportunityAndNewOwner = new Map<Id, Id>();
    Map<Id, List<Opportunity_Split__c>> osMap = new Map<Id, List<Opportunity_Split__c>>();
    for (Opportunity_Split__c os : [
      SELECT Id, User__c, User__r.Name, Opportunity__c, Percentage__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c IN :opps AND Role__c = 'Opportunity Owner'
      ORDER BY User__r.Name
    ]) {
      if (!osMap.containsKey(os.Opportunity__c)) {
        List<Opportunity_Split__c> osList = new List<Opportunity_Split__c>();
        osList.add(os);
        osMap.put(os.Opportunity__c, osList);
      } else {
        List<Opportunity_Split__c> osList = osMap.get(os.Opportunity__c);
        osList.add(os);
        osMap.put(os.Opportunity__c, osList);
      }
    }
    for (Opportunity o : opps) {
      String rId = selOption == 'AccountUserAll' ? o.AccountId : o.Id;
      List<User> u = getUserByID(recordMap, newOwners, rId);
      owrapper.add(new opportunitywrapper(o, o.OpportunityTeamMembers, osMap.get(o.Id), u[0]));
      opportunityAndNewOwner.put(o.Id, u[0].Id);
    }
    return owrapper;
  }

  private List<leadwrapper> populateLeadWrappers(
    Map<String, String> recordMap,
    Map<String, User> newOwners,
    String selOption
  ) {
    List<leadwrapper> lwrapper = new List<leadwrapper>();
    List<Lead> lds = new List<Lead>();
    if (selOption == 'AccountUserAll')
      lds = getLeadsByAccountId(recordMap.keySet());
    else
      lds = getLeadsById(recordMap.keySet());
    leadAndNewOwner = new Map<Id, Id>();
    for (Lead l : lds) {
      String rId = selOption == 'AccountUserAll' ? l.Account__c : l.Id;
      List<User> u = getUserByID(recordMap, newOwners, rId);
      lwrapper.add(new leadwrapper(l, u[0]));
      leadAndNewOwner.put(l.Id, u[0].Id);
    }
    return lwrapper;
  }

  // get accounts by id
  private List<Account> getAccounts(Set<String> accString) {
    return [SELECT Id, Name, OwnerId, Owner.Name FROM Account WHERE Id IN :accString OR Name IN :accString];
  }

  // get opportunities by account id
  private List<Opportunity> getOpportunitiesByAccountID(Set<String> accString) {
    return [
      SELECT
        Id,
        Name,
        AccountId,
        Account.Name,
        OwnerId,
        Owner.Name,
        (
          SELECT Id, TeamMemberRole, User.Id, User.Name
          FROM OpportunityTeamMembers
          WHERE TeamMemberRole = 'Opportunity Owner'
          ORDER BY User.Name
        )
      FROM Opportunity
      WHERE (AccountId IN :accString OR Account.Name IN :accString) AND IsClosed = FALSE
    ];
  }

  // get opportunities by id
  private List<Opportunity> getOpportunitiesByID(Set<String> oppIds) {
    return [
      SELECT
        Id,
        Name,
        AccountId,
        Account.Name,
        OwnerId,
        Owner.Name,
        (
          SELECT Id, TeamMemberRole, User.Id, User.Name
          FROM OpportunityTeamMembers
          WHERE TeamMemberRole = 'Opportunity Owner'
          ORDER BY User.Name
        )
      FROM Opportunity
      WHERE ID IN :oppIds AND IsClosed = FALSE
    ];
  }

  // get leads by account id
  private List<Lead> getLeadsByAccountId(Set<String> accString) {
    return [
      SELECT Id, Name, Account__c, Account__r.Name, OwnerId, Owner.Name
      FROM Lead
      WHERE Account__c IN :accString AND (Status = 'New' OR Status = 'Working') AND Account__r.EDR__c = NULL
    ];
  }

  // get leads by id
  private List<Lead> getLeadsById(Set<String> leadIds) {
    return [
      SELECT Id, Name, Account__c, Account__r.Name, OwnerId, Owner.Name
      FROM Lead
      WHERE Id IN :leadIds AND (Status = 'New' OR Status = 'Working') AND Account__r.EDR__c = NULL
    ];
  }

  public void updateOwner() {
    System.enqueueJob(new DataTeam_UpdateOwnerAccountQueueable(accountAndNewOwner, opportunityAndNewOwner, leadAndNewOwner, true, true));
  }

  public void updateAccountOwner() {
    System.enqueueJob(new DataTeam_UpdateOwnerAccountQueueable(accountAndNewOwner, null, null, false, false));
  }

  public void updateOpportunityOwner() {
    if (opportunityAndNewOwner.size() > 0) {
      System.enqueueJob(new DataTeam_DeleteTMOSQueueable(accountAndNewOwner, opportunityAndNewOwner, leadAndNewOwner, false, false));
    }

    if(Test.isrunningTest()) {
      System.enqueueJob(new DataTeam_UpdateOwnerOppQueueable(opportunityAndNewOwner, leadAndNewOwner, false));
      System.enqueueJob(new DataTeam_AddOppOwnerTeamMemberQueueable(opportunityAndNewOwner, leadAndNewOwner, false));
      System.enqueueJob(new DataTeam_ReturnResultsQueueable(accountAndNewOwner, opportunityAndNewOwner, leadAndNewOwner));
    }
  }

  public void updateLeadOwner() {
    System.enqueueJob(new DataTeam_UpdateOwnerLeadQueueable(null, leadAndNewOwner));
  }

  private Map<String, User> getUsers(List<String> userString) {
    Map<String, User> usersMap = new Map<String, User>();
    List<User> allUsers = [SELECT Id, Name FROM User WHERE Id IN :userString OR Name IN :userString];
    for (User u : allUsers) {
      usersMap.put(u.Id, u);
      usersMap.put(u.Name, u);
    }
    return usersMap;
  }

  private List<User> getUserByID(Map<String, String> recordMap, Map<String, User> newOwners, String rId) {
    List<User> u = new List<User>();
    if (recordMap.containsKey(rId)) {
      u.add(newOwners.get(recordMap.get(rId)));
    }
    return u;
  }

  public void Cancel() {
    selectedOption = '';
    allAccounts = null;
    allOpportunities = null;
    allLeads = null;
    showbatchcomponent = false;
  }

  public class accountwrapper {
    public Account acc { get; set; }
    public User newOwner { get; set; }
    public accountwrapper(Account currentAcc, User newOwner) {
      this.acc = currentAcc;
      this.newOwner = newOwner;
    }
  }

  public class opportunitywrapper {
    public Opportunity opp { get; set; }
    public List<OpportunityTeamMember> otm { get; set; }
    public List<Opportunity_Split__c> os { get; set; }
    public User newOwner { get; set; }
    public opportunitywrapper(
      Opportunity currentOpp,
      List<OpportunityTeamMember> relatedOTM,
      List<Opportunity_Split__c> relatedOS,
      User newOwner
    ) {
      this.opp = currentOpp;
      this.otm = relatedOTM;
      this.os = relatedOS;
      this.newOwner = newOwner;
    }
  }

  public class leadwrapper {
    public Lead lead { get; set; }
    public User newOwner { get; set; }
    public leadwrapper(Lead currentLead, User newOwner) {
      this.lead = currentLead;
      this.newOwner = newOwner;
    }
  }
}