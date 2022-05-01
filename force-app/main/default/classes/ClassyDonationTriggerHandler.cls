public without sharing class ClassyDonationTriggerHandler {

    public static void beforeInsert(
        List<Classy_Donation__c> newList
    ) {
        Set<Id> setPageIds = new Set<Id>();
        for (Classy_Donation__c cd : newList) {
            setPageIds.add(cd.Fundraising_Page__c);
        }
        
        Map<Id, Fundraising_Page__c> mapPages = new Map<Id, Fundraising_Page__c>([
            SELECT Id, Campaign__c FROM Fundraising_Page__c WHERE Id IN :setPageIds
        ]);
        
        for (Classy_Donation__c cd : newList) {
            String donationName = cd.Supporter_Display_Name__c + ' - ' + 
                '$' + String.valueOf(cd.Gross_Transaction_Amount__c.format()) + ' - ' +
                String.valueOf(cd.Transaction_Date__c.format());
            cd.Name = donationName.left(80);
            cd.Campaign__c = mapPages.get(cd.Fundraising_Page__c).Campaign__c;
        }
    }

    public static void afterInsert(
        List<Classy_Donation__c> newList
    ) {
        Set<Id> setPageIds = new Set<Id>();
        for (Classy_Donation__c cd : newList) {
            setPageIds.add(cd.Fundraising_Page__c);
        }

        Map<Id, Fundraising_Page__c> mapPagesWithDonations = new Map<Id, Fundraising_Page__c>([
            SELECT Id, Name, Fundraiser_Type__c, Number_of_Unique_Donors__c, Gross_Transaction_Amount__c, 
                   (SELECT Id, Gross_Transaction_Amount__c, Gift_Type__c, Donor_Supporter_ID__c 
                      FROM Classy_Donations__r 
                     ORDER BY Gross_Transaction_Amount__c DESC)
              FROM Fundraising_Page__c
             WHERE Id IN :setPageIds
              WITH SECURITY_ENFORCED
             ORDER BY Gross_Transaction_Amount__c DESC
        ]);

        for (Fundraising_Page__c page : mapPagesWithDonations.values()) {
            Set<String> setDonorIds = new Set<String>();
            for (Classy_Donation__c cd : page.Classy_Donations__r) {
                if (cd.Donor_Supporter_ID__c != null && !String.isBlank(cd.Donor_Supporter_ID__c)) {
                    setDonorIds.add(cd.Donor_Supporter_ID__c);
                }
            }
            page.Number_of_Unique_Donors__c = setDonorIds.size();
        }

        update mapPagesWithDonations.values();
    }
    
}
