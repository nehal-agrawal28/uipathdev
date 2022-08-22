public class threadIdClass {
  public static String CASE_REF_FORMAT = 'ref:{0}.{1}:ref';

  @testVisible
  private static String shortenOrgId(String id) {
    String part = id.substring(0, 15);
    Pattern p = Pattern.compile('^([A-Za-z0-9]{5})([A-Za-z0-9]*)$');
    Matcher m = p.matcher(part);

    if (m.matches()) {
      return '_' + m.group(1) + m.group(2).replace('0', '');
    }

    return '';
  }

  @testVisible
  private static String shortenCaseId(String id) {
    String part = id.substring(0, 15);
    Pattern p = Pattern.compile('^([A-Za-z0-9]{5})([A-Za-z0-9]*)([A-Za-z0-9]{5})$');
    Matcher m = p.matcher(part);

    if (m.matches()) {
      return '_' + m.group(1) + m.group(2).replace('0', '') + m.group(3);
    }

    return '';
  }

  public static String caseRefId(String orgId, String caseId) {
    if (orgId == null || caseId == null) {
      return '';
    }

    String shortenedOrgId = shortenOrgId(orgId);
    String shortenedCaseId = shortenCaseId(caseId);

    return String.format(CASE_REF_FORMAT, new List<String>{ shortenedOrgId, shortenedCaseId });
  }
}