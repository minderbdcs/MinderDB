
     SELECT RESPONSE_TEXT ADD_TRAN_RESPONSE_V6 (
      'MV',
      'DS000001', 
      '',       /* OBJECT is left empty for TRN_CODE = 'B' Batch print */
      'DSPS', 'B', 
      'NOW',    
      '|SYS_EQUIP.DEVICE_ID=PB|' , /* REFERENCE  */  
      1,      /*  QTY - may need to be able pass > 1 if we need say 2 SSCC labels / Carton  */
      'F',      /* COMPLETE must be 'F' */
      '',       /* ERROR_TEXT */
      'MASTER    ',      /* INSTANCE_ID must be 'MASTER    ' */ 
      0,        /* EXPORTED = 0*/ 
      '',       /* SUB_LOCN_ID */ 
      'SSSSSSSSS',     /* INPUT_SOURCE */      
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
/*
execute procedure add_tran_v6('MV','DS000001','','DSPS','B','NOW','|SYS_EQUIP.DEVICE_ID=PB|',1,'F','','MASTER   ',0,'','SSSSSSSSS','','BDCS','XX','','3333333335','SS','GO','');
*/
