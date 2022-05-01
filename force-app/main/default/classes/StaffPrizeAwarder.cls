public without sharing class StaffPrizeAwarder {

    @InvocableMethod(label='Draw Prize')
    public static List<Result> drawPrize(
        List<Request> lstRequests
    ) {
        // Parse input
        Id prizeId = lstRequests.get(0).prizeId;
        String staffType = lstRequests.get(0).staffType;

        // Get all entries for criteria that are not already associated with a prize
        List<Staff_Prize_Entry__c> lstEntries = [
            SELECT Id, Winner__c, Prize_Won__c, Staff_Member_Name__c, Staff_Member_Email__c
              FROM Staff_Prize_Entry__c 
             WHERE Winner__c = false 
               AND Fundraising_Page__r.Fundraiser_Type__c = :staffType
              WITH SECURITY_ENFORCED
        ];

        // Generate random number from 0 to the size of the list
        Integer numEntries = lstEntries.size();
        Integer randomNumber = Integer.valueOf((Math.random() * numEntries) - 0.01);

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
