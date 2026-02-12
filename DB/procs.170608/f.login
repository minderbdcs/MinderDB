COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;

CREATE OR ALTER PROCEDURE LOGIN_DEVICE (IP_ADDRESS VARCHAR(40) ,
COMPUTER_NAME VARCHAR(50) ,
USER_ID VARCHAR(10) )
RETURNS (DEVICE_ID CHAR(2) ,
LG_STATUS INTEGER,
LG_MESSAGE VARCHAR(80) )
AS 
 
 
 
DECLARE VARIABLE WK_USER VARCHAR(10);
DECLARE VARIABLE WK_FOUND INTEGER;
DECLARE VARIABLE WK_IP VARCHAR(40);
DECLARE VARIABLE WK_NAME VARCHAR(50);
DECLARE VARIABLE WK_LICENSE VARCHAR(40);
DECLARE VARIABLE WK_LOGIN INTEGER;

BEGIN
        
    /* Update Pick Item Status */
    LG_STATUS = -1;
    WK_FOUND = -1;
    LG_MESSAGE = '';
    DEVICE_ID = NULL;
    /* try the passed ip */
    IF (IP_ADDRESS IS NULL) THEN
    BEGIN
        WK_IP = '';
    END
    ELSE
    BEGIN
        WK_IP = IP_ADDRESS;
    END
    IF (WK_IP > '') THEN
    BEGIN
        FOR SELECT FIRST 1  DEVICE_ID
        FROM SYS_EQUIP
        WHERE IP_ADDRESS = :WK_IP
          AND DEVICE_TYPE IN ('HH','PC')
        INTO :DEVICE_ID
        DO
        BEGIN
            LG_STATUS = 1;
        END
    END
    ELSE
    BEGIN
        LG_MESSAGE = LG_MESSAGE || 'No IP Address Supplied';
    END

    IF (LG_STATUS < 0) THEN
    BEGIN
        /* no ip found */
        /* try the passed name */
        IF (COMPUTER_NAME IS NULL) THEN
        BEGIN
            WK_NAME = '';
        END
        ELSE
        BEGIN
            WK_NAME = COMPUTER_NAME;
        END
        IF (WK_NAME > '') THEN
        BEGIN
            FOR SELECT FIRST 1  DEVICE_ID
            FROM SYS_EQUIP
            WHERE COMPUTER_NAME = :WK_NAME
              AND DEVICE_TYPE IN ('HH','PC')
            INTO :DEVICE_ID
            DO
            BEGIN
                LG_STATUS = 10;
            END
        END
    END

    IF (LG_STATUS < 0) THEN
    BEGIN
        /* no name found */
        /* try using dhcp */
        /* using the logged in devices ip address */
        IF (WK_IP > '') THEN
        BEGIN
            FOR SELECT FIRST 1  SYS_EQUIP.DEVICE_ID
            FROM SYS_EQUIP
            JOIN SESSION ON SESSION.DEVICE_ID = SYS_EQUIP.DEVICE_ID
            WHERE SYS_EQUIP.IP_ADDRESS = 'DHCP'
              AND SYS_EQUIP.DEVICE_TYPE IN ('HH','PC')
              AND SESSION.CODE = 'CURRENT_IP_ADDRESS'
              AND SESSION.DESCRIPTION = :WK_IP
            INTO :DEVICE_ID
            DO
            BEGIN
                LG_STATUS = 24;
            END
        END
    END
   
    IF (LG_STATUS < 0) THEN
    BEGIN
        /* no name found */
        /* try using dhcp */
        IF (WK_IP > '') THEN
        BEGIN
            FOR SELECT FIRST 1  DEVICE_ID
            FROM SYS_EQUIP
            WHERE IP_ADDRESS = 'DHCP'
              AND DEVICE_TYPE IN ('HH','PC')
              AND CURRENT_PERSON IS NULL
              AND CURRENT_LOGGED_ON IS NULL
            INTO :DEVICE_ID
            DO
            BEGIN
                LG_STATUS = 20;
            END
        END
    END
   
    IF (LG_STATUS < 0) THEN
    BEGIN
        /* no device available */
        LG_MESSAGE = LG_MESSAGE || '- No Free Devices Available';
    END
    ELSE
    BEGIN
        /* have a device check user */

        IF (USER_ID IS NULL) THEN
        BEGIN
            WK_USER = '';
        END
        ELSE
        BEGIN
            WK_USER = USER_ID;
        END
        IF (WK_USER IS NULL) THEN
        BEGIN
            LG_MESSAGE = '- No User Supplied - Cannot LogIn'; 
            LG_STATUS = -10;
        END
        ELSE
        BEGIN
            SELECT 1 FROM SYS_USER WHERE USER_ID = :WK_USER INTO :WK_FOUND;
            IF (WK_FOUND = 1) THEN
            BEGIN     
                SELECT COUNT(*) FROM SYS_EQUIP
                WHERE
                    DEVICE_TYPE IN ('HH','PC')
                    AND (NOT(CURRENT_PERSON IS NULL)
                         OR NOT(CURRENT_LOGGED_ON IS NULL))
                    INTO :WK_FOUND;
                IF (WK_FOUND IS NULL) THEN
                BEGIN
                    WK_FOUND = 0;
                END
                SELECT LICENSE_NO FROM CONTROL INTO :WK_LICENSE;
                WK_LOGIN = CHECK_LOGIN( WK_FOUND, WK_LICENSE);
                IF (WK_LOGIN  > 0) THEN
                BEGIN
                    /* update - login user */
                    UPDATE SYS_EQUIP SET CURRENT_PERSON = :WK_USER, CURRENT_LOGGED_ON = 'NOW' ,LAST_PERSON = :WK_USER
                    WHERE DEVICE_ID = :DEVICE_ID;
                    UPDATE SYS_USER SET DEVICE_ID = :DEVICE_ID, LOGIN_DATE = 'NOW'
                    WHERE USER_ID = :WK_USER;
                    LG_MESSAGE = 'Logged Into Device ' || :DEVICE_ID || ' by ' || :WK_USER;
                END
                ELSE
                BEGIN
                    IF (WK_LOGIN = -20) THEN
                    BEGIN
                        LG_MESSAGE = 'Too Many Logged In to Allow Login';
                        LG_STATUS = -20;
                    END                  
                    ELSE
                    BEGIN
                        LG_MESSAGE = 'Invalid License Code';
                        LG_STATUS = -30;
                    END                  
                END
            END
            ELSE
            BEGIN
                LG_MESSAGE = '- No User Supplied - Cannot LogIn'; 
                LG_STATUS = -10;
            END
        END
    END

    SUSPEND;
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
