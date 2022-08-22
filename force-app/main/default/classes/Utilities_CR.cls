public with sharing class Utilities_CR {

    public static final String UIPATH_CI_SCRATCH_NAME = 'UiPathScratchOrg';


    /**
     * @return true if current org is a UiPath scratch Org
     */
    public static Boolean isScratchOrg() {
        Organization org = [SELECT Name FROM Organization];
        return org.Name==UIPATH_CI_SCRATCH_NAME;
    }
}