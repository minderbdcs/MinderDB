BEGIN { print "alter trigger update_issn_time inactive;" }
{
printf "%s%s%s\n", "update issn set prev_prev_wh_id=prev_wh_id,prev_wh_id=wh_id, wh_id='XX' where ssn_id='",$1,"';"
}
END { print "alter trigger update_issn_time active;" }
