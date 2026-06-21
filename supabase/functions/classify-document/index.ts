import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const documentTypes = [
  "lease",
  "deed",
  "insurance",
  "utility",
  "tax",
  "hoa",
  "permit",
  "other",
] as const;

const responseSchema = {
  document_type: "lease",
  confidence: 0.95,
  property_address: "",
  city: "",
  state: "",
  zip_code: "",
  unit_number: "",
  summary: "",
  extracted_metadata: {},
};

function buildPrompt(documentText: string): string {
  return `You are an expert real estate document classification and extraction system.

Classify the document and extract structured data from the text below.

Allowed document_type values: ${documentTypes.join(", ")}

Return ONLY valid JSON matching this schema:

${JSON.stringify(responseSchema, null, 2)}

Rules:
* document_type must be one of the allowed values
* confidence is 0.0 to 1.0
* property address fields: extract when present; use empty string if missing
* summary: one sentence describing the document
* extracted_metadata: type-specific fields as JSON object:
  - lease: lease_start_date, lease_end_date, monthly_rent, security_deposit, late_fee, tenant_names (array), landlord_name
  - deed: grantor, grantee, recording_date, parcel_number
  - insurance: carrier, policy_number, expiry_date, coverage_amount
  - utility: provider, account_number, amount_due, due_date, service_address
  - tax: tax_year, amount_due, due_date, parcel_number
  - hoa: association_name, amount_due, due_date
  - permit: permit_type, permit_number, expiry_date, issuing_authority
  - other: notes (any useful key-value pairs)
* If field is missing, omit it or use null
* Do NOT include explanations
* Output must be valid JSON only

DOCUMENT TEXT:
${documentText}`;
}

function stripJsonFences(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith("```")) {
    return trimmed
      .replace(/^```(?:json)?/i, "")
      .replace(/```$/i, "")
      .trim();
  }
  return trimmed;
}

function validateResponse(data: Record<string, unknown>) {
  const docType = data.document_type;
  if (
    typeof docType !== "string" ||
    !documentTypes.includes(docType as (typeof documentTypes)[number])
  ) {
    throw new Error(`Invalid document_type: ${docType}`);
  }
  if (typeof data.confidence !== "number") {
    throw new Error("Missing or invalid confidence");
  }
  for (const key of [
    "property_address",
    "city",
    "state",
    "zip_code",
    "unit_number",
    "summary",
  ]) {
    if (!(key in data)) {
      throw new Error(`Missing field: ${key}`);
    }
  }
  if (
    typeof data.extracted_metadata !== "object" ||
    data.extracted_metadata === null ||
    Array.isArray(data.extracted_metadata)
  ) {
    throw new Error("extracted_metadata must be an object");
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error("Supabase environment is not configured.");
    }
    if (!geminiApiKey) {
      throw new Error("GEMINI_API_KEY is not configured.");
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const documentText = body?.documentText;
    if (
      !documentText ||
      typeof documentText !== "string" ||
      documentText.trim().length === 0
    ) {
      return new Response(JSON.stringify({ error: "documentText is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: buildPrompt(documentText) }],
            },
          ],
        }),
      },
    );

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      return new Response(
        JSON.stringify({ error: "Gemini API request failed", details: errorText }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const geminiJson = await geminiResponse.json();
    const rawText =
      geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    if (!rawText) {
      return new Response(JSON.stringify({ error: "Empty Gemini response" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const parsed = JSON.parse(stripJsonFences(rawText));
    validateResponse(parsed);

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
