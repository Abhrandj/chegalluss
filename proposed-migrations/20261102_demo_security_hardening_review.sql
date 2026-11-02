-- PROPOSED ONLY. NO DATABASE DEPLOYMENT. Requires coordinated frontend rollout and isolated SQL tests.
BEGIN;
ALTER TABLE public.demo_deposit_movements ADD COLUMN IF NOT EXISTS topup_request_id uuid;
CREATE UNIQUE INDEX IF NOT EXISTS demo_unique_topup_request ON public.demo_deposit_movements(topup_request_id) WHERE topup_request_id IS NOT NULL;
CREATE OR REPLACE FUNCTION public.demo_deposit_action(action text, account uuid, amount numeric DEFAULT NULL::numeric, number text DEFAULT NULL::text, barn uuid DEFAULT NULL::uuid, period uuid DEFAULT NULL::uuid, items jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare uid uuid:=auth.uid(); request_uuid uuid; previous_amount numeric; previous_account uuid; bal numeric; total numeric:=0; row_item jsonb; prod record; b_id uuid; qty numeric; price numeric; debit numeric; pending numeric;
begin
 if uid is null or not exists(select 1 from public.staff_roles where user_id=uid and enabled and role='admin') then raise exception 'ADMIN_REQUIRED';end if;
 if action not in ('topup','bon') then raise exception 'INVALID_ACTION';end if;
 perform 1 from public.demo_deposit_accounts where id=account for update;
 if not found then raise exception 'ACCOUNT_NOT_FOUND';end if;
 select coalesce(sum(amount_idr),0) into bal from public.demo_deposit_movements where account_id=account;
 if action='topup' then
  if number is null or number !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then raise exception 'REQUEST_ID_REQUIRED'; end if;
  request_uuid:=number::uuid;
  select m.account_id,m.amount_idr into previous_account,previous_amount from public.demo_deposit_movements m where m.topup_request_id=request_uuid;
  if found then
   if previous_account<>account or previous_amount<>amount then raise exception 'REQUEST_ID_CONFLICT'; end if;
   return jsonb_build_object('status','OK','duplicate',true,'balance',bal);
  end if;
  if amount is null or amount<=0 or amount<>trunc(amount) or amount>1000000000000 then raise exception 'INVALID_AMOUNT';end if;
  insert into public.demo_deposit_movements(account_id,kind,amount_idr,created_by,topup_request_id) values(account,'topup',amount,uid,request_uuid);
  return jsonb_build_object('status','OK','balance',bal+amount);
 end if;
 if number is null or length(trim(number))<1 or length(number)>80 then raise exception 'INVALID_BON';end if;
 if not exists(select 1 from public.periods where id=period and barn_id=barn and status='open') then raise exception 'PERIOD_MISMATCH';end if;
 if exists(select 1 from public.demo_bons where account_id=account and bon_number=trim(number)) then raise exception 'DUPLICATE_BON';end if;
 if items is null or jsonb_typeof(items)<>'array' or jsonb_array_length(items)<1 or jsonb_array_length(items)>40 then raise exception 'INVALID_ITEMS';end if;
 for row_item in select value from jsonb_array_elements(items) loop
  select id,name into prod from public.products where id=(row_item->>'product_id')::uuid and active;
  if not found then raise exception 'UNKNOWN_PRODUCT';end if;
  qty:=(row_item->>'quantity')::numeric;price:=(row_item->>'unit_price_idr')::numeric;
  if qty is null or price is null or qty<=0 or qty>1000000 or price<0 or price>1000000000 or price<>trunc(price) then raise exception 'INVALID_LINE';end if;
  total:=total+qty*price;
 end loop;
 if total<=0 or total<>trunc(total) or total>1000000000000 then raise exception 'INVALID_TOTAL';end if;
 debit:=least(total,greatest(bal,0));pending:=total-debit;
 insert into public.demo_bons(account_id,barn_id,period_id,bon_number,amount_idr,created_by) values(account,barn,period,trim(number),total,uid) returning id into b_id;
 for row_item in select value from jsonb_array_elements(items) loop
  select id,name into prod from public.products where id=(row_item->>'product_id')::uuid;
  insert into public.demo_bon_lines(bon_id,product_id,product_name,quantity,unit_price_idr) values(b_id,prod.id,prod.name,(row_item->>'quantity')::numeric,(row_item->>'unit_price_idr')::numeric);
 end loop;
 if debit>0 then
  insert into public.demo_deposit_movements(account_id,kind,amount_idr,bon_id,created_by) values(account,'bon',-debit,b_id,uid);
 end if;
 if pending>0 then insert into public.demo_payables(bon_id,account_id,original_idr,remaining_idr) values(b_id,account,pending,pending);end if;
 return jsonb_build_object('status','OK','bon_id',b_id,'bon_total',total,'deposit_used',debit,'payable_created',pending,'balance',bal-debit);
end $function$;
CREATE OR REPLACE FUNCTION public.demo_post_harvest(account uuid, barn uuid, period uuid, reference_no text, sold_on date, weight_kg numeric, price_per_kg_idr numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare uid uuid:=auth.uid(); v_sale uuid; v_total numeric; v_balance numeric; left_to_apply numeric; applied numeric:=0; part numeric; debt record;
begin
 if uid is null or not exists(select 1 from public.staff_roles where user_id=uid and role='admin' and enabled) then raise exception 'ADMIN_REQUIRED';end if;
 perform 1 from public.demo_deposit_accounts where id=account for update;
 if not found then raise exception 'ACCOUNT_NOT_FOUND';end if;
 if not exists(select 1 from public.periods where id=period and barn_id=barn and status='open') then raise exception 'PERIOD_MISMATCH';end if;
 if reference_no is null or length(trim(reference_no))<1 or length(reference_no)>80 then raise exception 'INVALID_REFERENCE';end if;
 if sold_on is null or weight_kg is null or price_per_kg_idr is null or weight_kg<=0 or weight_kg>1000000 or price_per_kg_idr<=0 or price_per_kg_idr>1000000000 or price_per_kg_idr<>trunc(price_per_kg_idr) then raise exception 'INVALID_SALE';end if;
 v_total:=weight_kg*price_per_kg_idr;
 if v_total<>trunc(v_total) or v_total>1000000000000 then raise exception 'INVALID_TOTAL';end if;
 if exists(select 1 from public.demo_harvest_sales s where s.account_id=account and s.reference_no=trim(demo_post_harvest.reference_no)) then raise exception 'DUPLICATE_SALE';end if;
 insert into public.demo_harvest_sales(account_id,barn_id,period_id,reference_no,sold_on,weight_kg,price_per_kg_idr,created_by)
 values(account,barn,period,trim(reference_no),sold_on,weight_kg,price_per_kg_idr,uid) returning id into v_sale;
 left_to_apply:=v_total;
 for debt in select id,remaining_idr from public.demo_payables where account_id=account and remaining_idr>0 order by created_at,id for update loop
   exit when left_to_apply<=0;
   part:=least(left_to_apply,debt.remaining_idr);
   update public.demo_payables set remaining_idr=remaining_idr-part where id=debt.id;
   insert into public.demo_payable_settlements(payable_id,sale_id,amount_idr) values(debt.id,v_sale,part);
   left_to_apply:=left_to_apply-part;applied:=applied+part;
 end loop;
 if left_to_apply>0 then
 insert into public.demo_deposit_movements(account_id,kind,amount_idr,sale_id,created_by) values(account,'harvest_credit',left_to_apply,v_sale,uid);
 end if;
 select coalesce(sum(amount_idr),0) into v_balance from public.demo_deposit_movements where account_id=account;
 return jsonb_build_object('status','OK','sale_id',v_sale,'total',v_total,'paid_payables',applied,'credited_deposit',left_to_apply,'balance',v_balance);
end $function$;
COMMIT;
