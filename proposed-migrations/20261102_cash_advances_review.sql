-- CHEGALLUSS CONTROL: proposed migration, NOT executed on production.
-- Requires review of existing auth/RLS and test on isolated environment first.
alter table public.operational_cash_movements
  add column if not exists request_id uuid unique,
  add column if not exists actor_id uuid references auth.users(id);
alter table public.employee_advances
  add column if not exists request_id uuid unique,
  add column if not exists actor_id uuid references auth.users(id);

-- No direct writes from the browser; all writes go through validated RPC.
revoke insert, update, delete on public.operational_cash_movements from anon, authenticated;
revoke insert, update, delete on public.employee_advances from anon, authenticated;

create or replace function public.chegalluss_post_cash(
  p_request uuid, p_day date, p_barn uuid, p_period uuid,
  p_category text, p_description text, p_amount bigint
) returns uuid language plpgsql security definer
set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_id uuid;
begin
  if v_actor is null or not exists(
    select 1 from public.staff_roles
    where user_id=v_actor and enabled and role='admin'
  ) then raise exception 'ADMIN_REQUIRED'; end if;
  if p_request is null or p_day is null or p_barn is null or
     p_amount is null or p_amount<=0 or p_amount>10000000000 or
     p_category not in ('Sewa kandang','Sekam','Transport','Listrik','Gaji','Biaya lain') or
     length(trim(coalesce(p_description,''))) < 3 then
    raise exception 'INVALID_CASH_INPUT'; end if;
  if not exists (select 1 from public.barns where id=p_barn and active)
    then raise exception 'INVALID_BARN'; end if;
  if p_period is not null and not exists(
    select 1 from public.periods where id=p_period and barn_id=p_barn
  ) then raise exception 'PERIOD_BARN_MISMATCH'; end if;
  insert into public.operational_cash_movements
    (request_id,actor_id,occurred_on,barn_id,period_id,category,description,amount_idr)
  values (p_request,v_actor,p_day,p_barn,p_period,p_category,trim(p_description),-p_amount)
  on conflict (request_id) do nothing returning id into v_id;
  if v_id is null then raise exception 'DUPLICATE_REQUEST'; end if;
  return v_id;
end $$;

create or replace function public.chegalluss_post_advance(
  p_request uuid, p_day date, p_employee text, p_kind text,
  p_amount bigint
) returns uuid language plpgsql security definer
set search_path = ''
as $$
declare v_actor uuid:=auth.uid(); v_id uuid; v_balance numeric;
begin
  if v_actor is null or not exists(
    select 1 from public.staff_roles
    where user_id=v_actor and enabled and role='admin'
  ) then raise exception 'ADMIN_REQUIRED'; end if;
  if p_request is null or p_day is null or
     length(trim(coalesce(p_employee,'')))<2 or
     length(p_employee)>120 or
     p_kind not in ('advance','repayment','payroll_deduction') or
     p_amount is null or p_amount<=0 or p_amount>10000000000
     then raise exception 'INVALID_ADVANCE_INPUT'; end if;
  -- Serialize movements for the same named employee to guard against over-repayment.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(lower(trim(p_employee)),0));
  if exists (select 1 from public.employee_advances where request_id=p_request)
     then raise exception 'DUPLICATE_REQUEST'; end if;
  select coalesce(sum(case when kind='advance' then amount_idr
     else -amount_idr end),0) into v_balance
     from public.employee_advances
     where lower(trim(employee_name))=lower(trim(p_employee));
  if p_kind <> 'advance' and v_balance < p_amount
     then raise exception 'ADVANCE_EXCEEDS_BALANCE'; end if;
  insert into public.employee_advances
    (request_id,actor_id,employee_name,occurred_on,kind,amount_idr,notes)
  values (p_request,v_actor,trim(p_employee),p_day,p_kind,p_amount,'Input via Admin')
  returning id into v_id;
  -- Cash impact: advance disbursement negative, cash repayment positive.
  -- Payroll deduction must NOT produce a cash movement.
  if p_kind <> 'payroll_deduction' then
    insert into public.operational_cash_movements
      (request_id,actor_id,occurred_on,barn_id,period_id,description,category,amount_idr)
    values (p_request,v_actor,p_day,null,null,
      'Kasbon: '||trim(p_employee), 'Kasbon',
      case when p_kind='advance' then -p_amount else p_amount end);
  end if;
  return v_id;
end $$;

revoke all on function public.chegalluss_post_cash(uuid,date,uuid,uuid,text,text,bigint) from public, anon;
revoke all on function public.chegalluss_post_advance(uuid,date,text,text,bigint) from public, anon;
grant execute on function public.chegalluss_post_cash(uuid,date,uuid,uuid,text,text,bigint) to authenticated;
grant execute on function public.chegalluss_post_advance(uuid,date,text,text,bigint) to authenticated;
