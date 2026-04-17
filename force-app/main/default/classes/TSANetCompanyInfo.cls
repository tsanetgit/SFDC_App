/** Wrapper for TSANet company and user information. */
global inherited sharing class TSANetCompanyInfo {

    /** User associated with the company. */
    global CompanyUser user;
    /** Company details. */
    global Company company;

    /** Represents a user within a TSANet company. */
	global class CompanyUser {
        /** Email address of the company user. */
        global String email;
    }

    /** Represents a TSANet partner company. */
    global class Company {
        /** Unique identifier of the company. */
        global String id;
        /** Name of the company. */
        global String name;
    }
}