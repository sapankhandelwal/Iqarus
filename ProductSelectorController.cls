// 
// (c) 2015 Appirio, Inc.
//
// Controller for page allowing user to create booking line items for a booking, based upon available contract line items
//
// 19 November 2015     Shane Khublall       Original.
// 02 December 2015     Shane Khublall       Updates including replacing text with custom labels
// 15 December 2015     Khushal Dave         T-457534 added mapping for Uplift percentage from CLI to BLI
// 14 April 2016        Khushal Dave         T-492617 Updated SOQL query to only retrieve the Active CLI's
// 22 April 2016        Khushal Dave         T-497185 Updated the SOQL query and search field plus Vf has been modified.

public with sharing class ProductSelectorController
{
    //Search criteria fields
    //public String productNameToSearch {set;get;}
    public String customerproductNameToSearch {set;get;}
    public String resetTextBoxName {set; get;}
    
    public Id parentRecordId {get;set;} // Parent record will be a case
    private String bookingRecordTypeName;
    private RecordType bookingLineItemRecordType;
    private Case parentCase;
    public List<ContractLineItemWrapper> allCLIRecordsWrapped {set;get;} // used on page to hold record info + a checkbox for user interaction
    public Set <Id> allCLIRecordsPersistPageChange {set;get;} // store the ID of each record that is checked on the page by the user, to persist through page change

    private Map<String,Set<String>> recordTypeToProductFamilyMap = new Map<String,Set<String>>(); // to select products with the correct product families

    public ApexPages.StandardSetController ssc {get; set;} // For pagination
    public Integer pageSize = 10;// default page size of results returned

    // Constructor, calls init method to initialise required variables
    public ProductSelectorController()
    {
        init();
    }
    
    // Used in constructor, initialise all requried variables, including retrieval of custom setting records and retrieval of related Booking information
    // @param : no parameters
    // @return : does not return anything
    private void init()
    {
        allCLIRecordsPersistPageChange = new Set<Id>();
        try
        {
            for(Booking_Record_Type_to_Product_Families__c singlerecTypeToProdFam : Booking_Record_Type_to_Product_Families__c.getAll().values())
            {
                List<String> prodFams = singlerecTypeToProdFam.Product_Families__c.split(',');
                Set<String> productFamilies = new Set<String>();
                productFamilies.addAll(prodFams);
                recordTypeToProductFamilyMap.put(singlerecTypeToProdFam.Name,productFamilies);
            }
            System.debug('recordTypeToProductFamilyMap is: ' + recordTypeToProductFamilyMap);
        }
        catch(Exception e) 
        {
            ApexPages.Message noBookingSelected = new ApexPages.Message(ApexPages.Severity.Error,System.Label.custom_settings_not_defined + ': ' + e.getMessage());
            ApexPages.addMessage(noBookingSelected);
            return;
        }

        try
        {
            parentRecordId = System.currentPageReference().getParameters().get('bookingId');// need the booking Id
            for(Case singleCase: [SELECT Id, AccountId, RecordTypeId, Contract__c FROM Case WHERE Id =:parentRecordId])
            {
                parentCase = singleCase;
            }
            if(parentCase == null)
            {
                ApexPages.Message noBookingReturned = new ApexPages.Message(ApexPages.Severity.Error,System.Label.Booking_Not_Found);
                ApexPages.addMessage(noBookingReturned);
                return;
            }
            else
            {
                Schema.DescribeSObjectResult caseDescribe = Schema.SObjectType.Case; 
                Map<Id,Schema.RecordTypeInfo> caseRtIdToRT = caseDescribe.getRecordTypeInfosById();
                Schema.RecordTypeInfo rtById =  caseRtIdToRT.get(parentCase.RecordTypeId);                
                bookingRecordTypeName = rtById.getName();
                System.debug('bookingRecordTypeName is: ' + bookingRecordTypeName);
            }
        }
        catch(Exception e)
        {
            ApexPages.Message noBookingSelected = new ApexPages.Message(ApexPages.Severity.Error,System.Label.no_booking_selected + ': ' + e.getMessage());
            ApexPages.addMessage(noBookingSelected);
            return;
        }
    }

    //set to default status of page
    // @param : no parameters
    // @return : does not return anything
    public void resetSearchStatus()
    {        
        //Reset Contact fields
        if(resetTextBoxName != '')
        {
            if(resetTextBoxName=='1')
            {
                // productNameToSearch = '';
                 customerproductNameToSearch='';
            }
        }
        else
        {  
            //productNameToSearch = ''; 
            customerproductNameToSearch=  '';
        }
        performSearch();
    }

    // searches for Contract Line Items to display on Visualforce page. Excludes CLIs where a BLI has already been created for it.
    // @param : no parameters
    // @return : does not return anything
    public void performSearch()
    {
        if(parentCase!=null)
        {
            try{
                Set<Id> contractIds = new Set<Id>();
                for(Contract__c singleContract : [SELECT Id, Customer_Name__c FROM Contract__c
                WHERE Id=:parentCase.Contract__c AND(Status__c='Live' OR(Status__c='Lapsed' AND Continue_after_expiry_date__c=TRUE))])
                {
                    contractIds.add(singleContract.Id);
                }
                
                System.debug('contractIds are: ' + contractIds); 
    
                Set<String> productFamilySearchString = new Set<String>();
                if(recordTypeToProductFamilyMap.containsKey(bookingRecordTypeName))
                {
                    productFamilySearchString = recordTypeToProductFamilyMap.get(bookingRecordTypeName);
                }
                System.debug('productFamilySearchString is:' + productFamilySearchString);
                
                // Do not display any contract line items where a booking line item exists on the booking, and the booking line item has a parent contract line item that is returned from related contracts.
                List <Booking_Line_Item__c> allRelatedBookingLineItems = new List<Booking_Line_Item__c>([SELECT Id, Contract_line_item__c FROM Booking_Line_Item__c WHERE Case__c =:parentRecordId]);
                Set<Id> recordsToExclude = new Set<Id>();
                
                for(Booking_Line_Item__c singleBookingLineItem : allRelatedBookingLineItems)
                {
                   recordsToExclude.add(singleBookingLineItem.Contract_line_item__c);
                }
                System.debug('allRelatedBookingLineItems is: ' + allRelatedBookingLineItems);
                // Now get the child contract Line item records.
    
               // String productNameToSearchUpdated = '%' + (productNameToSearch==null?'%':productNameToSearch) + '%'; // The search term
                String customerproductNameToSearchUpdated = '%' + (customerproductNameToSearch==null?'%':customerproductNameToSearch) + '%';// The search term
                system.debug('select q:SELECT Id, Name, Contract__c, Quantity_contracted__c,Product_Family__c, Line_Item_Price__c, Clinical_Indicator__c, Customer_Product_Invoice_Name__c,Clinical_Indicator_Description__c, Chargeable_Overtime__c  FROM Contract_line_item__c WHERE Contract__c IN: '+contractIds+' AND Product_Family__c IN:'+ productFamilySearchString +'AND Id NOT IN: '+recordsToExclude+' AND Status__c!=\'Inactive\' AND Customer_Product_Invoice_Name__c LIKE:'+ customerproductNameToSearchUpdated+'');
                
                List<Contract_line_item__c> allChildContractLineItems = [SELECT Id, Name, Contract__c, Quantity_contracted__c, 
                                                                        Product_Family__c, Line_Item_Price__c, Clinical_Indicator__c, Customer_Product_Invoice_Name__c,  
                                                                        Clinical_Indicator_Description__c, Chargeable_Overtime__c  
                                                                        FROM Contract_line_item__c 
                                                                        WHERE Contract__c IN: contractIds AND Product_Family__c IN: productFamilySearchString 
                                                                        AND Id NOT IN: recordsToExclude AND Status__c!='Inactive' AND 
                                                                        Customer_Product_Invoice_Name__c LIKE: customerproductNameToSearchUpdated];
                
                ssc = new ApexPages.StandardSetController(allChildContractLineItems);
                ssc.setPageSize(pageSize);
                ssc.setpageNumber(1);
                System.debug('pageSize just after contract line item retrieval is : ' + ssc.getPageSize());
                System.debug('allChildContractLineItems is: ' + allChildContractLineItems);
                // This needs to be refined to show contract line items where their prodFamily matches the case's record type. This will need to wait until record types are defined on the Case object.
    
                System.debug('allCLIRecordsWrapped is: ' + allCLIRecordsWrapped);
                updatePageView();
            }
            catch(Exception e)
            {
                ApexPages.Message searchError = new ApexPages.Message(ApexPages.Severity.Error,System.label.Search_Error + ': ' + e.getMessage());
                ApexPages.addMessage(searchError);
                return;
            }
        }
    }

    // Attempts to insert new Booking Line Item records. Will add a page message to the Visualforce page showing the status.
    // @param : no parameters
    // @return : does not return anything
    public void insertBookingLIs() // Change this to a page reference, and show informational message on creation. Also run the search again.
    {
        List <Booking_line_item__c> newBookingLIs = new List<Booking_line_item__c>();
        updatePageView();
        
        if(bookingLineItemRecordType==null)// only populate this once
        {
            try
            {
                for(RecordType singleRecType: [SELECT Id FROM RecordType WHERE Name =: bookingRecordTypeName AND SobjectType = 'Booking_line_item__c'])
                {
                    bookingLineItemRecordType=singleRecType;
                }
            }
            catch(Exception e)
            {
                ApexPages.Message bookingLineCreationError = new ApexPages.Message(ApexPages.Severity.Info,System.label.No_record_type_defined_for_Booking_Line_Item + ' ' + bookingRecordTypeName + ' ' + System.label.No_record_type_defined_for_Booking_Line_Item_2  + ': ' + e.getMessage());
                ApexPages.addMessage(bookingLineCreationError);
            }
        }
        for(Contract_line_item__c single : [SELECT Id, Name, Contract__c,  Product__c, Quantity_contracted__c, Product_Family__c, Line_Item_Price__c, Clinical_Indicator__c, Customer_Product_Invoice_Name__c,  Clinical_Indicator_Description__c, Chargeable_Overtime__c, Unit_Type__c, Additional_Capabilities__c,Uplift_Percentage__c FROM Contract_line_item__c WHERE ID IN: allCLIRecordsPersistPageChange])
        {
            Booking_line_item__c singleRec = createBookingLI(single);
            newBookingLIs.add(singleRec);
        }

        System.debug('records to Insert: ' + newBookingLIs.size());
        if(newBookingLIs.size()>0)
        {
            try
            {
                insert newBookingLIs;
                String infoMsg = newBookingLIs.size()==1?' ' + System.label.Booking_Line_Item_Created: ' ' + System.label.Booking_Line_Items_Created;

                ApexPages.Message bookingLinesCreated = new ApexPages.Message(ApexPages.Severity.Info,newBookingLIs.size() + infoMsg);
                ApexPages.addMessage(bookingLinesCreated);
            }
            catch(Exception e)
            {
                ApexPages.Message bookingLineCreationError = new ApexPages.Message(ApexPages.Severity.Error,System.label.Error_Creating_Booking_Line_Item + ': ' + e.getMessage());
                ApexPages.addMessage(bookingLineCreationError);
            }
        }
        else
        {
            ApexPages.Message pleaseSelectProduct = new ApexPages.Message(ApexPages.Severity.Warning,System.label.Please_Select_Product);
                ApexPages.addMessage(pleaseSelectProduct);
        }
    }

    // Gets a list of records for display on the Visualforce page
    // @param : no parameters
    // @return : returns a list of contractLineItemWrapper records for display on the Visualforce page
    public List<ContractLineItemWrapper> updatePageView()
    {
        allCLIRecordsWrapped = new List<ContractLineItemWrapper>(); // this seems to be setting checkbox to zero, but if put elsewhere, problems arise
        for(Contract_line_item__c singleLI : (List<Contract_line_item__c>)ssc.getRecords())
        { 
            if(allCLIRecordsPersistPageChange.contains(singleLI.Id)) // this is for maintaining the checkboxes that were selected.
            {
                allCLIRecordsWrapped.add(new ContractLineItemWrapper(singleLI, true));
            }
            else // if the record wasn't previously checked, show the record with checkbox set to false
            {
                allCLIRecordsWrapped.add(new ContractLineItemWrapper(singleLI));
            }
        }
        return allCLIRecordsWrapped;
    }

    // Updates persistent set of data, updates the page view, inserts BLI records, clears persistent set (as we've now inserted records), search again
    // @param : no parameters
    // @return : does not return anything
    public void insertAndSearchAgain()
    {
        updatePersistentSet();
        updatePageView();
        insertBookingLIs();
        clearPersistentSet();
        performSearch();
    }

    // Updates persistent set of data, updates the page view, inserts BLI records, returns us to the booking record
    // @param : no parameters
    // @return : returns a page reference
    public PageReference insertAndReturn()
    {
        updatePersistentSet();
        updatePageView();
        insertBookingLIs();
        
        // if variable== false
        return returnToBooking();
    }

    // Generates a URL back to the parent booking record
    // @param : no parameters
    // @return : returns a page reference
    public pageReference returnToBooking()
    {
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs)
        {
            //System.debug('severity is: ' + msg.getSeverity());
            if( msg.getSeverity() == ApexPages.Severity.ERROR)
            {
                b=true;
            }
        }
        if(!b)
        {
            PageReference pg = new PageReference('/' + ApexPages.currentPage().getParameters().get('bookingId')); 
            pg.setRedirect(true);
            return pg;
        }
        else
        {
            return null;
        }
    }

    // Commits previous page selected records to a persistent set of Ids, and displays the first page of records
    // @param : no parameters
    // @return : does not return anything
    public void first() {
        updatePersistentSet();
        ssc.first();
        updatePageView();
    }

    // Commits previous page selected records to a persistent set of Ids, and displays the last page of records
    // @param : no parameters
    // @return : does not return anything
    public void last() {
        updatePersistentSet();
        ssc.last();
        updatePageView();
    }

    // Commits previous page selected records to a persistent set of Ids, and displays the previous page of records
    // @param : no parameters
    // @return : does not return anything
    public void previous() {
        updatePersistentSet();
        ssc.previous();
        updatePageView();
    }

    // Commits previous page selected records to a persistent set of Ids, and displays the next page of records
    // @param : no parameters
    // @return : does not return anything
    public void next() {
        updatePersistentSet();
        ssc.next();
        updatePageView();
    }

    // Commits previous page selected records to a persistent set of Ids, and displays the next page of records
    // @param : no parameters
    // @return : does not return anything
    public void jumpToPage()
    {
        updatePersistentSet();
        ssc.getPageNumber();
        updatePageView();
    }

    // Commits selected records to a persistent set of Ids
    // @param : no parameters
    // @return : does not return anything
    public void updatePersistentSet()
    {
        System.debug('allCLIRecordsPersistPageChange before ' + allCLIRecordsPersistPageChange);
        System.debug('allCLIRecordsPersistPageChange before size: ' + allCLIRecordsPersistPageChange.size());
        for(ContractLineItemWrapper single : allCLIRecordsWrapped) // go through all clis that are on the current page, just before button press
        {
            Id childId = single.childLI.Id;
            if(allCLIRecordsPersistPageChange.contains(childId)) // if the item is in the set, do a check to see if it is now unchecked and remove it from set
            {
                System.debug('does it contain this?');
                //System.debug('allCLIRecordsPersistPageChange before ' + allCLIRecordsPersistPageChange);
                if(!single.selected)// if single is now unchecked, remove it from the set.
                {
                    allCLIRecordsPersistPageChange.remove(childId);
                }
                System.debug('single is: ' + single);
            }
            if(single.selected && !allCLIRecordsPersistPageChange.contains(childId)) // if it's checked and not yet in the set, add it to the set
            {
                allCLIRecordsPersistPageChange.add(childId);
            }
        }
        System.debug('allCLIRecordsPersistPageChange after ' + allCLIRecordsPersistPageChange);
        System.debug('allCLIRecordsPersistPageChange after size: ' + allCLIRecordsPersistPageChange.size());
    }

    // Clears the persistent set of Ids. (Normally used after records are inserted)
    // @param : no parameters
    // @return : does not return anything
    public void clearPersistentSet()
    {
        allCLIRecordsPersistPageChange.clear();
    }

    // Creates a Booking Line Item record based upon a related Contract Line Item's information
    // @param : singleClI a Contract_line_item__c to map to the new BLI record
    // @return : returns a Booking_Line_Item__c record
    public Booking_Line_Item__c createBookingLI(Contract_line_item__c singleCLI)
    {
        Booking_Line_Item__c bookingLIToReturn = new Booking_Line_Item__c();
        // bookingLIToReturn.Name=singleCLI.Name; // This is an autonumber field now
        bookingLIToReturn.Case__c=parentRecordId;
        bookingLIToReturn.Contract_line_item__c = singleCLI.Id;
        bookingLIToReturn.Product__c = singleCLI.Product__c;
        bookingLIToReturn.Price__c = singleCLI.Line_Item_Price__c;
        bookingLIToReturn.Unit_Type__c = singleCLI.Unit_Type__c;
        bookingLIToReturn.Customer_Product_Invoice_Name__c = singleCLI.Customer_Product_Invoice_Name__c;// customer product invoice
        bookingLIToReturn.Clinical_Indicator__c = singleCLI.Clinical_Indicator__c;// clinical indicator
        bookingLIToReturn.Clinical_Indicator_details__c = singleCLI.Clinical_Indicator_Description__c; // clinical indicator details
        bookingLIToReturn.Chargeable_Overtime__c = singleCLI.Chargeable_Overtime__c;//Chargeable_Overtime__c
        bookingLIToReturn.Addition_Details__c = singleCLI.Additional_Capabilities__c;
        bookingLIToReturn.Uplift_Percentage__c = singleCLI.Uplift_Percentage__c; // Khushal Dave T-457534
        
        if(bookingLineItemRecordType !=null)
        {
            bookingLIToReturn.RecordTypeId = bookingLineItemRecordType.id;
        }
        return bookingLIToReturn;
    }

    // Used for display on VF page (includes checkbox for selection)
    @testVisible private class ContractLineItemWrapper
    {
        public boolean selected {get;set;}
        public Contract_Line_Item__c childLI {get;set;}

        // ContractLineItemWrapper constructor
        public ContractLineItemWrapper(Contract_line_item__c singleLineItem)
        {
            childLI = singleLineItem;
            selected = false;
        }

        // ContractLineItemWrapper constructor
        public ContractLineItemWrapper(Contract_line_item__c singleLineItem, boolean isChecked)
        {
            childLI = singleLineItem;
            selected = isChecked;
        }

        // ContractLineItemWrapper constructor
        public ContractLineItemWrapper()
        {
            childLI = new Contract_Line_Item__c();
            selected = false;
        }
    }
}