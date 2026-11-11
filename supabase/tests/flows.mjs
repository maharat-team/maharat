const C = '11111111-1111-1111-1111-111111111111'; // customer
const W = '22222222-2222-2222-2222-222222222222'; // worker
const K = '33333333-3333-3333-3333-333333333333'; // contractor
const X = '44444444-4444-4444-4444-444444444444'; // unrelated worker (same trade)

let failures = 0;
function check(name, cond) {
  console.log(cond ? '  pass' : '  FAIL', name);
  if (!cond) failures++;
}

export default async function (db) {
  const as = async (uid, sql, params) => {
    await db.exec(`reset role; set role authenticated; select set_config('request.jwt.claim.sub', '${uid}', false);`);
    try {
      return await db.query(sql, params);
    } finally {
      await db.exec('reset role;');
    }
  };
  const fails = async (uid, sql, params) => {
    try { await as(uid, sql, params); return null; } catch (e) { return e.message; }
  };
  const admin = (sql, params) => db.query(sql, params);

  for (const id of [C, W, K, X]) await admin(`insert into auth.users (id) values ($1)`, [id]);
  check('profiles auto-created', (await admin('select count(*)::int n from profiles')).rows[0].n === 4);

  for (const [id, name, phone] of [[C, 'Ahmed', '+923001111111'], [W, 'Tariq', '+923002222222'], [K, 'Kashif', '+923003333333'], [X, 'Zubair', '+923004444444']]) {
    await as(id, `update profiles set full_name=$1, phone=$2, neighbourhood='Model Town A', lat=29.39, lng=71.68 where id=auth.uid()`, [name, phone]);
  }

  // Workers apply; a face check (service role) approves them.
  for (const [id, phone, cnic] of [[W, '+923002222222', '31202-1111111-1'], [X, '+923004444444', '31202-2222222-2']]) {
    await as(id, `select submit_worker_application('Electrician',$1,'bio',5,300,array['Model Town A'],$2,$3||'/f.jpg',$3||'/b.jpg',$3||'/s.jpg',29.3912,71.6834)`, [phone, cnic, id]);
  }
  const base = (await admin(`select base_lat from workers where id=$1`, [W])).rows[0].base_lat;
  check('worker base location rounded to 2 decimals', base === 29.39);
  check('resubmitting while pending is refused', (await fails(W, `select submit_worker_application('Electrician','+923002222222','b',5,300,array['Model Town A'],'31202-1111111-1',$1||'/f.jpg',$1||'/b.jpg',$1||'/s.jpg')`, [W]))?.includes('already been submitted'));
  await admin(`update cnic_verifications set status='approved', face_match_score=91.5 where worker_id in ($1,$2)`, [W, X]);
  check('approval flows to workers table', (await admin(`select count(*)::int n from workers where verification_status='approved'`)).rows[0].n === 2);
  check('worker reads own face score', (await as(W, `select face_match_score from cnic_verifications where worker_id=auth.uid()`)).rows[0].face_match_score == 91.5);
  check('cnic number not readable by client', (await fails(W, `select cnic_number from cnic_verifications`))?.includes('permission denied'));

  // Rejected → resubmission allowed, attempt limit enforced.
  await admin(`update cnic_verifications set status='rejected', rejection_code='face_mismatch' where worker_id=$1`, [X]);
  check('rejection hides worker from directory', (await as(C, `select count(*)::int n from workers`)).rows[0].n === 1);
  for (let i = 0; i < 4; i++) {
    await as(X, `select submit_worker_application('Electrician','+923004444444','b',5,300,array['Model Town A'],'31202-2222222-2',$1||'/f.jpg',$1||'/b.jpg',$1||'/s.jpg')`, [X]);
    await admin(`update cnic_verifications set status='rejected' where worker_id=$1`, [X]);
  }
  check('6th attempt in a day is refused', (await fails(X, `select submit_worker_application('Electrician','+923004444444','b',5,300,array['Model Town A'],'31202-2222222-2',$1||'/f.jpg',$1||'/b.jpg',$1||'/s.jpg')`, [X]))?.includes('Too many attempts'));
  await admin(`update cnic_verifications set status='approved' where worker_id=$1`, [X]);

  // Contractor applies and is approved.
  await as(K, `select submit_contractor_application('Kashif Electric Works','+923003333333',array['Electrician','Plumber'],'Shop bio',array['Model Town A','Satellite Town'],'Shop 4, Circular Road',29.395,71.683,$1||'/shop.jpg','31202-3333333-3',$1||'/f.jpg',$1||'/b.jpg',$1||'/s.jpg')`, [K]);
  check('contractor role set', (await admin(`select active_role::text r from profiles where id=$1`, [K])).rows[0].r === 'contractor');
  check('pending contractor hidden from customers', (await as(C, `select count(*)::int n from contractors`)).rows[0].n === 0);
  check('inviting before approval is refused', (await fails(K, `select invite_team_member('+923002222222')`))?.includes('must be verified'));
  await admin(`update contractor_verifications set status='approved', face_match_score=88 where contractor_id=$1`, [K]);
  check('approved contractor visible', (await as(C, `select business_name from contractors`)).rows[0]?.business_name === 'Kashif Electric Works');

  // Team
  check('invite unknown number refused', (await fails(K, `select invite_team_member('+923009999999')`))?.includes('No verified worker'));
  const invited = await as(K, `select invite_team_member('+923002222222') as n`);
  check('invite returns worker name', invited.rows[0].n === 'Tariq');
  check('customer cannot see pending invites', (await as(C, `select count(*)::int n from contractor_members`)).rows[0].n === 0);
  check('worker sees invite', (await as(W, `select status::text s from contractor_members`)).rows[0]?.s === 'invited');
  await as(W, `select respond_to_team_invite($1, true)`, [K]);
  check('customer sees active team member', (await as(C, `select count(*)::int n from contractor_members`)).rows[0].n === 1);

  // Order to contractor
  const orderId = (await as(C, `select post_job('Electrician','Rewire kitchen','Model Town A','today',array[]::text[],$1,29.3923456,71.6812345,'House 12, Street 3') as id`, [K])).rows[0].id;
  const order = (await admin(`select * from job_requests where id=$1`, [orderId])).rows[0];
  check('order is pending for contractor', order.contractor_status === 'pending');
  check('approx location rounded', order.approx_lat === 29.39);
  check('customer phone attached to contractor order', order.customer_phone === '+923001111111');
  check('unrelated worker cannot see contractor order', (await as(X, `select count(*)::int n from job_requests where id=$1`, [orderId])).rows[0].n === 0);
  check('team worker cannot see order before assignment', (await as(W, `select count(*)::int n from job_requests where id=$1`, [orderId])).rows[0].n === 0);
  check('contractor sees order', (await as(K, `select count(*)::int n from job_requests where id=$1`, [orderId])).rows[0].n === 1);
  check('contractor sees exact location', (await as(K, `select address_details a from job_locations where job_id=$1`, [orderId])).rows[0]?.a === 'House 12, Street 3');
  check('worker cannot express interest in contractor order', !!(await fails(X, `insert into job_interests (job_id, worker_id) values ($1, auth.uid())`, [orderId])));
  check('assign before accept refused', (await fails(K, `select assign_order_team($1, array[$2]::uuid[])`, [orderId, W]))?.includes('Accept this order'));
  check('completing before assignment refused', (await fails(C, `update job_requests set status='completed' where id=$1`, [orderId]))?.includes('not assigned'));
  await as(K, `select respond_to_order($1, true)`, [orderId]);
  check('assigning non-member refused', (await fails(K, `select assign_order_team($1, array[$2]::uuid[])`, [orderId, X]))?.includes('Only members'));
  await as(K, `select assign_order_team($1, array[$2]::uuid[])`, [orderId, W]);
  check('assigned worker sees order', (await as(W, `select customer_phone from job_requests where id=$1`, [orderId])).rows[0]?.customer_phone === '+923001111111');
  check('assigned worker sees exact location', (await as(W, `select count(*)::int n from job_locations where job_id=$1`, [orderId])).rows[0].n === 1);
  check('customer sees assignment', (await as(C, `select count(*)::int n from job_assignments where job_id=$1`, [orderId])).rows[0].n === 1);
  check('contractor cannot edit job status directly', !!(await fails(K, `update job_requests set status='closed' where id=$1`, [orderId])) || (await admin(`select status::text s from job_requests where id=$1`, [orderId])).rows[0].s === 'active');
  await as(C, `update job_requests set status='completed' where id=$1`, [orderId]);
  check('contractor job count incremented', (await admin(`select completed_jobs_count n from contractors where id=$1`, [K])).rows[0].n === 1);
  check('assigned worker job count incremented', (await admin(`select completed_jobs_count n from workers where id=$1`, [W])).rows[0].n === 1);
  await as(C, `insert into reviews (job_id, contractor_id, rating, comment) values ($1, $2, 4, 'Good team')`, [orderId, K]);
  check('contractor rating updated', (await admin(`select rating_avg::float r, review_count n from contractors where id=$1`, [K])).rows[0].r === 4);
  check('cannot review worker on contractor job', !!(await fails(C, `insert into reviews (job_id, worker_id, rating) values ($1, $2, 5)`, [orderId, W])));

  // Decline flow
  const order2 = (await as(C, `select post_job('Plumber','Leak','Model Town A','today',array[]::text[],$1) as id`, [K])).rows[0].id;
  await as(K, `select respond_to_order($1, false)`, [order2]);
  const o2 = (await admin(`select status::text s, contractor_status::text c from job_requests where id=$1`, [order2])).rows[0];
  check('declined order is closed', o2.s === 'closed' && o2.c === 'declined');

  // Broadcast job: location hidden until interest.
  const job = (await as(C, `select post_job('Electrician','Fan repair','Model Town A','tomorrow',array[]::text[],null,29.3911,71.6822,'Gate 2') as id`)).rows[0].id;
  check('broadcast job visible to trade worker', (await as(X, `select count(*)::int n from job_requests where id=$1`, [job])).rows[0].n === 1);
  check('broadcast job has no customer phone', (await admin(`select customer_phone from job_requests where id=$1`, [job])).rows[0].customer_phone === null);
  check('exact location hidden before interest', (await as(X, `select count(*)::int n from job_locations where job_id=$1`, [job])).rows[0].n === 0);
  await as(X, `insert into job_interests (job_id, worker_id) values ($1, auth.uid())`, [job]);
  check('exact location shown after interest', (await as(X, `select count(*)::int n from job_locations where job_id=$1`, [job])).rows[0].n === 1);
  await as(C, `update job_requests set status='completed', assigned_worker_id=$2 where id=$1`, [job, X]);
  await as(C, `insert into reviews (job_id, worker_id, rating) values ($1, $2, 5)`, [job, X]);
  check('worker rating still works', (await admin(`select rating_avg::float r from workers where id=$1`, [X])).rows[0].r === 5);

  // Team removal and account deletion
  await as(W, `select remove_team_membership($1, auth.uid())`, [K]);
  check('worker can leave team', (await admin(`select count(*)::int n from contractor_members`)).rows[0].n === 0);
  await as(X, `select delete_my_account()`);
  check('account deletion cascades', (await admin(`select count(*)::int n from workers where id=$1`, [X])).rows[0].n === 0);

  console.log(failures ? `\n${failures} FAILED` : '\nall flows passed');
}
