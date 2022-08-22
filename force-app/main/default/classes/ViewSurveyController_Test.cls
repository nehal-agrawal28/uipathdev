@istest
private class ViewSurveyController_Test {
  //------------------------------------------------------------------------------//
  //------------------------------------------------------------------------------//
  private static testMethod void testViewSurveyController() {
    SurveyTestingUtil tu = new SurveyTestingUtil();
    //tu.createTestSurvey();
    Apexpages.currentPage().getParameters().put('id', tu.surveyId);
    Apexpages.Standardcontroller stc;
    ViewSurveyController vsc = new ViewSurveyController(stc);
    vsc.init();
    System.assert(vsc.allQuestionsSize == 4);
    System.assert(tu.surveyId != null);

    vsc.submitResults();
    for (SFQuestion q : vsc.allQuestions) {
      q.selectedOption = String.valueof(2);
      q.choices = String.valueof(2);
      q.selectedOptions = new List<String>();
      q.selectedOptions.add(String.valueof(2));
      vsc.submitResults();
    }
    System.assertEquals(true, vsc.thankYouRendered);
  }

  private static testMethod void testUpdateSurveyName() {
    SurveyTestingUtil tu = new SurveyTestingUtil();
    Apexpages.currentPage().getParameters().put('id', tu.surveyId);
    Apexpages.Standardcontroller stc;
    ViewSurveyController vsc = new ViewSurveyController(stc);
    vsc.surveyName = 'new name';
    system.assert(vsc.updateSurveyName() == null);
  }

  private static testMethod void testupdateSurveyThankYouAndLink() {
    SurveyTestingUtil tu = new SurveyTestingUtil();
    Apexpages.currentPage().getParameters().put('id', tu.surveyId);
    Apexpages.Standardcontroller stc;
    ViewSurveyController vsc = new ViewSurveyController(stc);
    vsc.surveyThankYouText = 'new stuff';
    vsc.surveyThankYouURL = 'more new stff';
    system.assert(vsc.updateSurveyThankYouAndLink() == null);
  }

  private static testMethod void testUpdateSurveyName2() {
    SurveyTestingUtil tu = new SurveyTestingUtil();
    viewShareSurveyComponentController vscc = new viewShareSurveyComponentController();
    Apexpages.currentPage().getParameters().put('id',tu.surveyId);
    Apexpages.currentPage().getParameters().put('caId','testcaseid');
    Apexpages.currentPage().getParameters().put('cId','testcontactid');
    ViewSurveyController vsc = new ViewSurveyController(vscc);
    //Apexpages.currentPage().getParameters().put('id',tu.surveyId);
  }
}