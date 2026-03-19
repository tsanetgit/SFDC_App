global class TSANetCompanyInfo {
    
    global CompanyUser user;
    global Company company;
    
	global class CompanyUser {
        global String email;
    }
    
    global class Company {
        global String id;
        global String name;
    }
}