public with sharing class viewShareSurveyComponentController {

    public Id surveyId { get; set; }
    public List < SelectOption > urlType {get;set;}
    public String selectedURLType {get;set;}

    public String surveyURL {
        get {
            if (selectedURLType == 'Email Link, Anonymous' || selectedURLType == 'Chatter') {
                return 'id=' + surveyId + '&cId=none&caId=none';
            } else if (selectedURLType == 'Email Link w/ Contact Merge') {
                return 'id=' + surveyId + '&cId={!Contact.Id}&caId=none';
            } else {
                return 'id=' + surveyId + '&cId={!Contact.Id}&caId={!Case.id}';
            }
        }

        set;
    }

    public String surveySite {
        get{
            if(surveySite == null){
                surveySite = getVFUrl();
            }
            return surveySite;
        }
        set;
    }
        public String surveyURLBase {
        get {
            if (selectedURLType == 'Chatter') {
                 surveyURLBase = getVFUrl();
            }else{
                surveyURLBase = surveySite;//Updated when select list is changed
            }
            return surveyURLBase;
        }
        set;
    }
    public viewShareSurveyComponentController() {
        urlType = new List < SelectOption > ();
        urlType.add(new SelectOption('Email Link w/ Contact Merge', System.Label.LABS_SF_Email_Link_w_Contact_Merge));
        urlType.add(new SelectOption('Email Link w/ Contact & Case Merge', System.Label.LABS_SF_Email_Link_w_Contact_Case_Merge));
        urlType.add(new SelectOption('Email Link, Anonymous', System.Label.LABS_SF_Email_Link_Anonymous));
        urlType.add(new SelectOption('Chatter', System.Label.LABS_SF_Chatter));
        selectedURLType = 'Chatter';
    }

    public String getVFUrl()
    {
        system.debug('Host:----'+ApexPages.currentPage().getHeaders().get('Host'));
        return 'https://' + ApexPages.currentPage().getHeaders().get('Host') + Page.TakeSurvey.getUrl() + '?';
    }



    public List < Selectoption > sitesPicklist {
        get{
            sitesPicklist = new List < Selectoption > ();
            try{
                sitesPicklist.add(new Selectoption(getVFUrl(), 'Internal'));

                List<Site> siteList = [Select Name, Status,  Subdomain, UrlPathPrefix, SiteType, OptionsRequireHttps from Site where Subdomain != ''];
                system.debug('siteList-----'+siteList);
                for(Site s: siteList){
                    system.debug('Site Name-----'+s.Name);
                    String url = (s.OptionsRequireHttps == true)?'https://':'http://';
                    system.debug('url-----Line 69'+url);
                    url += Utilities1.getSubdomainPrefix() + s.Subdomain + '.';
                    system.debug('url-----Line 71'+url);
                    url += Utilities1.getInstance();
                    system.debug('url-----Line 73'+url);
                    url += (s.OptionsRequireHttps == true && s.SiteType == 'Visualforce')?'secure.force.com/':'force.com/';
                    system.debug('url-----Line 75'+url);
                    url += (String.isEmpty(s.UrlPathPrefix))?'':s.UrlPathPrefix + '/';
                    system.debug('url-----Line 77'+url);
                    url += 'TakeSurvey?';
                    system.debug('Printing the Url-----'+url);
                    sitesPicklist.add(new Selectoption(url, s.Name));
                }
            }catch(Exception e){
                System.debug('Exception:' + e.getMessage());
            }
            return sitesPicklist;
        }
        set;
    }
}