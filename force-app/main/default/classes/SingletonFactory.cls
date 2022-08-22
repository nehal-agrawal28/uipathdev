/**
* @author Girish Lakshmanan
* @date 18/03/2019
* @description Factory to create Singleton instances. Note that Singletons in Apex are scoped only to the Transaction
*/

public class SingletonFactory {
    private static Pricebook2 stdPriceBook = null;

    private static Pricebook2 getStdPriceBook() {

        return [select id, name from Pricebook2 where isStandard = true limit 1];
    }

    public static Pricebook2 getStandardPriceBookInstance() {
        // lazy load the record type - only initialize if it doesn't already exist
        if (stdPriceBook == null) stdPriceBook = getStdPriceBook();
        return stdPriceBook;
    }
}