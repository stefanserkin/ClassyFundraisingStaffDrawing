trigger ClassyDonationTrigger on Classy_Donation__c (before insert, after insert) {

    if (Trigger.isInsert && Trigger.isBefore) {
        ClassyDonationTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isInsert && Trigger.isAfter) {
        ClassyDonationTriggerHandler.afterInsert(Trigger.new);
    }
    
}