BEGIN { tc="MOD_%s_MIRROR" }
{
    tb = $1;

    td = sprintf(tc,tb)
    if (length(td) > 31) {
        print "gt31gt31";
    }
    printf( ta , tb, tb);
    

#CREATE OR ALTER TRIGGER MOD_%s_MIRROR FOR %s
#ACTIVE BEFORE UPDATE POSITION 4 
#AS
#BEGIN
#   IF ( OLD.MIRROR_DATA IS NOT NULL) THEN
#   BEGIN
#      NEW.MIRROR_DATA = NULL;
#   END
#
#END ^
}
