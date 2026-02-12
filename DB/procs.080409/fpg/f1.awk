BEGIN { print "alter trigger update_issn_time inactive;" }
{
printf "%s%s%s%s%s%s%s\n", "update issn set wh_id='", $2,"',issn_status='",$4,"' where ssn_id='",$1,"';"
}
END { print "alter trigger update_issn_time active;" }
