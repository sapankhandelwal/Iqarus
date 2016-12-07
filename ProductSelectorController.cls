<!-- SKhublall 19/11/15 -->
<apex:page showHeader="true" sidebar="true" tabStyle="Product2" id="prodSel" controller="ProductSelectorController" action="{!performSearch}" title="Product Selector">
<!-- <apex:pageMessages id="pageMessages2"/> -->
    <apex:outputLink value="/{!parentRecordId}" id="returnLink" style="float:left">{!$Label.Back_To_Booking}</apex:outputLink>
    <br/>
    <apex:sectionHeader title="{!$Label.Booking}" subtitle="{!$Label.Product_Selector}"/>
    <style type="text/css">
        .data_field{
            padding-right:20px; 
        }
        span#icon_clear{   
            font-family:verdana;
            cursor:pointer;
            color:#38468F;
            font-weight:bold;
            position:relative;
            height:20px;
            left:-18px;
                
        }
        span#icon_clear:hover{
                color:#ccc;
        }
        ::-ms-clear {
          display: none;
        }

        /* Used for the results list START */
        .clickableHeader {
            cursor: pointer;
            width: 100%;
        }
        .paginatorWrap {
            background: url("/img/alohaSkin/listFooter.png") repeat-x scroll 0 0 #F2F2F2;
            border: 1px solid #EAEAEA;
            background-color: #F3F3F3;
            border-top: 1px solid #FFFFFF;
            padding: 5px;
        }
        
        .noRecordsFound {
            border: 1px solid #D4DADC;
            padding: 4px;
        }
        
        .imageAsc {
            background: url("/img/alohaSkin/sortArrows.png") no-repeat scroll left top transparent;
            height: 8px;
            margin: 0 5px;
            vertical-align: -1px;
            width: 7px;
        }
        
        .imageDesc {
            background: url("/img/alohaSkin/sortArrows.png") no-repeat scroll 0px -12px transparent;
            background-repeat: no-repeat;
            height: 8px;
            margin: 0 5px;
            vertical-align: -1px;
            width: 7px;
        }
        
        .noRowsHeader {
            border: 1px solid rgb(221, 213, 213);
            background-color: #f8f8f8;
            background-image: none;
            font-size: 0.9em;
            font-weight: normal;
            padding: 5px; 
        }
        /* Used for the results list END */

    </style> 
    <apex:form id="frm">
        <script>
          // Character limits of search contact for all fields
          var searchCharacterLimit = 3; 
          //this variable would be used to show total prices of all records
          var totalPrice=0;
        </script>

        <table class="list" width="100%">
            <tr class="dataRow" onmouseout="javascript:hiOff(this)" onmouseover="javascript:hiOn(this)">
                <td class="labelCol" colspan="1" style="width:200px;" ><h2 class="pageDescription">{!$Label.Product_Search}</h2></td>
                <td class="dataCell" colspan="4"><a href="javascript:void(0);" onclick="resetSearchStatus();"> {!$Label.Reset_Search}</a> 
                </td>
            </tr>
            <tr class="dataRow" onmouseout="javascript:hiOff(this)" onmouseover="javascript:hiOn(this)">
                <td class="labelCol" style="width:200px;" > {!$Label.Search_By} </td>
                <td class="dataCell" >{!$ObjectType.Contract_Line_Item__c.Fields.Customer_Product_Invoice_Name__c.Label}</td>
               
            </tr>
            <tr class="dataRow" onmouseout="javascript:hiOff(this)" onmouseover="javascript:hiOn(this)">
                <td class="labelCol" style="width:200px;" > {!$Label.Search_Criteria}: </td>
                <td class="dataCell" >  
                     <apex:outputPanel id="op1">                        
                        <apex:inputText styleClass="data_field" title="Minimum two characters are required" value="{!customerproductNameToSearch}" onkeypress="doSearch(this.id,event);" id="txtPName" style="width:100px;" />
                        <span class="cross_icon" id="icon_clear">x</span>
                    </apex:outputPanel> 
                </td>
                <td class="dataCell">  <apex:inputField value="{!parentCase.Site__c}" onchange="init();"  /></td>
            </tr>
        </table> 

        <input type="hidden" id="oldPName" value="" />

        


        <apex:actionFunction action="{!performSearch}" name="search" reRender="resultBlock,pnlDisplayMsg" status="myStatus" >
            <apex:param name="d1" value="" assignTo="{!customerproductNameToSearch}" />
      </apex:actionFunction>

        <apex:actionFunction name="resetSearchStatus" action="{!resetSearchStatus}" reRender="frm" status="myStatus" >
            <apex:param name="txtobj" value="" assignTo="{!resetTextBoxName}" />
        </apex:actionFunction>

        <!-- Page Messages will be displayed here -->
        <apex:outputPanel id="pnlDisplayMsg">
            <!-- <apex:pageMessages /> -->
        </apex:outputPanel>

        <!-- This is where the results will be displayed -->
        <apex:outputPanel id="resultBlock" >
        <apex:pageMessages id="pageMessages"/>
            <apex:pageBlock id="pageBlock" title="{!$Label.Products}">
            <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js' ></script>
                <script type="text/javascript"> // jQuery is used for correct checkbox rendering
                //intializing totalPrice to 0 once search button is clicked
                    totalPrice=0;
                    $j=jQuery.noConflict();
                    $j(document).ready(function(){
                      $j('.headerCheckbox').click(function(){
                          totalPrice=0;
                      var selAll = this.checked;
                      $j('.checkbox').each(function(){
                      this.checked = selAll;
                       var totalPriceForSingleRecord=Number(document.getElementById('hi-'+this.id).value);
                       if(this.checked)
                       {
                          totalPrice+=totalPriceForSingleRecord;
                              
                       }
                       else
                       {
                            totalPrice=0;
                            
                       }
                       document.getElementById('totalPrice').innerHTML='<B>{!$Label.TotalPrice}</B> '+totalPrice;
                      });
                      if(!this.checked)
                       document.getElementById('totalPrice').innerHTML='';
                       //else
                       
                          
                      });

                      $j('.checkbox').click(function(){
                          //this hidden value store total price for each row
                       var totalPriceForSingleRecord=Number(document.getElementById('hi-'+this.id).value);
                           if(this.checked)
                          { 
                          totalPrice+=totalPriceForSingleRecord;
                          }else
                          {
                           totalPrice-=totalPriceForSingleRecord;                          
                          }
                        if($j('.checkbox:checked').length == $j('.checkbox').length){
                           
                            
                            $j('.headerCheckbox').prop('checked',true);
                        }else{
                            $j('.headerCheckbox').prop('checked',false);
                       
                            
                            
                        }
                    
                      document.getElementById('totalPrice').innerHTML='<B>{!$Label.TotalPrice}</B> '+totalPrice;
                      });
                    });

                    $j('.headerCheckbox').each(function ()// go through the header checkbox.
                    {
                        var allSel = true; //true, unless 1 or more checkboxes are false
                        $j('.checkbox').each(function()
                        {
                            if(!this.checked)
                            {
                                allSel=false;
                            }
                        });
                        if(!allSel)
                        {
                          document.getElementById('totalPrice').innerHTML='';
                         
                        }
                        this.checked=allSel;
                    
                        
                    });
                </script>
                <apex:pageBlockButtons location="top" >

                   <apex:actionStatus style="float:left;" stopText="" id="myStatus">
                    <apex:facet name="start">
                        <img src="/img/loading.gif" />
                    </apex:facet>
                 </apex:actionStatus>      
              
                </apex:pageBlockButtons>

                <!-- This is our results pageBlock no records returned START -->
                <apex:outputPanel rendered="{!OR(ISNULL(allCLIRecordsWrapped),allCLIRecordsWrapped.size == 0)}" >
                    <div class="noRowsHeader">{!$Label.No_records_to_display}</div>
                </apex:outputPanel>
                <!-- This is our results pageBlock no records returned END -->

                <!-- This is our results pageBlock START -->
                <apex:pageBlockTable value="{!allCLIRecordsWrapped}" var="r" rendered="{!AND(NOT(ISNULL(allCLIRecordsWrapped)),allCLIRecordsWrapped.size > 0)}">
                    <apex:column >
                        <apex:facet name="header">
                            <apex:inputCheckbox id="select_all" styleClass="headerCheckbox"/>
                        </apex:facet>
                        <input type="Checkbox" value="{!r.selected}"  id="{!r.childLI.id}" class="checkbox"/>
                        <input type="Hidden" id="hi-{!r.childLI.id}" value="{!r.childLI.Line_Item_Price__c*r.childLI.Quantity_contracted__c}"/>
                    </apex:column>
<!--                <apex:column headerValue="{!$Label.Product}" value="{!r.childLI.Product__c}"/> -->
                   <apex:column headerValue="{!$ObjectType.Contract_Line_Item__c.Fields.Customer_Product_Invoice_Name__c.Label}" value="{!r.childLI.Customer_Product_Invoice_Name__c}"/>
                    <apex:column headerValue="{!$Label.CLI_Name}" value="{!r.childLI.Name}"/>
                    <apex:column headerValue="{!$Label.Quantity}" value="{!r.childLI.Quantity_contracted__c}"/>
                    <apex:column headerValue="{!$Label.Product_Family}" value="{!r.childLI.Product_Family__c}"/>
                    <apex:column headerValue="{!$Label.Line_Item_Price}" value="{!r.childLI.Line_Item_Price__c}"/>
                    <apex:column headerValue="{!$Label.Clinical_Indicator}" value="{!r.childLI.Clinical_Indicator__c}"/>
                    <apex:column headerValue="{!$Label.Clinical_Indicator_Description}" value="{!r.childLI.Clinical_Indicator_Description__c}"/>
                    
                </apex:pageBlockTable>
                <apex:outputPanel layout="block" styleClass="paginatorWrap" rendered="{!AND(allCLIRecordsWrapped.size > 0, NOT(ISNULL(ssc.pageSize)))}">
                    <div class="paginator">
                        <span class="left" id="totalPrice">
                            
                      </span>                        
                        <span class="prevNextLinks">
                      
                            <span class="prevNext">
                                <!-- Show first button if page set has previous page-->
                                <apex:commandLink value="" action="{!first}" rendered="{!ssc.pageNumber != 1}" rerender="pageBlock" title="First" status="myStatus">
                                    <img class="first" src="/s.gif" alt="" />
                                </apex:commandLink>
                                
                                <apex:outputPanel rendered="{!NOT(ssc.hasPrevious)}">
                                    <img class="firstoff" src="/s.gif" alt="" />
                                </apex:outputPanel>
                            </span>
                            
                            <!-- Previous Button -->
                            <span class="prevNext">
                               
                                <apex:commandLink value="" action="{!previous}" rendered="{!ssc.hasPrevious}" rerender="pageBlock" status="myStatus">
                                    <img class="prev" src="/s.gif" alt="" />{!$Label.Previous}
                                </apex:commandLink>
                                
                               
                                <apex:outputPanel rendered="{!NOT(ssc.hasPrevious)}">
                                    <img class="prevoff" src="/s.gif" alt="" />{!$Label.Previous}
                                </apex:outputPanel>
                            </span>
                            
                          
                            <span class="prevNext">
                                <!-- Show next button if page set has next -->
                                <apex:commandLink value="" action="{!next}" rendered="{!ssc.hasNext}" rerender="pageBlock" status="myStatus">
                                    {!$Label.Next}<img class="next" alt="Next" title="Next" src="/s.gif" />
                                </apex:commandLink>
                               
                                <apex:outputPanel rendered="{!NOT(ssc.hasNext)}">
                                    {!$Label.Next}<img class="nextOff" alt="Next" title="Next" src="/s.gif" />
                                </apex:outputPanel>
                            </span>
                            
                            <!-- Last Button -->
                            <span class="prevNext"> 
                                <!-- Show last button if page set has next -->
                                <apex:commandLink value="" action="{!last}" rendered="{!ssc.hasNext}" title="Last" rerender="pageBlock" status="myStatus">
                                    <img class="last" src="/s.gif" alt="" />
                                </apex:commandLink>
                                
                                <!-- Show disabled last button if page set has no next -->
                                <apex:outputPanel rendered="{!NOT(ssc.hasNext)}">
                                    <img class="lastoff" src="/s.gif" alt="" />
                                </apex:outputPanel>
                            </span>
                            
                        </span>

                        <span class="right">
                            {!$Label.Page}&nbsp;
                            
                            <apex:inputText value="{!ssc.pageNumber}" styleClass="pageInput"  onkeypress="return isNumber(event,this)">
                                <apex:actionSupport event="onchange" rerender="pageBlock" status="myStatus" action="{!jumpToPage}"/>
                            </apex:inputText>
                            
                             {!$Label.Of} {!CEILING(ssc.ResultSize / ssc.pageSize)} 
               
                        </span>

                    </div>
                </apex:outputPanel>
                <apex:pageBlockButtons rendered="{!AND(NOT(ISNULL(allCLIRecordsWrapped)),allCLIRecordsWrapped.size > 0)}" location="bottom">
                    <apex:commandButton action="{!insertAndSearchAgain}" value="{!$Label.Save_More}" id="createBookingLIs" reRender="pageBlock, pageMessages" status="myStatus"/>
                    <apex:commandButton action="{!insertAndReturn}" value="{!$Label.Save_Go_Back_to_Booking}" id="createAndReturn"/>
                </apex:pageBlockButtons>

                <!-- This is our results pageBlock END -->

            </apex:pageBlock>

        </apex:outputPanel>
    </apex:form>

    <script>
        $j=jQuery.noConflict();
        $j('.data_field').each(function() {
            if ($j(this).val().length <= 0) {
                $j(this).next().fadeOut(300);
            }
            else {
                $j('.cross_icon').fadeIn(300);
            }
        });
        
        $j('.data_field').on('keyup', function() {
            if ($j(this).val().length > 0) {
                $j(this).next().fadeIn(300);
            }
            else{
                $j(this).next().fadeOut(300);
            }
        });

        $j('.cross_icon').on('click',function()
        {
               if(this.parentElement.id == 'prodSel:frm:op1'){               
                  resetSearchStatus('1');
              }
        }); 

        function validateForSearch(ctrl)
        {   
           setTimeout("validateForSearch2()",1000);
        }

        function doSearch(ctrl,e)
        {
            var keycode = (e.keyCode ? e.keyCode : e.which); 
                if(keycode == '13'){   
                    e.preventDefault ? e.preventDefault() : e.returnValue = false;

                    if(document.getElementById(ctrl).value==''){
                        return false;
                    }      
                    validateForSearch2();
                    return false;
                }
        }  

        //Function to trim string
        function fncTrim(value)
        {
            return value.replace(/^\s*/, "").replace(/\s*$/, "");
        }

        function validateForSearch2()
        {
            try{
              //  var txtProdName = document.getElementById("prodSel:frm:txtPName").value;
                var txtProdName=$j( "input[id$='txtPName']").val();

                if(fncTrim(txtProdName ) != '')
                {   
                    var oldProdName = document.getElementById('oldPName').value;
                    
                    document.getElementById('oldPName').value = oldProdName;
                     
                    var isChange = 'No';
                           
                    if(fncTrim(txtProdName).length >= searchCharacterLimit && txtProdName != oldProdName){
                       isChange = 'Yes';
                    }

                    if(isChange == 'Yes' ){                     
                        search(txtProdName); 
                    }    
                }          
            }
            catch(e){         
                alert(e);
            }     
        }

        // This function is used for the paginator with the results
        function isNumber(evt,obj)
        {
            evt = (evt) ? evt : window.event;
            var charCode = (evt.which) ? evt.which : evt.keyCode;
            if(charCode == 13){
                
                obj.onchange();
                return false;
            }
            if (charCode > 31 && (charCode < 48 || charCode > 57)) {
                return false;
            }
            return true;
        }
    </script>
</apex:page>