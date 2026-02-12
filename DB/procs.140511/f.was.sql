/*
     SELECT RESPONSE_TEXT ADD_TRAN_RESPONSE_V6 (
      'MV',
      'DS000001', 
      '',       -* OBJECT is left empty for TRN_CODE = 'B' Batch print *-
      'DSPS', 'B', 
      'NOW',    
      '|SYS_EQUIP.DEVICE_ID=PB|' , -* REFERENCE  *-  
      1,      -*  QTY - may need to be able pass > 1 if we need say 2 SSCC labels / Carton  *-
      'F',      -* COMPLETE must be 'F' *-
      '',       -* ERROR_TEXT *-
      'MASTER    ',      -* INSTANCE_ID must be 'MASTER    ' *- 
      0,        -* EXPORTED = 0*- 
      '',       -* SUB_LOCN_ID *- 
      'SSSSSSSSS',     -* INPUT_SOURCE *-      
      'BDCS',   
      'XX',   
      '',   
      'PSGROUP',  
      '3333333332',  
      'SO',  
      'GO',
      ''
     )
      ; 

execute procedure add_tran_v6('MV','DS000001','','DSPS','B','NOW','|SYS_EQUIP.DEVICE_ID=PB|',1,'F','','MASTER   ',0,'','SSSSSSSSS','','BDCS','XX','','3333333332','SS','GO','');
*/
/*
Parameters:
WH_ID                             INPUT CHAR(2)
LOCN_ID                           INPUT VARCHAR(10)
OBJECT                            INPUT VARCHAR(30)
TRN_TYPE                          INPUT VARCHAR(4)
TRN_CODE                          INPUT CHAR(1)
TRN_DATE                          INPUT TIMESTAMP
REFERENCE                         INPUT VARCHAR(1024)
QTY                               INPUT INTEGER
COMPLETE                          INPUT CHAR(1)
ERROR_TEXT                        INPUT VARCHAR(255)
INSTANCE_ID                       INPUT CHAR(10)
EXPORTED                          INPUT INTEGER
SUB_LOCN_ID                       INPUT VARCHAR(10)
INPUT_SOURCE                      INPUT VARCHAR(10)
PERSON_ID                         INPUT VARCHAR(10)
DEVICE_ID                         INPUT CHAR(2)
PROD_ID                           INPUT VARCHAR(30)
COMPANY_ID                        INPUT VARCHAR(20)
ORDER_NO                          INPUT VARCHAR(15)
ORDER_TYPE                        INPUT VARCHAR(2)
ORDER_SUB_TYPE                    INPUT VARCHAR(2)
TRN_CLASS                         INPUT VARCHAR(10)
*/   

/*
execute procedure add_tran_v6('MV','DS000001','','DSPS','B','NOW','|SYS_EQUIP.DEVICE_ID=PB|',1,'F','','MASTER   ',0,'','SSSSSSSSS','BDCS','XX','','PSGROUP','3333333335','SS','GO','');
*/
execute procedure add_tran_v6('MV','DS000001','','DSUC','U','NOW','|CPLEASE||',127,'F','','MASTER   ',0,'','SSSSSSSSS','BDCS','XX','','PINPOINT','3333333332','SS','GO','');
execute procedure add_tran_v6('MV','DS000001','','DSUC','U','NOW','|OTHERCARR||',128,'F','','MASTER   ',0,'','SSSSSSSSS','BDCS','XX','','PINPOINT','3333333332','SS','GO','');
execute procedure add_tran_v6('MV','DS000001','','DSUC','U','NOW','|UGLY||',129,'F','','MASTER   ',0,'','SSSSSSSSS','BDCS','XX','','PINPOINT','3333333332','SS','GO','');
execute procedure add_tran_v6('MV','DS000001','','DSUC','U','NOW','|EPARCEL||',130,'F','','MASTER   ',0,'','SSSSSSSSS','BDCS','XX','','PINPOINT','3333333332','SS','GO','');
