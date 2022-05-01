public without sharing class ClassyDonationUtilities {
    
    public static void deleteAllData() {
        delete [SELECT Id FROM Classy_Donation__c];
        delete [SELECT Id FROM Fundraising_Page__c WHERE Name != 'Donation Page (No Fundraiser)'];
    }

    public static void deleteAllStaffPrizeEntries() {
        delete [SELECT Id FROM Staff_Prize_Entry__c];
        List<Fundraising_Page__c> lstPages = [
            SELECT Id, Most_Unique_Donors__c, Single_Largest_Donation_Collected__c, Top_Staff_Fundraiser__c 
              FROM Fundraising_Page__c
             WHERE Most_Unique_Donors__c = true 
                OR Single_Largest_Donation_Collected__c = true 
                OR Top_Staff_Fundraiser__c = true
        ];
        for (Fundraising_Page__c page : lstPages) {
            page.Most_Unique_Donors__c = false;
            page.Single_Largest_Donation_Collected__c = false;
            page.Top_Staff_Fundraiser__c = false;
        }
        if (!lstPages.isEmpty()) {
            update lstPages;
        }
        
    }

}
