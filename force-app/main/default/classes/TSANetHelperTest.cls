@IsTest

public class TSANetHelperTest {


    @IsTest
    public static void stripHtmlTagsTest(){
        String text = TSANetHelper.stripHtmlTags('<b>test</b>');
        System.assertEquals('test', text);
    }

}