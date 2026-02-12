/* ITEM_CLASS categorises items as COMPANY ASSET, RESALE ITEM NEW, RESALE ITEM USED, ARTIFACT, 
   LOAN ITEM, CONSUMABLE, etc. Notice that this is a control table, not merely a name lookup.
   Currently GN and FL don't envisage ever needing anything but Asset, Product, Object and Loan
   Item, but then Noah didn't envisage the outboard motor either. 
   */
CREATE TABLE ITEM_CLASS(
  ITEM_CLASS_CODE CODE_ONE NOT NULL PRIMARY KEY, 
  DESCRIPTION DESCRIPTION
  ) ^

/* New table for build 403, allows an SSN to be classified in
   multiple item classes. */

CREATE TABLE SSN_ITEM_CLASS (
  SSN_ID SSN_ID NOT NULL,
  ITEM_CLASS_CODE CODE_ONE NOT NULL,
  CLASSIFICATION_DATE DATETIME,
  CLASSIFIED_BY PERSON
)^
/*,
  CONSTRAINT FK_CLASS_SSN FOREIGN KEY (SSN_ID)
    REFERENCES SSN ) ^
*/

create index ssn_item_class_ssn_IX on ssn_item_class(ssn_id,item_class_code)^
