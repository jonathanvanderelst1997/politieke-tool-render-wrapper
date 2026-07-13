#!/usr/bin/env node

const port = Number(process.env.PORT || 10000);
const base = `http://127.0.0.1:${port}`;
const user = String(process.env.POLITIEK_ONLINE_AUTH_USER || "").trim();
const password = String(process.env.POLITIEK_ONLINE_AUTH_PASSWORD || "");

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function request(path, options = {}) {
  return fetch(`${base}${path}`, { redirect: "manual", ...options });
}

async function waitForGateway() {
  const deadline = Date.now() + 90_000;
  while (Date.now() < deadline) {
    try {
      const response = await request("/healthz", { headers: { Accept: "text/plain" } });
      const body = await response.text();
      if (response.status === 200 && body.trim() === "ok") return;
    } catch {
      // The server may still be starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error("gateway health check did not become ready");
}

function cookiesFromResponse(response) {
  const values =
    typeof response.headers.getSetCookie === "function"
      ? response.headers.getSetCookie()
      : [response.headers.get("set-cookie") || ""];
  return values
    .flatMap((value) => value.split(/,(?=\s*[^;,]+=)/))
    .map((value) => value.trim().split(";")[0])
    .filter(Boolean)
    .join("; ");
}

function cookieValue(cookieHeader, name) {
  const prefix = `${name}=`;
  const part = cookieHeader
    .split(";")
    .map((item) => item.trim())
    .find((item) => item.startsWith(prefix));
  return part ? decodeURIComponent(part.slice(prefix.length)) : "";
}

async function login(candidatePassword) {
  return request("/api/online-login", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Origin: base,
    },
    body: new URLSearchParams({ user, password: candidatePassword, returnTo: "/" }),
  });
}

async function main() {
  assert(user && password, "runtime authentication variables are missing");
  await waitForGateway();

  const unauthenticatedApi = await request("/api/local-sync/status", {
    headers: { Accept: "application/json" },
  });
  assert(unauthenticatedApi.status === 401, "unauthenticated API was not blocked");

  const invalidLogin = await login(`${password}-invalid`);
  assert(invalidLogin.status === 401, "invalid production login was not rejected");

  const validLogin = await login(password);
  assert(validLogin.status === 303, "valid production login did not redirect");
  const cookies = cookiesFromResponse(validLogin);
  const csrf = cookieValue(cookies, "politiek_csrf");
  assert(cookies.includes("politiek_gateway_session="), "session cookie was not issued");
  assert(Boolean(csrf), "CSRF cookie was not issued");

  const app = await request("/", {
    headers: { Cookie: cookies, Accept: "text/html" },
  });
  const appBody = await app.text();
  assert(app.status === 200 && appBody.includes('id="root"'), "authenticated application did not load");

  const withoutCsrf = await request("/api/link-enrich", {
    method: "POST",
    headers: {
      Cookie: cookies,
      Origin: base,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ links: [] }),
  });
  assert(withoutCsrf.status === 403, "mutation without CSRF was not rejected");

  const withCsrf = await request("/api/link-enrich", {
    method: "POST",
    headers: {
      Cookie: cookies,
      Origin: base,
      "Content-Type": "application/json",
      "X-Politiek-CSRF": csrf,
    },
    body: JSON.stringify({ links: [] }),
  });
  assert(withCsrf.status === 200, "mutation with valid CSRF was not accepted");

  const logout = await request("/api/online-logout", {
    method: "POST",
    headers: { Cookie: cookies, Origin: base },
  });
  assert(logout.status === 303, "logout did not redirect");

  const afterLogout = await request("/api/local-sync/status", {
    headers: { Cookie: cookies, Accept: "application/json" },
  });
  assert(afterLogout.status === 401, "old session remained valid after logout");

  console.log("RUNTIME_AUTH_SELF_TEST=pass");
}

try {
  await main();
} catch (error) {
  console.error(`RUNTIME_AUTH_SELF_TEST=fail:${error.message || error}`);
  process.exitCode = 1;
}
