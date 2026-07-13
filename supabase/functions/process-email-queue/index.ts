/**
 * CourtFlow — process-email-queue Edge Function
 *
 * Reads pending email_queue rows and sends confirmation emails.
 * Capped at 2 emails per invocation to stay under Supabase's free-tier
 * rate limit of 3 emails/hour. Scheduled every 20 min via pg_cron.
 *
 * Environment variables (set in Supabase Dashboard → Edge Functions → Secrets):
 *   SUPABASE_URL          — your project URL (auto-injected)
 *   SUPABASE_SERVICE_ROLE_KEY — service role key (auto-injected)
 *   RESEND_API_KEY        — from resend.com (free: 100 emails/day)
 *   APP_URL               — https://courtflowapp.pages.dev (or localhost:3000)
 */

import { createClient } from "jsr:@supabase/supabase-js@2";

const BATCH_SIZE = 2; // max emails per invocation (stay under 3/hour)

Deno.serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const appUrl = Deno.env.get("APP_URL") ?? "https://courtflowapp.pages.dev";
  const resendKey = Deno.env.get("RESEND_API_KEY");

  if (!resendKey) {
    return new Response(
      JSON.stringify({ error: "RESEND_API_KEY not set" }),
      { status: 500 }
    );
  }

  // Fetch pending emails (scheduled_at in the past, not yet sent)
  const { data: pending, error: fetchError } = await supabase
    .from("email_queue")
    .select("id, user_id, email, type, verification_token")
    .is("sent_at", null)
    .lte("scheduled_at", new Date().toISOString())
    .order("scheduled_at", { ascending: true })
    .limit(BATCH_SIZE);

  if (fetchError) {
    return new Response(JSON.stringify({ error: fetchError.message }), {
      status: 500,
    });
  }

  if (!pending || pending.length === 0) {
    return new Response(JSON.stringify({ sent: 0, message: "No pending emails" }));
  }

  let sent = 0;

  for (const item of pending) {
    const verifyUrl = `${appUrl}/verify?token=${item.verification_token}`;

    const emailBody = {
      from: "CourtFlow <noreply@courtflowapp.pages.dev>",
      to: [item.email],
      subject: "Verify your CourtFlow email address",
      html: `
        <div style="font-family:sans-serif;max-width:480px;margin:auto">
          <h2 style="color:#00C896">CourtFlow</h2>
          <p>Hi there,</p>
          <p>Please verify your email address to secure your account.</p>
          <p>
            <a href="${verifyUrl}"
               style="display:inline-block;padding:12px 24px;background:#00C896;
                      color:#000;text-decoration:none;border-radius:6px;font-weight:bold">
              Verify Email
            </a>
          </p>
          <p style="color:#888;font-size:13px">
            This link expires in 7 days. If you did not create a CourtFlow account, ignore this email.
          </p>
          <p style="color:#888;font-size:12px">
            Or copy this link: ${verifyUrl}
          </p>
        </div>
      `,
    };

    // Send via Resend
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(emailBody),
    });

    if (res.ok) {
      await supabase
        .from("email_queue")
        .update({ sent_at: new Date().toISOString() })
        .eq("id", item.id);
      sent++;
    } else {
      const errText = await res.text();
      await supabase
        .from("email_queue")
        .update({ error: errText })
        .eq("id", item.id);
    }
  }

  return new Response(JSON.stringify({ sent, total: pending.length }));
});
