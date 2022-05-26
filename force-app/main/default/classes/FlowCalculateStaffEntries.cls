public without sharing class FlowCalculateStaffEntries {

    private static final String REASON_SET_UP_PAGE = 'Set up class page';
    private static final String REASON_UNIQUE_DONOR = 'Unique donor';
    private static final String REASON_HUNDRED_RAISED = '$100 raised';
    private static final String REASON_MOST_UNIQUE_DONORS = 'Most unique donors';
    private static final String REASON_SINGLE_LARGEST_DONATION = 'Single largest donation collected';
    private static final String REASON_TOP_FUNDRAISER = 'Top staff fundraiser';
    private static final String GENERIC_DONATION_PAGE_NAME = 'Donation Page (No Fundraiser)';
    private static final String TYPE_NON_EMPLOYEE = 'Non-employee';

    private static Decimal mostUniqueDonorsAmount;
    private static Decimal largestDonationAmount;
    private static Decimal topFundraiserAmount;
    private static Set<Fundraising_Page__c> mostUniqueDonorsWinners;
    private static Set<Fundraising_Page__c> largestDonationWinners;
    private static Set<Fundraising_Page__c> topFundraisers;


    @InvocableMethod(label='Calculate Staff Entries')
    public static List<Result> calculateStaffEntries(
        List<Request> lstRequests
    ) {
        // Initialize transaction variables
        mostUniqueDonorsAmount  = 0;
        largestDonationAmount   = 0;
        topFundraiserAmount     = 0;
        mostUniqueDonorsWinners = new Set<Fundraising_Page__c>();
        largestDonationWinners  = new Set<Fundraising_Page__c>();
        topFundraisers          = new Set<Fundraising_Page__c>();

        // Parse input
        String campaignId = lstRequests.get(0).campaignId;
        Boolean includeMatching = lstRequests.get(0).includeMatching;
        // Get pages with related donations
        List<Fundraising_Page__c> lstPagesWithDonations = [
            SELECT Id, Fundraiser_Type__c, Gross_Transaction_Amount__c, 
                   Number_of_Unique_Donors__c, Number_of_Hundreds_Raised__c, 
                   Single_Largest_Donation_Collected__c, Most_Unique_Donors__c, 
                   Top_Staff_Fundraiser__c, 
                   (SELECT Id, Gross_Transaction_Amount__c, Gift_Type__c, Donor_Supporter_ID__c 
                      FROM Classy_Donations__r
                     ORDER BY Gross_Transaction_Amount__c DESC)
              FROM Fundraising_Page__c
             WHERE Campaign__c = :campaignId
               AND Name != :GENERIC_DONATION_PAGE_NAME
              WITH SECURITY_ENFORCED
             ORDER BY Gross_Transaction_Amount__c DESC
             LIMIT 10000
        ];

        List<Staff_Prize_Entry__c> lstEntries = new List<Staff_Prize_Entry__c>();
        // Do the accumulative math - add eligible entries, per donation, to list
        for (Fundraising_Page__c page : lstPagesWithDonations) {
            lstEntries.addAll(
                getAccumulativeEntries( page )
            );
        }

        // Grant entries for overall winners and update page records
        Map<Id, Fundraising_Page__c> mapWinningPages = new Map<Id, Fundraising_Page__c>();

        // 10 for most unique donors
        for (Fundraising_Page__c winner : mostUniqueDonorsWinners) {
            for (Integer i = 0; i < 10; i++) {
                lstEntries.add(
                    new Staff_Prize_Entry__c(
                        Fundraising_Page__c = winner.Id,
                        Entry_Reason__c = REASON_MOST_UNIQUE_DONORS
                    )
                );
            }
            if (mapWinningPages.containsKey(winner.Id)) {
                mapWinningPages.get(winner.Id).Most_Unique_Donors__c = true;
            } else {
                winner.Most_Unique_Donors__c = true;
                mapWinningPages.put(
                    winner.Id, winner
                );
            }
        }
        // 10 for single largest donation
        for (Fundraising_Page__c winner : largestDonationWinners) {
            for (Integer i = 0; i < 10; i++) {
                lstEntries.add(
                    new Staff_Prize_Entry__c(
                        Fundraising_Page__c = winner.Id,
                        Entry_Reason__c = REASON_SINGLE_LARGEST_DONATION
                    )
                );
            }
            if (mapWinningPages.containsKey(winner.Id)) {
                mapWinningPages.get(winner.Id).Single_Largest_Donation_Collected__c = true;
            } else {
                winner.Single_Largest_Donation_Collected__c = true;
                mapWinningPages.put(
                    winner.Id, winner
                );
            }
        }
        // 10 for top fundraiser
        for (Fundraising_Page__c winner : topFundraisers) {
            for (Integer i = 0; i < 10; i++) {
                lstEntries.add(
                    new Staff_Prize_Entry__c(
                        Fundraising_Page__c = winner.Id,
                        Entry_Reason__c = REASON_TOP_FUNDRAISER
                    )
                );
            }
            if (mapWinningPages.containsKey(winner.Id)) {
                mapWinningPages.get(winner.Id).Top_Staff_Fundraiser__c = true;
            } else {
                winner.Top_Staff_Fundraiser__c = true;
                mapWinningPages.put(
                    winner.Id, winner
                );
            }
        }

        if (!mapWinningPages.isEmpty()) {
            update mapWinningPages.values();
        }

        // Insert entries
        if (!lstEntries.isEmpty()) {
            insert lstEntries;
        }
        // Return result
        List<Result> lstResults = new List<Result>();
        Result result = new Result();
        result.numEntriesGenerated = lstEntries.size();
        lstResults.add(result);
        return lstResults;

    }
    
    public class Request {
        @InvocableVariable(required=true label='Campaign ID')
        public String campaignId;
        @InvocableVariable
        public Boolean includeMatching;
    }

    public class Result {
        @InvocableVariable(label='Number of Entries Generated')
        public Integer numEntriesGenerated;
    }

    /*
    private static String constructQueryString(
        String campaignId, Boolean includeMatching
    ) {
        String queryString = 'select Id, Fundraiser_Type__c, Gross_Transaction_Amount__c, Number_of_Unique_Donors__c, Number_of_Hundreds_Raised__c, Single_Largest_Donation_Collected__c, Most_Unique_Donors__c, Top_Staff_Fundraiser__c, (select Id, Gross_Transaction_Amount__c, Gift_Type__c, Donor_Supporter_ID__c from Classy_Donations__r ';
        if (!includeMatching) {
            queryString += 'where Gift_Type__c != \'Matching Gift\'';
        }
        queryString += ') from Fundraising_Page__c where Campaign__c = \'' + campaignId + '\' and Fundraiser_Type__c != \'Non-employee\'';
        System.debug('::::: query string is : ' + queryString);
        return queryString;
    }
    */

    private static List<Staff_Prize_Entry__c> getAccumulativeEntries(
        Fundraising_Page__c pageWithDonations
    ) {
        List<Staff_Prize_Entry__c> lstPageEntries = new List<Staff_Prize_Entry__c>();
        Integer numHundreds = pageWithDonations.Number_of_Hundreds_Raised__c != null ? 
            Integer.valueOf(pageWithDonations.Number_of_Hundreds_Raised__c) : 
            0;
        Integer numUniqueDonors = pageWithDonations.Number_of_Unique_Donors__c != null ?
            Integer.valueOf(pageWithDonations.Number_of_Unique_Donors__c) :
            0;
        Decimal largestPageGiftAmount = !pageWithDonations.Classy_Donations__r.isEmpty() ?
            pageWithDonations.Classy_Donations__r.get(0).Gross_Transaction_Amount__c :
            0;

        // Set up page
        lstPageEntries.add(
            new Staff_Prize_Entry__c(
                Fundraising_Page__c = pageWithDonations.Id,
                Entry_Reason__c = REASON_SET_UP_PAGE
            )
        );

        // Number of hundreds raised
        for (Integer i = 0; i < numHundreds; i++) {
            lstPageEntries.add(
                new Staff_Prize_Entry__c(
                    Fundraising_Page__c = pageWithDonations.Id,
                    Entry_Reason__c = REASON_HUNDRED_RAISED
                )
            );
        }

        // Unique donors
        for (Integer i = 0; i < numUniqueDonors; i++) {
            lstPageEntries.add(
                new Staff_Prize_Entry__c(
                    Fundraising_Page__c = pageWithDonations.Id,
                    Entry_Reason__c = REASON_UNIQUE_DONOR
                )
            );
        }

        // Compare to leading values
        if (numUniqueDonors > mostUniqueDonorsAmount) {
            mostUniqueDonorsWinners.clear();
            mostUniqueDonorsWinners.add(pageWithDonations);
            mostUniqueDonorsAmount = numUniqueDonors;
        } else if (numUniqueDonors == mostUniqueDonorsAmount) {
            mostUniqueDonorsWinners.add(pageWithDonations);
        }

        if (largestPageGiftAmount > largestDonationAmount) {
            largestDonationWinners.clear();
            largestDonationWinners.add(pageWithDonations);
            largestDonationAmount = largestPageGiftAmount;
        } else if (largestPageGiftAmount == largestDonationAmount) {
            largestDonationWinners.add(pageWithDonations);
        }

        if (pageWithDonations.Gross_Transaction_Amount__c > topFundraiserAmount) {
            topFundraisers.clear();
            topFundraisers.add(pageWithDonations);
            topFundraiserAmount = pageWithDonations.Gross_Transaction_Amount__c;
        } else if (pageWithDonations.Gross_Transaction_Amount__c == topFundraiserAmount) {
            topFundraisers.add(pageWithDonations);
        }

        return lstPageEntries;
    }

}
