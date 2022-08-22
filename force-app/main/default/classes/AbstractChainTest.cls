@IsTest
public class AbstractChainTest {

    private static final String CALL_LOG = 'calls';

    @IsTest
    private static void chains_queueables_successfully() {

        AbstractChain chain = new ChainingSampleQueueable1()
            .setShared(CALL_LOG, new List<String>())
            .then( new ChainingSampleQueueable2() )
            .execute();

        Iterator<String> calls = ((List<String>) chain.getShared(CALL_LOG)).iterator();
        System.assertEquals('ChainingSampleQueueable1.work', calls.next());
        System.assertEquals('ChainingSampleQueueable2.work', calls.next());
    }

    public static void log(AbstractChain chainable) {
        List<String> calls = (List<String>) chainable.getShared(CALL_LOG);
        calls.add(callLocation());
    }


    // Note: Idea taken from https://salesforce.stackexchange.com/questions/153835
    private static String callLocation() {
        Pattern STACK_LINE = Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');

        for(String line : new DmlException().getStackTraceString().split('\n')) {
            Matcher matcher = STACK_LINE.matcher(line);

            if(matcher.find() && !line.startsWith('Class.' + AbstractChainTest.class.getName() + '.')) {
                return matcher.group(1) + '.' + matcher.group(2);
            }
        }

        return null;
    }
}