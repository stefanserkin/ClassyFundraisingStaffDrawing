public without sharing class StaffPrizeAwarder {

    @InvocableMethod(label='Draw Prize')
    public static List<Result> drawPrize(
        List<Request> lstRequests
    ) {
        // Parse input
        Id prizeId = lstRequests.get(0).prizeId;
        String staffType = lstRequests.get(0).staffType;

        // Get all entries for criteria that are not already associated with a prize
        List<Fundraising_Page__c> lstPagesWithEntries = [
            SELECT Id,
                   (SELECT Id, Winner__c, Prize_Won__c, Staff_Member_Name__c, Staff_Member_Email__c
                      FROM Staff_Prize_Entries__r)
              FROM Fundraising_Page__c
             WHERE Fundraiser_Type__c = :staffType
               AND Id NOT IN (SELECT Fundraising_Page__c 
                                FROM Staff_Prize_Entry__c 
                               WHERE Winner__c = true)
              WITH SECURITY_ENFORCED
             LIMIT 10000
        ];
        /*
        List<Staff_Prize_Entry__c> lstEntries = [
            SELECT Id, Winner__c, Prize_Won__c, Staff_Member_Name__c, Staff_Member_Email__c
              FROM Staff_Prize_Entry__c 
             WHERE Winner__c = false 
               AND Fundraising_Page__r.Fundraiser_Type__c = :staffType
               AND Fundraising_Page__c NOT IN (SELECT Fundraising_Page__c 
                                                 FROM Staff_Prize_Entry__c 
                                                WHERE Winner__c = true)
              WITH SECURITY_ENFORCED
        ];
        */

        // Create entry pool
        List<Staff_Prize_Entry__c> lstEntries = new List<Staff_Prize_Entry__c>();

        for (Fundraising_Page__c fp : lstPagesWithEntries) {
            lstEntries.addAll(fp.Staff_Prize_Entries__r);
        }

        // Generate random number from 0 to the size of the list
        Integer numEntries = lstEntries.size();
        Integer randomNumber = (Math.random() * numEntries).intValue();

        // Get winning entry
        Staff_Prize_Entry__c winningEntry = lstEntries.get(randomNumber);

        // Return result
        List<Result> lstResults = new List<Result>();
        Result result = new Result();
        result.winningEntry = winningEntry;
        lstResults.add(result);
        return lstResults;

    }

    public class Request {
        @InvocableVariable
        public Id prizeId;

        @InvocableVariable
        public String staffType;
    }

    public class Result {
        @InvocableVariable
        public Staff_Prize_Entry__c winningEntry;
    }
    
}
