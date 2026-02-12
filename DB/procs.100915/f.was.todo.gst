if in pick_order
	p_country is null or p_country = ''
	then treat as if it was 'AUSTRALIA'

	for 'AUSTRALIA' or 'AU' in p_country then gst_rate = default_tax_rate from control.
	otherwise use '0' rate.

============================================================================================================================
for pick_item
	if the item is a product or item issn for the item is a product
	then lookup the prod_profile
		if the tax_applicable = 'T'
		then the gst_rate is the default_tax_rate from the control table
		else gst_rate = 0
	if the item is just an SSN then treat as tax_applicable = 'T'

	line_total = CAST(COALESCE( SALE_PRICE, 0.00) * COALESCE(PICK_ORDER_QTY,0) * (1- COALESCE(DISCOUNT, 0.00)/100) as NUMERIC(9,2)) 
	tax_amount = cast(line_total * (1 - coalesce(tax_rate,0)/100) as numeric(9,2))
OK done this
===========================================================================================================================
then in the pick_order
	create a new field sub_total_tax numeric(13,2)
        sub_total_tax = SELECT SUM(LINE_TOTAL * TAX_RATE / 100) FROM PICK_ITEM WHERE PICK_ORDER =  $orderNo;
        sub_total_amount = SELECT SUM(LINE_TOTAL ) FROM PICK_ITEM WHERE PICK_ORDER =  $orderNo;
        taxable_Amount = (FREIGHT + ((sub_Total_Amount + FREIGHT) * ADMIN_FEE_RATE/100) + ADMIN_FEE_AMOUNT + OTHER_NUM1 + OTHER_NUM2);
        tax_Amount = sub_Total_Tax + taxable_Amount * tax_Rate / 100;
        total = sub_Total_Amount + taxable_Amount + tax_Amount;
        due_Amount = total - AMOUNT_PAID;
        freight_Tax_Amount = FREIGHT * tax_Rate / 100;


