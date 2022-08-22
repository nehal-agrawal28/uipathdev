public without sharing class TaskMetadata_CM {
  //RT Names
  public static final String ONBOARDING_PLAYBOOK = 'Onboarding_Playbook';

  public static Id getRecordTypeId(String developerName) {
    Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    return recordTypeId;
  }

  public static Id OnboardingPlaybookRecordType {
    get {
      if (OnboardingPlaybookRecordType == null) {
        OnboardingPlaybookRecordType = getRecordTypeId(ONBOARDING_PLAYBOOK);
      }
      return OnboardingPlaybookRecordType;
    }
    set;
  }
}