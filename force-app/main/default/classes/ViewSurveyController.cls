/* Controller associated with pages rendering the survey.
 * Used by SurveyPage, ResultsPage, TakeSurvey //
 */
global virtual without sharing class ViewSurveyController {
  public String qQuestion { get; set; }
  public Boolean qRequired { get; set; }
  public String qChoices { get; set; }
  public String surveyName { get; set; }
  public String surveyHeader { get; set; }
  public String surveyId {
    get;
    set {
      this.surveyId = value;
      init();
    }
  }
  public String renderSurveyPreview { get; set; }
  public Boolean surveyAlreadyTaken { get; set; }
  public String questionName { get; set; }
  public String questionType { get; set; }
  public Boolean questionRequired { get; set; }
  public List<SelectOption> singleOptions { get; set; }
  public List<SFQuestion> allQuestions { get; set; }
  public List<String> responses { get; set; }
  public Integer allQuestionsSize { get; set; }
  public String templateURL { get; set; }
  public String surveyThankYouText { get; set; }
  public String surveyContainerCss { get; set; }
  public String surveyThankYouURL { get; set; }
  public String caseId { get; set; }
  public String contactId { get; set; }
  public String anonymousAnswer { get; set; }
  public List<SelectOption> anonymousOrUser { get; set; }
  public Boolean isInternal { get; set; }
  public String baseURL { get; set; }

  public String userId { get; set; }
  public String userName { get; set; }
  public String surveyTakerId { get; set; }
  public Boolean thankYouRendered { get; set; }
  public List<String> newOrder { get; set; }

  public String surveyError { get; set; }
  public Boolean surveyErrorRendered { get; set; }
  public OrgWideEmailAddress orgWideAddObj;
  public EmailTemplate templateId;
  public String ORG_WIDE_ADDRESS = Label.UIPathOrgWideAddress;
  public String EMAIL_TEMPLATE_NAME = 'Survey_Error_Notification';
  public boolean surveySubmittedRendered { get; set; }
  /* Retrieves the list of questions, the survey name, after retrieving the 
necessary parameters from the url.
*/
  //------------------------------------------------------------------------------//
  public ViewSurveyController(ApexPages.StandardController stdController) {
    // Get url parameters
    surveyId = Apexpages.currentPage().getParameters().get('id');
    caseId = Apexpages.currentPage().getParameters().get('caId');
    contactId = Apexpages.currentPage().getParameters().get('cId');

    surveyError = System.Label.SurveyErrorMessage;
    if (caseId == null || caseId.length() < 15) {
      caseId = 'none';
    }
    if (contactId == null || contactId.length() < 15) {
      contactId = 'none';
    }
    // By default the preview is not showing up
    renderSurveyPreview = 'false';
    surveyAlreadyTaken = false;

    init();
  }

  public ViewSurveyController(viewShareSurveyComponentController controller) {
    surveyId = Apexpages.currentPage().getParameters().get('id').escapeHtml4();
    caseId = Apexpages.currentPage().getParameters().get('caId').escapeHtml4();
    contactId = Apexpages.currentPage().getParameters().get('cId').escapeHtml4();
    if (caseId == null || caseId.length() < 15) {
      caseId = 'none';
    }
    if (contactId == null || contactId.length() < 15) {
      contactId = 'none';
    }
    // By default the preview is not showing up
    renderSurveyPreview = 'false';
    init();
  }

  public void init() {
    if (surveyId != null) {
      // Retrieve all necessary information to be displayed on the page
      allQuestions = new List<SFQuestion>();
      setupQuestionList();
      setSurveyNameAndThankYou(surveyId);
      anonymousOrUser = new List<SelectOption>();
      anonymousOrUser.add(new SelectOption('Anonymous', System.Label.LABS_SF_Anonymous));
      anonymousOrUser.add(new SelectOption('User', 'User ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName()));
      anonymousAnswer = 'Anonymous';
      isInternal = true;
      newOrder = new List<String>();
      String urlBase = URL.getSalesforceBaseUrl().toExternalForm();
      baseURL = urlBase;

      userId = UserInfo.getUserId();
      userName = UserInfo.getName();

      String profileId = UserInfo.getProfileId();
      try {
        //sp = Database.setSavepoint();
        Profile p = [SELECT Id, UserType FROM Profile WHERE Id = :profileId];
        if (p.UserType == 'Guest') {
          isInternal = false;
        } else {
          isInternal = true;
        }
      } catch (Exception e) {
        surveyErrorRendered = true;
        isInternal = false;
      }

      thankYouRendered = false;

      List<SurveyTaker__c> surveysTaken = [SELECT id FROM SurveyTaker__c WHERE case__c = :caseId];
      if (surveysTaken.isempty()) {
        surveyAlreadyTaken = false;
        thankYouRendered = false;
      } else {
        surveyAlreadyTaken = true;
        thankYouRendered = true;
      }
    }
  }

  //----------------------------------------------------------------------------//

  /* Called during the setup of the page.
   Retrieve questions and responses from DB and inserts them in 2 lists. */
  public Integer setupQuestionList() {
    getAQuestion();
    return allQuestions.size();
  }

  /** Sets the survey's name variable
   *  param: sID   The survey ID as specified in the DB
   */
  public void setSurveyNameAndThankYou(String sId) {
    System.debug('*****sId' + sId);
    Survey__c s = [
      SELECT
        Name,
        Id,
        URL__c,
        Thank_You_Text__c,
        thankYouText__c,
        thankYouLink__c,
        Survey_Header__c,
        Survey_Container_CSS__c
      FROM Survey__c
      WHERE Id = :sId
    ];
    surveyName = s.Name;
    surveyHeader = s.Survey_Header__c;
    templateURL = s.URL__c + 'id=' + sId; //+'&cId={!Contact.Id}'+'&caId='+'{!Case.id}';
    surveyThankYouText = s.Thank_You_Text__c;
    if (surveyThankYouText == null) {
      surveyThankYouText = System.Label.LABS_SF_Survey_Submitted_Thank_you;
    }
    surveyThankYouURL = s.thankYouLink__c;
    surveyContainerCss = s.Survey_Container_CSS__c;
  }

  //------------------------------------------------------------------------------//
  public Pagereference updateSurveyName() {
    Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id = :surveyId];
    s.Name = surveyName;
    try {
      update s;
    } catch (Exception e) {
      surveyErrorRendered = true;
      //Apexpages.addMessages(e);
    }
    return null;
  }

  //------------------------------------------------------------------------------//
  public Pagereference updateSurveyThankYouAndLink() {
    Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id = :surveyId];
    s.thankYouText__c = surveyThankYouText;
    s.thankYouLink__c = surveyThankYouURL;
    try {
      update s;
    } catch (Exception e) {
      surveyErrorRendered = true;
      Apexpages.addMessages(e);
    }
    return null;
  }

  //------------------------------------------------------------------------------//
  /** When requested from the page - when the user clicks on 'Update Order' -
this function will reorganize the list so that it is displayed in the new order
*/
  public Pagereference refreshQuestionList() {
    setupQuestionList();
    return null;
  }

  //------------------------------------------------------------------------------//

  //------------------------------------------------------------------------------//
  private static boolean checkRequired(String response, Survey_Question__c question) {
    if (question.Required__c == true) {
      if (response == null || response == 'NO RESPONSE')
        return false;
    }
    return true;
  }

  /** Redirects the page that displays the detailed results of the survey, 
from all users who took the survey.
*/
  public PageReference resultPage() {
    return new PageReference('/apex/ResultsPage?id=' + surveyId);
  }

  //------------------------------------------------------------------------------//

  //------------------------------------------------------------------------------//

  /**
   */
  public List<String> getResponses() {
    List<SurveyQuestionResponse__c> qr = [
      SELECT Survey_Question__c, SurveyTaker__c, Response__c, Name
      FROM SurveyQuestionResponse__c
      LIMIT 100
    ];
    List<String> resp = new List<String>();
    for (SurveyQuestionResponse__c r : qr) {
      resp.add(r.Response__c);
    }

    return resp;
  }

  /** Fills up the List of questions to be displayed on the Visualforce page
   */
  public List<SFQuestion> getAQuestion() {
    qQuestion = '';
    qChoices = '';

    List<Survey_Question__c> allQuestionsObject = [
      SELECT s.Type__c, s.Id, s.Survey__c, s.Required__c, s.Question__c, s.OrderNumber__c, s.Name, s.Choices__c
      FROM Survey_Question__c s
      WHERE s.Survey__c = :surveyId
      ORDER BY s.OrderNumber__c
    ];

    allQuestions = new List<SFQuestion>();

    Double old_OrderNumber = 0;
    Double new_OrderNumber;
    Double difference = 0;
    /* Make sure that the order number follow each other (after deleting a question, orders might not do so) */
    for (Survey_Question__c q : allQuestionsObject) {
      new_OrderNumber = q.OrderNumber__c;
      difference = new_OrderNumber - old_OrderNumber - 1;
      if (difference > 0) {
        Double dd = double.valueOf(difference);
        Integer newOrderInt = dd.intValue();
        q.OrderNumber__c -= Integer.valueOf(newOrderInt);
      }
      old_OrderNumber = q.OrderNumber__c;
      SFQuestion theQ = new SFQuestion(q);
      allQuestions.add(theQ);
    }
    allQuestionsSize = allQuestions.size();
    return allQuestions;
  }

  public void submitResults() {
    //showSpinner = true;
    //disableButton = true;
    SavePoint sp;
    try {
      sp = Database.setSavepoint();
      List<SurveyQuestionResponse__c> sqrList = new List<SurveyQuestionResponse__c>();
      for (SFQuestion q : allQuestions) {
        SurveyQuestionResponse__c sqr = new SurveyQuestionResponse__c();
        if (q.renderSelectRadio == 'true') {
          if (q.required && (q.selectedOption == null || q.selectedOption == '')) {
            Apexpages.addMessage(
              new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields')
            );
            return;
          }

          if (q.selectedOption == null || q.selectedOption == '') {
            sqr.Response__c = '';
          } else {
            sqr.Response__c = q.singleOptions.get(Integer.valueOf(q.selectedOption)).getLabel();
          }
          sqr.Survey_Question__c = q.Id;
          sqrList.add(sqr);
        } else if (q.renderFreeText == 'true') {
          if (q.required && q.choices == '') {
            Apexpages.addMessage(
              new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields')
            );
            return;
          }

          sqr.Response__c = q.choices;
          sqr.Survey_Question__c = q.Id;
          sqrList.add(sqr);
        } else if (q.renderSelectCheckboxes == 'true') {
          if (q.required && (q.selectedOptions == null || q.selectedOptions.size() == 0)) {
            Apexpages.addMessage(
              new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields')
            );
            return;
          }

          for (String opt : q.selectedOptions) {
            sqr = new SurveyQuestionResponse__c();
            if (opt == '' || opt == null) {
              sqr.Response__c = '';
            } else {
              sqr.Response__c = q.multiOptions.get(Integer.valueOf(opt)).getLabel();
            }
            sqr.Survey_Question__c = q.Id;
            sqrList.add(sqr);
          }
        } else if (q.renderSelectRow == 'true') {
          if (q.required && (q.selectedOption == null || q.selectedOption == '')) {
            Apexpages.addMessage(
              new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields')
            );
            return;
          }

          if (q.selectedOption == null || q.selectedOption == '') {
            sqr.Response__c = '';
          } else {
            sqr.Response__c = q.rowOptions.get(Integer.valueOf(q.selectedOption)).getLabel();
          }
          sqr.Survey_Question__c = q.Id;
          sqrList.add(sqr);
        }
      }
      if (AddSurveyTaker()) {
        for (SurveyQuestionResponse__c sqr : sqrList) {
          sqr.SurveyTaker__c = surveyTakerId;
        }
        insert sqrList;
        thankYouRendered = true;
        String surveySrc = ApexPages.currentPage().getParameters().get('src');
        if (surveySrc != null && surveySrc == 'CaseView') {
          surveySubmittedRendered = true;
        }
        System.debug('ApexPages.currentPage()' + ApexPages.currentPage());
      }
    } catch (Exception e) {
      Database.rollback(sp);
      /*String surveySrc = ApexPages.currentPage().getParameters().get('src');
if(surveySrc != null && surveySrc == 'CaseView'){
submitFailed = true;
}*/
      surveyErrorRendered = true;
      sendErrorEmail(e.getMessage());
      /*if(isInternal) {
Apexpages.addMessages(e);
}else{
Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()+ 'Some error occured while saving response'));
}*/
    }
  }

  private Boolean AddSurveyTaker() {
    String userId;

    if (surveyId == null) {
      return false;
    }
    if (caseId.toUpperCase() == 'NONE' || caseId.length() < 5)
      caseId = null;
    if (contactId.toUpperCase() == 'NONE' || contactId.length() < 5)
      contactId = null;
    if (anonymousAnswer != 'Anonymous') {
      userId = UserInfo.getUserId();
    } else {
      userId = null;
    }

    if (/*anonymousAnswer != 'Anonymous' && */ (contactId != null || caseId != null)) {
      List<SurveyTaker__c> check = [
        SELECT Contact__c, Survey__c, Case__c, User__c
        FROM SurveyTaker__c
        WHERE Contact__c = :contactId AND Survey__c = :surveyId AND Case__c = :caseId AND User__c = :UserId
      ];
      if (check != null && check.size() > 0) {
        Apexpages.addMessage(
          new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.LABS_SF_You_have_already_taken_this_survey)
        );

        return false;
      }
    }
    Case caseRec;
    if (caseId != null) {
      caseRec = [SELECT Id, Subject, ParentId, RecordType.Name FROM Case WHERE id = :caseId];
      if (caseRec != null && caseRec.Subject.startsWithIgnoreCase('DSAT FollowUp')) {
        Case caseParentRec = [SELECT Id, Subject, ParentId, RecordType.Name FROM Case WHERE id = :caseRec.ParentId];
        if (
          caseParentRec != null &&
          (caseParentRec.RecordType.Name == 'Cloud Elements' ||
          caseParentRec.RecordType.Name == 'Incident' ||
          caseParentRec.RecordType.Name == 'Proactive Care' ||
          caseParentRec.RecordType.Name == 'Service Request')
        ) {
          caseParentRec.CSAT__c = null;
          update caseParentRec;
        }
      }
    }
    SurveyTaker__c st = new SurveyTaker__c();
    st.Contact__c = contactId;
    st.Survey__c = surveyId;
    st.Taken__c = 'true';
    st.Case__c = caseId;
    st.User__c = userId;
    insert st;
    surveyTakerId = st.Id;
    return true;
  }

  public void sendErrorEmail(String errorMessage) {
    orgWideAddObj = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :ORG_WIDE_ADDRESS];
    templateId = [SELECT Id, Subject, Htmlvalue FROM EmailTemplate WHERE DeveloperName = :EMAIL_TEMPLATE_NAME];
    Case c = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseId];
    List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
    String subject = templateId.Subject.replace('{!Case.CaseNumber}', c.CaseNumber);
    mailObj.setSubject(subject);
    String htmlBody = templateId.HtmlValue.replace('{!errorMessage}', errorMessage);
    htmlBody = htmlBody.replace('{!Case.CaseNumber}', c.CaseNumber);
    mailObj.setHtmlBody(htmlBody);
    mailObj.setSaveAsActivity(false);
    mailObj.setWhatId(caseId);

    mailObj.setToAddresses(System.Label.SurveyErrorEmailRecepients.split(','));
    mailObj.setOrgWideEmailAddressId(orgWideAddObj.id);

    lstMsgsToSend.add(mailObj);
    Messaging.sendEmail(lstMsgsToSend);
  }
}