export async function apiFetch(input: string, init?: RequestInit) {
  const response = await fetch(input, {
    ...init,
    credentials: "same-origin",
    cache: "no-store",
  });
  if (response.status === 401) {
    window.location.assign("/auth/login");
    throw new Error("Please log in again");
  }
  return response;
}
