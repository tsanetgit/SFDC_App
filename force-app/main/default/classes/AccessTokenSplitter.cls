public class AccessTokenSplitter {
    
	public class SplitResult {
        public String firstPart;
        public String restPart;
    }

    public static SplitResult splitBy175(String input) {
        SplitResult result = new SplitResult();

        if (String.isBlank(input)) {
            result.firstPart = '';
            result.restPart  = '';
            return result;
        }

        if (input.length() <= 175) {
            result.firstPart = input;
            result.restPart  = '';
        } else {
            result.firstPart = input.substring(0, 175);
            result.restPart  = input.substring(175);
        }

        return result;
    }
}