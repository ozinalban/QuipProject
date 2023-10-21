public class ProductOfferTriggerHandler {

    public static void onAfterInsert (List<ProductOffer__c> newList){
    
        sendEmailForNewProductOffer (newList);

    }

    public static void sendEmailForNewProductOffer (List<ProductOffer__c>  newList) {
        List<ProductOffer__c> offersWithRelatedObj = getOffersWithRelatedObjects(newList);
        List<User> customers = getCustomers();

         // Terminate the process if there are no available Offer or User
        if (offersWithRelatedObj.isEmpty() || customers.isEmpty()) return;

        Set<Id> productIds = getProductIDs (offersWithRelatedObj);
        Map<Id, Double> listPriceMapByProductId = getPricesByProductId(productIds);
        Map<Id, Double> discountMapByOfferId = getdiscountMapByOfferId (offersWithRelatedObj, listPriceMapByProductId);
        Map<Id, String> imageUrlMapByProductId = getImageUrlMapByProductId(productIds);

        // Create Email
        List<Messaging.SingleEmailMessage> emails =  new List<Messaging.SingleEmailMessage> ();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> emailAddresses = new List<String>();
        String htmlEmailBody = '<h1 style="color: red; text-align: center;">New Discount Available For You!</h1>'+
                            '<h2 style="text-align: center;">There is a limited stock. Hurry up!</h2>';

        // Set the Recipient Emails
        for (User u:customers){
            emailAddresses.add(u.Email);
        }
        email.setToAddresses(emailAddresses);

        // Set the email body
        htmlEmailBody = getOfferHTMLBody (offersWithRelatedObj, listPriceMapByProductId, discountMapByOfferId, imageUrlMapByProductId, htmlEmailBody);
    
        System.debug('Email Body' + htmlEmailBody);
        System.debug('Image URL : ' +  imageUrlMapByProductId.get(offersWithRelatedObj[0].Product__c));
        email.setHtmlBody(htmlEmailBody);

        // Send the email
        emails.add(email);
        Messaging.SendEmailResult[] result = Messaging.sendEmail(emails);
    }

     /***********************  HELPER METHODS *****************/
     
    private static String getOfferHTMLBody (List<ProductOffer__c> offersWithRelatedObj, Map<Id, Double> listPriceMapByProductId, Map<Id, Double> discountMapByOfferId, Map<Id, String> imageUrlMapByProductId, String htmlEmailBody){
        for(ProductOffer__c offer:offersWithRelatedObj){
            htmlEmailBody += 
            '<div style="display: flex; border: 1px solid #ccc; margin: 10px 0;">' +
                '<div style="flex: 1; padding: 30px; order: 1; width: 30%;">'+
                    '<p style="font-size: 2rem;>' + offer.Product__r.Name + '</p> <br/>'+
                    '<p style="font-size: 1.5rem; color:red;" ><b>List Price : <strike>' + listPriceMapByProductId.get(offer.Product__c) + ' ₺ </strike></b></p> <br/>'+
                    '<p style="font-size: 1.5rem;" ><b>Discount : ' + offer.Coupon__r.Name + '</b></p><br/>'+
                    '<p style="font-size: 1.5rem;" ><b>Discounted Price: ' + (listPriceMapByProductId.get(offer.Product__c) - discountMapByOfferId.get(offer.id)) +  ' ₺</b></p><br/> <br/>'+
                    '<p style="font-size: 1.5rem; color:green;" ><b>Your Earning: ' + discountMapByOfferId.get(offer.id) +  ' ₺</b></p><br/> <br/>'+
                    '<a target="_blank" href="' + 'https://www.google.com' + '" style="font-size: 20px; background-color:blue; color: white;padding: 14px 25px; text-align: center;text-decoration: none;display: inline-block; border-radius: 12px;" onMouseOver="this.style.backgroundColor=\'royalblue\'" onMouseOut="this.style.backgroundColor=\'blue\'">Go To Product</a>'+
                '</div>'+
                '<div style="flex: 1; margin-right: 20px; padding: 30px; order: 2; width: 30%;">'+
                    '<img src="' + imageUrlMapByProductId.get(offer.Product__c) + '" alt="Product 1" width: "25%">'+
                '</div>'+
            '</div>';

        }   

        // '<img src="' + imageUrlMapByProductId.get(offer.Product__c) + '" alt="Product 1">'+
        return htmlEmailBody;
    }

     private static List<ProductOffer__c> getOffersWithRelatedObjects (List<ProductOffer__c> newList) {
        return [SELECT Id, Name, Coupon__c, Product__c, 
                Coupon__r.Name , Coupon__r.Discount__c, Coupon__r.Expired__c, Coupon__r.Flat_Discount__c, Coupon__r.Remaining_Quantity__c, Coupon__r.Type__c,
                Product__r.Name
                FROM ProductOffer__c
                WHERE Coupon__r.Expiry_Date__c > TODAY
                AND Coupon__r.Remaining_Quantity__c > 0
                AND ID = :newList
                AND Product__c != NULL];
    }

    private static List<User> getCustomers (){
        return [SELECT Id, FirstName, Lastname, Email 
                FROM User 
                WHERE isActive = TRUE 
                AND Profile.Name = 'Customer Community User'];
    }

    private static Set<Id> getProductIDs (List<ProductOffer__c> offersWithRelatedObj){
        Set<Id> productIds = new Set<Id> ();
        for(ProductOffer__c offer:offersWithRelatedObj){
            productIds.add(offer.Product__c);
        }
        return productIds;
    }

    private static Map<Id, Double> getPricesByProductId (Set<Id> productIds){
        Map<Id, Double> listPriceMapByProductId = new Map<Id, Double>();
        for(PricebookEntry pbe:[SELECT IsActive, Product2Id, UnitPrice, UseStandardPrice
                                FROM PricebookEntry
                                WHERE IsActive = TRUE 
                                AND Product2Id IN :productIds
                                AND UseStandardPrice = TRUE 
                                AND UnitPrice > 0])
        {
            listPriceMapByProductId.put(pbe.Product2Id, pbe.UnitPrice);
        }
        return listPriceMapByProductId;
    }

    private static Map<Id, Double> getdiscountMapByOfferId (List<ProductOffer__c> offersWithRelatedObj, Map<Id, Double> listPriceMapByProductId){
        Map<Id, Double> discountMapByOfferId = new  Map<Id, Double>();
        for (ProductOffer__c offer:offersWithRelatedObj){
            Double listPrice;
            Double discount;
            if (offer.Coupon__r.Type__c == 'Percentage'){
                listPrice = listPriceMapByProductId.get(offer.Product__c);
                discount = offer.Coupon__r.Discount__c * listPrice / 100;
            } else {
                discount = offer.Coupon__r.Flat_Discount__c;
            }
            discountMapByOfferId.put(offer.id, discount);
        }
        return discountMapByOfferId;
    }

    private static Map<Id, String> getImageUrlMapByProductId (Set<Id> productIds) {
        Map<Id, String> imageUrlMapByProductId = new  Map<Id, String> ();
        for(Product_Images__c img:[SELECT Product__c, Type__c, Resource_URL__c
                                    FROM Product_Images__c
                                    WHERE Product__c IN :productIds]) {

            imageUrlMapByProductId.put(img.Product__c, img.Resource_URL__c);
        }
        return imageUrlMapByProductId;
    }

}