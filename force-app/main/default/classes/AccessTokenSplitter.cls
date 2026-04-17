/** Splits access tokens into parts to fit custom field length limits. */
public inherited sharing class AccessTokenSplitter {

    /** Result container holding the two parts of a split token. */
	public class SplitResult {
        /** First portion of the split string. */
        public String firstPart;
        /** Remaining portion after the split. */
        public String restPart;
    }

    /**
     * Splits the input string at the configured token split length.
     * @param input the string to split
     * @return SplitResult with firstPart and restPart
     */
    public static SplitResult splitBy175(String input) {
        SplitResult result = new SplitResult();

        if (String.isBlank(input)) {
            result.firstPart = '';
            result.restPart  = '';
            return result;
        }

        if (input.length() <= TSANetConstants.TOKEN_SPLIT_LENGTH) {
            result.firstPart = input;
            result.restPart  = '';
        } else {
            result.firstPart = input.substring(0, TSANetConstants.TOKEN_SPLIT_LENGTH);
            result.restPart  = input.substring(TSANetConstants.TOKEN_SPLIT_LENGTH);
        }

        return result;
    }
}