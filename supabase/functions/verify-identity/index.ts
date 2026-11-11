// verify-identity: compares the face on a user's CNIC front photo with their
// live selfie using AWS Rekognition, then approves or rejects the application.
//
//   POST { "kind": "worker" | "contractor" }   (signed-in user's JWT required)
//   -> { status: "approved" | "rejected" | "pending", score?: number, code?: string }
//
// Secrets (Supabase > Edge Functions > Secrets):
//   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
// SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided
// by Supabase automatically.

import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  CompareFacesCommand,
  DetectTextCommand,
  RekognitionClient,
} from 'npm:@aws-sdk/client-rekognition@3';

/** Similarity (0-100) at or above which an account is approved automatically. */
const APPROVE_AT = 80;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

// Shown in the app when it has no translation for the code.
const reasons: Record<string, string> = {
  face_mismatch: 'The face on your CNIC does not match your selfie. Please retake both photos in good light.',
  no_face_cnic: 'We could not find the photo on your CNIC. Retake the front of your CNIC so the photo is sharp and not covered by glare.',
  no_face_selfie: 'We could not see your face in the selfie. Take a clear selfie facing the camera.',
  multiple_faces: 'Your selfie must show only your face. Do not hold your CNIC or include other people.',
};

const tables = {
  worker: { table: 'cnic_verifications', id: 'worker_id' },
  contractor: { table: 'contractor_verifications', id: 'contractor_id' },
} as const;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const url = Deno.env.get('SUPABASE_URL')!;
  const authHeader = req.headers.get('Authorization') ?? '';
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: auth } = await userClient.auth.getUser();
  const user = auth?.user;
  if (!user) return json({ error: 'Please sign in again.' }, 401);

  let kind: keyof typeof tables = 'worker';
  try {
    const body = await req.json();
    if (body?.kind === 'contractor') kind = 'contractor';
  } catch {
    // An empty body means a worker check.
  }
  const { table, id } = tables[kind];

  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false },
  });

  const { data: row, error: rowError } = await admin
    .from(table)
    .select('cnic_number, front_path, selfie_path, status, face_match_score, rejection_code, face_checked_at')
    .eq(id, user.id)
    .maybeSingle();
  if (rowError) return json({ error: 'Could not load your application.' }, 500);
  if (!row) return json({ error: 'Please submit your documents first.' }, 404);

  // Each submission is checked once. A new submission resets these fields.
  if (row.status !== 'pending' || row.face_checked_at) {
    return json({ status: row.status, score: row.face_match_score, code: row.rejection_code });
  }

  const region = Deno.env.get('AWS_REGION');
  const accessKeyId = Deno.env.get('AWS_ACCESS_KEY_ID');
  const secretAccessKey = Deno.env.get('AWS_SECRET_ACCESS_KEY');
  if (!region || !accessKeyId || !secretAccessKey) {
    // Not set up yet: the application stays pending for manual review.
    return json({ status: 'pending', code: 'not_configured' });
  }

  const download = async (path: string) => {
    const { data, error } = await admin.storage.from('cnic-documents').download(path);
    if (error || !data) throw new Error(`download failed: ${path}`);
    return new Uint8Array(await data.arrayBuffer());
  };

  let front: Uint8Array;
  let selfie: Uint8Array;
  try {
    [front, selfie] = await Promise.all([download(row.front_path), download(row.selfie_path)]);
  } catch (e) {
    console.error(e);
    return json({ status: 'pending', code: 'temporary_error' }, 502);
  }

  const rekognition = new RekognitionClient({
    region,
    credentials: { accessKeyId, secretAccessKey },
  });

  let score = 0;
  let code: string | null = null;
  try {
    const result = await rekognition.send(
      new CompareFacesCommand({
        SourceImage: { Bytes: front },
        TargetImage: { Bytes: selfie },
        SimilarityThreshold: 0,
        QualityFilter: 'AUTO',
      }),
    );
    const matches = result.FaceMatches ?? [];
    const facesInSelfie = matches.length + (result.UnmatchedFaces?.length ?? 0);
    if (facesInSelfie === 0) {
      code = 'no_face_selfie';
    } else if (facesInSelfie > 1) {
      // A CNIC held up to the camera would match itself, so it is refused.
      code = 'multiple_faces';
    } else {
      score = Math.max(0, ...matches.map((m) => m.Similarity ?? 0));
      if (score < APPROVE_AT) code = 'face_mismatch';
    }
  } catch (e) {
    const name = (e as { name?: string }).name;
    if (name === 'InvalidParameterException') {
      // Rekognition raises this when the source image (the CNIC) has no face.
      code = 'no_face_cnic';
    } else {
      console.error('Rekognition error', e);
      return json({ status: 'pending', code: 'temporary_error' }, 502);
    }
  }

  // Best effort: does the CNIC number typed in the app appear on the card?
  // Recorded for reviewers; it does not block approval because glare often
  // hides a digit or two.
  let numberMatched: boolean | null = null;
  try {
    const text = await rekognition.send(new DetectTextCommand({ Image: { Bytes: front } }));
    const digits = (text.TextDetections ?? [])
      .filter((t) => t.Type === 'LINE')
      .map((t) => (t.DetectedText ?? '').replace(/\D/g, ''))
      .join(' ');
    numberMatched = digits.includes(String(row.cnic_number).replace(/\D/g, ''));
  } catch (e) {
    console.error('DetectText error', e);
  }

  const status = code ? 'rejected' : 'approved';
  const { error: updateError } = await admin
    .from(table)
    .update({
      status,
      face_match_score: Math.round(score * 100) / 100,
      rejection_code: code,
      rejection_reason: code ? reasons[code] : null,
      cnic_number_matched: numberMatched,
      face_checked_at: new Date().toISOString(),
    })
    .eq(id, user.id)
    .eq('status', 'pending');
  if (updateError) {
    console.error(updateError);
    return json({ status: 'pending', code: 'temporary_error' }, 500);
  }

  return json({ status, score: Math.round(score * 10) / 10, code });
});
