trigger ProductOfferTrigger on ProductOffer__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert){
        ProductOfferTriggerHandler.onAfterInsert(Trigger.new);
    }
}