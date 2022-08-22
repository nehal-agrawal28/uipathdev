/**
 * @Author	:	Jitendra Zaa
 * @Desc	:	Utility class to run Enterprise Territory Management Assignment rules
 * */
public without sharing class RunTerritoryRules extends AbstractQueueable {
  public List<Account> accountList = null;
  private String sessionId = null;
  private String loggerTransactionId;

  public RunTerritoryRules(String loggerTransactionId, List<SObject> accountList) {
    super('RunTerritoryRules');
    this.accountList = accountList;
    this.loggerTransactionId = loggerTransactionId;
  }
  public override void work() {
    Logger.setParentLogTransactionId(loggerTransactionId);
    try {
      List<String> lstAccString = new List<String>();
      for (Account acc : accountList) {
        lstAccString.add(accountTag.replace('{ACCID}', acc.Id));
      }
      requestTemplate = requestTemplate.replace('{ACCLISTS}', String.join(lstAccString, ' '));
      requestTemplate = requestTemplate.replace(
        '{SESSID}',
        UserInfo.getOrganizationId() +
        '' +
        UserInfo.getSessionId().SubString(15)
      );
      HttpRequest request = new HttpRequest();

      request.setEndpoint(
        System.URL.getSalesforceBaseUrl().toExternalForm() +
        '/services/Soap/u/' +
        getApiVersion() +
        '/' +
        UserInfo.getOrganizationId()
      );
      request.setMethod('POST');
      request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
      request.setTimeout(120000);
      request.setHeader('SOAPAction', '""');
      request.setBody(requestTemplate);
      logger.debug(
        new LogMessage(
          'Request Body: {0}\n\nRequest EndPoint: {1}',
          new List<String>{ JSON.serializePretty(request.getBody()), request.getEndpoint() }
        )
      );
      String response = String.valueOf(new Http().send(request).getBodyDocument());
      logger.debug(response);
    } catch (Exception ex) {
      logger.error('Failed in RunTerritoryRules', ex);
    } finally {
      logger.saveLog();
    }
  }

  private static String getApiVersion() {
    String userJson = JSON.serialize(new User(Id = UserInfo.getUserId()));
    return userJson.substringAfter('/data/').substringBefore('/sobjects/User');
  }

  String accountTag =
    '<urn:sObjects> ' +
    '<urn1:type>Account</urn1:type>  ' +
    '<urn1:Id>{ACCID}</urn1:Id>   ' +
    '</urn:sObjects> ';
  String requestTemplate =
    '<soapenv:Envelope ' +
    'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"' +
    ' xmlns:urn="urn:partner.soap.sforce.com"' +
    ' xmlns:urn1="urn:sobject.partner.soap.sforce.com">' +
    '<soapenv:Header> ' +
    '<urn:AssignmentRuleHeader> ' +
    '<urn:useDefaultRule>true</urn:useDefaultRule> ' +
    '<urn:assignmentRuleId></urn:assignmentRuleId> ' +
    '</urn:AssignmentRuleHeader>  ' +
    '<urn:SessionHeader> ' +
    '<urn:sessionId>{SESSID}</urn:sessionId> ' +
    '</urn:SessionHeader> ' +
    '</soapenv:Header> ' +
    '<soapenv:Body> ' +
    '<urn:update> ' +
    ' {ACCLISTS}' +
    '</urn:update> ' +
    '</soapenv:Body> ' +
    '</soapenv:Envelope>';
}