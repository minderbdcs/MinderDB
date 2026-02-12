{
	#print NF
	for  (i=1;i < NF;i++)
	{
		#print i
		#print $i
		if ($i == "ON")
		{
			
			j=i+1
			if ($j == "PROCEDURE")
			{
				k = j+1	
				print $j,$k
			}
			else
			{
				print $j
			}
		}
	}
}
